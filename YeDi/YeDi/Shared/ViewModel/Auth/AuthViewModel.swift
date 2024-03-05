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

class UserAuth: ObservableObject {
    @Published var userType: UserType?
    @Published var clientSession: FirebaseAuth.User?
    @Published var designerSession: FirebaseAuth.User?
    @Published var currentClientID: String?
    @Published var currentDesignerID: String?
    @Published var isClientLogin: Bool = false
    @Published var isDesignerLogin: Bool = false
    
    private let auth = Auth.auth()
    private let storeService = Firestore.firestore()
    private let userDefaults: UserDefaults = UserDefaults.standard
    
    private let collectionClients: CollectionReference = Firestore.firestore().collection("clients")
    private let collectionDesigners: CollectionReference = Firestore.firestore().collection("designers")
    
    init() {
        fetchUserTypeinUserDefaults()
        fetchUser()
    }
    
    func fetchUser() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.userType = self?.userType
                
                switch self?.userType {
                case .client:
                    self?.clientSession = user
                    self?.currentClientID = self?.clientSession?.uid
                    self?.isClientLogin = true
                case .designer:
                    self?.designerSession = user
                    self?.currentDesignerID = self?.designerSession?.uid
                    self?.isDesignerLogin = true
                case nil:
                    return
                }
            } else {
                self?.resetUserInfo()
            }
        }
    }
    
    func signIn(_ email: String, _ password: String, _ type: UserType, _ completion: @escaping (Bool) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("(AuthViewModel) DEBUG: signIn Error \(error.localizedDescription)")
                completion(false)
            }
            
            guard let user = result?.user else {
                completion(false)
                return
            }
            
            /// user type에 따라서 각 고객, 디자이너 정보 가져오기
            let collectionName = type.rawValue + "s"
            
            self?.storeService.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("(AuthViewModel) Firestore query error:", error.localizedDescription)
                    completion(false)
                }
                
                if let documents = snapshot?.documents,
                   let userData = documents.first?.data(),
                   let name = userData["name"] as? String,
                   let email = userData["email"] as? String {
                    
                    print("(AuthViewModel) signIn Name:", name)
                    print("(AuthViewModel) signIn Email:", email)
                    
                    switch type {
                    case .client:
                        self?.clientSession = user
                        self?.currentClientID = self?.clientSession?.uid
                        self?.isClientLogin = true
                    case .designer:
                        self?.designerSession = user
                        self?.currentDesignerID = self?.designerSession?.uid
                        self?.isDesignerLogin = true
                    }
                    
                    self?.userType = type
                    self?.saveUserTypeinUserDefaults(type.rawValue)
                    
                    completion(true)
                    
                } else {
                    print("(AuthViewModel) User data not found")
                    completion(false)
                }
            }
        }
    }
    
    func registerClient(client: Client, password: String, completion: @escaping (Bool) -> Void) {
        auth.createUser(withEmail: client.email, password: password) { [weak self] result, error in
            if let error = error {
                completion(false)
                print("(AuthViewModel) DEBUG: Error registering new user: \(error.localizedDescription)")
            } else {
                completion(true)
                
                guard let user = result?.user else { return }
                print("(AuthViewModel) DEBUG: Registered User successfully")
                
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
                
                self?.collectionClients
                    .document(user.uid)
                    .setData(data, merge: true)
                
                self?.resetUserInfo()
            }
        }
    }
    
    func registerDesigner(designer: Designer, shop: Shop, password: String, completion: @escaping (Bool) -> Void) {
        auth.createUser(withEmail: designer.email, password: password) { [weak self] result, error in
            if let error = error {
                completion(false)
                print("(AuthViewModel) DEBUG: Error registering new user: \(error.localizedDescription)")
            } else {
                completion(true)
                
                guard let user = result?.user else { return }
                print("(AuthViewModel) DEBUG: Registered User successfully")
                
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
                
                self?.collectionDesigners
                    .document(user.uid)
                    .setData(data, merge: true)
                
                guard let dataSet = self?.designerShopDataSet(shop: shop) else {
                    return
                }
                
                self?.collectionDesigners.document(user.uid).collection("shop")
                    .addDocument(data: dataSet) { _ in
                        self?.resetUserInfo()
                    }
            }
        }
    }
    
    func resetPassword(forEmail email: String, userType: UserType, completion: @escaping (Bool) -> Void) {
        let clientsQuery = collectionClients.whereField("email", isEqualTo: email)
        let designersQuery = collectionDesigners.whereField("email", isEqualTo: email)
        
        switch userType {
        case .client:
            checkExistEmail(query: clientsQuery, email: email) { exists in
                if exists {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .designer:
            checkExistEmail(query: designersQuery, email: email) { exists in
                if exists {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func checkExistEmail(query: Query, email: String, completion: @escaping (Bool) -> Void) {
        query.addSnapshotListener { [weak self] querySnapshot, error in
            if let error = error {
                print("(AuthViewModel) \(error.localizedDescription)")
                completion(false)
            }
            
            guard let querySnapshot = querySnapshot else {
                completion(false)
                return
            }
            
            if querySnapshot.documents.isEmpty {
                completion(false)
            } else {
                self?.sendPasswordReset(email: email) { success in
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("(AuthViewModel) \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func signOut() {
        resetUserInfo()
        try? auth.signOut()
    }
    
    // TODO: 1.함수명 변경 2.아이디와 연결된 모든 데이터를 삭제하는 로직 필요
    func deleteClientAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        if let currentClientID {
            collectionClients
                .document(currentClientID).delete()
        }
        
        if let currentDesignerID {
            collectionDesigners
                .document(currentDesignerID).delete()
        }
        
        user.delete { error in
            if let error = error {
                print("(AuthViewModel) DEBUG: Error deleting user account: \(error.localizedDescription)")
                return
            }
            
            print("(AuthViewModel) DEBUG: User account deleted")
            
            self.signOut()
        }
    }
    
    func resetUserInfo() {
        userType = nil
        
        clientSession = nil
        designerSession = nil
        
        currentClientID = nil
        currentDesignerID = nil
        
        isClientLogin = false
        isDesignerLogin = false
        
        removeUserTypeinUserDefaults()
    }
    
    func designerShopDataSet(shop: Shop) -> [String: Any] {
        let dateFomatter = FirebaseDateFormatManager.sharedDateFormmatter
     
        let changedDateFomatOpenHour = dateFomatter.changeDateString(transition: "HH", from: shop.openingHour)
        let changedDateFomatClosingHour = dateFomatter.changeDateString(transition: "HH", from: shop.closingHour)
        
        let shopData: [String: Any] = [
            "shopName": shop.shopName,
            "headAddress": shop.headAddress,
            "subAddress": shop.subAddress,
            "detailAddress": shop.detailAddress,
            "longitude": shop.longitude ?? 0.0,
            "latitude": shop.latitude ?? 0.0,
            "openingHour": changedDateFomatOpenHour,
            "closingHour": changedDateFomatClosingHour,
            "closedDays": shop.closedDays
        ]
        
        return shopData
    }
    
    // MARK: - UserDefaults related functions
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
}
