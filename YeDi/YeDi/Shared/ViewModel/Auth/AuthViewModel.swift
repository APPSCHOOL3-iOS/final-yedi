//
//  AuthViewModel.swift
//  YeDi
//
//  Created by yunjikim on 2023/10/06.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum UserType: String {
    case client, designer
}

final class UserAuth: ObservableObject {
    @Published var currentClientID: String?
    @Published var currentDesignerID: String?
    @Published var userType: UserType?
    @Published var userSession: FirebaseAuth.User?
    @Published var isLogin: Bool = false
    
    private let auth = Auth.auth()
    private let storeService = Firestore.firestore()
    private let userDefaults: UserDefaults = UserDefaults.standard
    
    init() {
        fetchUserTypeinUserDefaults()
        fetchUser()
    }
    
    func fetchUser() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.userSession = user
                self?.userType = self?.userType
                self?.isLogin = true
                
                switch self?.userType {
                case .client:
                    self?.currentClientID = user.uid
                case .designer:
                    self?.currentDesignerID = user.uid
                case nil:
                    return
                }
            } else {
                self?.resetUserInfo()
            }
        }
    }
    
    func signIn(_ email: String, _ password: String, _ type: UserType, _ completion: @escaping (Bool) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: signIn Error \(error.localizedDescription)")
                completion(false)
            }
            
            guard let user = result?.user else {
                completion(false)
                return
            }
            
            /// user type에 따라서 각 고객, 디자이너 정보 가져오기
            let collectionName = type.rawValue + "s"
            
            self.storeService.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore query error:", error.localizedDescription)
                    completion(false)
                }
                
                guard let documents = snapshot?.documents,
                      let userData = documents.first?.data() else {
                    print("User data not found")
                    completion(false)
                    return
                }
                
                if let name = userData["name"] as? String,
                   let email = userData["email"] as? String{
                    print("Name:", name)
                    print("Email:", email)
                    
                    switch type {
                    case .client:
                        self.currentClientID = user.uid
                    case .designer:
                        self.currentDesignerID = user.uid
                    }
                    
                    self.userSession = user
                    self.userType = type
                    self.saveUserTypeinUserDefaults(type.rawValue)
                    self.isLogin = true
                    
                    completion(true)
                } else {
                    print("Invalid user data")
                    completion(false)
                }
            }
        }
    }
    
    func registerClient(client: Client, password: String, completion: @escaping (Bool) -> Void) {
        auth.createUser(withEmail: client.email, password: password) { result, error in
            if let error = error {
                completion(false)
                print("DEBUG: Error registering new user: \(error.localizedDescription)")
            } else {
                completion(true)
                
                guard let user = result?.user else { return }
                print("DEBUG: Registered User successfully")
                
                let data: [String: Any] = [
                    "id": user.uid,
                    "name": client.name,
                    "email": client.email,
                    "profileImageURLString": client.profileImageURLString,
                    "phoneNumber": client.phoneNumber,
                    "gender": client.gender,
                    "birthDate": client.birthDate,
                    "favoriteStyle": client.favoriteStyle,
                    "chatRooms": client.chatRooms
                ]
                
                self.storeService.collection("clients")
                    .document(user.uid)
                    .setData(data, merge: true)
                
                self.userSession = nil
                self.isLogin = false
            }
        }
    }
    
    func registerDesigner(designer: Designer, shop: Shop, password: String, completion: @escaping (Bool) -> Void) {
        auth.createUser(withEmail: designer.email, password: password) { result, error in
            if let error = error {
                completion(false)
                print("DEBUG: Error registering new user: \(error.localizedDescription)")
            } else {
                completion(true)
                
                guard let user = result?.user else { return }
                print("DEBUG: Registered User successfully")
                
                let data: [String: Any] = [
                    "id": user.uid,
                    "name": designer.name,
                    "email": designer.email,
                    "imageURLString": designer.imageURLString ?? "",
                    "phoneNumber": designer.phoneNumber,
                    "description": designer.description ?? "",
                    "designerScore": designer.designerScore,
                    "reviewCount": designer.reviewCount,
                    "followerCount": designer.followerCount,
                    "skill": designer.skill,
                    "chatRooms": designer.chatRooms,
                    "birthDate": designer.birthDate,
                    "gender": designer.gender,
                    "rank": designer.rank.rawValue,
                    "designerUID": user.uid,
                ]
                
                self.storeService.collection("designers")
                    .document(user.uid)
                    .setData(data, merge: true)
                
                self.storeService.collection("designers").document(user.uid).collection("shop")
                    .addDocument(data: self.designerShopDataSet(shop: shop), completion: { _ in
                        self.userSession = nil
                        self.isLogin = false
                    })
            }
        }
    }
    
    func resetPassword(forEmail email: String, completion: @escaping (Bool) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print(error.localizedDescription)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func updatePassword(_ email: String, _ currentPassword: String, _ newPassword: String, _ completion: @escaping (Bool) -> Void) {
        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        auth.currentUser?.reauthenticate(with: credential) { result, error in
            if let error = error {
                print("reauthenticate error: \(error.localizedDescription)")
                completion(false)
            } else {
                self.auth.currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        print("update error: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    func signOut() {
        resetUserInfo()
        try? auth.signOut()
    }
    
    func deleteClientAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        if let currentClientID {
            storeService
                .collection("clients")
                .document(currentClientID).delete()
        }
        
        if let currentDesignerID {
            storeService
                .collection("designers")
                .document(currentDesignerID).delete()
        }
        
        user.delete { error in
            if let error = error {
                print("DEBUG: Error deleting user account: \(error.localizedDescription)")
                return
            }
            
            print("DEBUG: User account deleted")
            
            self.signOut()
        }
    }
    
    func resetUserInfo() {
        userSession = nil
        userType = nil
        currentClientID = nil
        currentDesignerID = nil
        isLogin = false
        
        removeUserTypeinUserDefaults()
    }
    
    func fetchUserTypeinUserDefaults() {
        if let type = userDefaults.value(forKey: "UserType") {
            let typeToString = String(describing: type)
            self.userType = UserType(rawValue: typeToString)
        }
    }
    
    func saveUserTypeinUserDefaults(_ type: String) {
        userDefaults.set(type, forKey: "UserType")
    }
    
    func removeUserTypeinUserDefaults() {
        userDefaults.removeObject(forKey: "UserType")
    }
    
    func designerShopDataSet(shop: Shop) -> [String: Any] {
        let dateFomatter = SingleTonDateFormatter.sharedDateFommatter
     
        let changedDateFomatOpenHour = dateFomatter.changeDateString(transition: "HH", from: shop.openingHour)
        let changedDateFomatClosingHour = dateFomatter.changeDateString(transition: "HH", from: shop.closingHour)
        
        let shopData : [String: Any] = [ "shopName" : shop.shopName,
                                         "headAddress" : shop.headAddress,
                                         "subAddress" : shop.subAddress,
                                         "detailAddress" : shop.detailAddress,
                                         // "telNumber" : "",
                                         "longitude" : shop.longitude,
                                         "latitude" : shop.latitude,
                                         "openingHour" : changedDateFomatOpenHour,
                                         "closingHour" : changedDateFomatClosingHour,
                                         // "messangerLinkURL" : ["": ""],
                                         "closedDays" : shop.closedDays]
        
        return shopData
    }
}
