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
    
    private let auth = Auth.auth()
    private let storeService = Firestore.firestore()
    private let userDefaults: UserDefaults = UserDefaults.standard
    
    init() {
        fetchUserTypeinUserDefaults()
        //fetchUser()
    }
    
    func fetchUser() {
        auth.addStateDidChangeListener { auth, user in
            if let user = user {
                self.userSession = user
                self.userType = self.userType
                switch self.userType {
                case .client:
                    self.currentClientID = user.uid
                case .designer:
                    self.currentDesignerID = user.uid
                case nil:
                    return
                }
            } else {
                self.userSession = nil
            }
        }
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
    
    func signIn(_ email: String, _ password: String, _ type: UserType, _ completion: @escaping (Bool) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: signIn Error \(error.localizedDescription)")
                completion(false) // 로그인 실패 시 false 반환
                return
            }
            
            guard let user = result?.user else {
                completion(false)
                return
            }
            self.userSession = user
            self.userType = type
            self.saveUserTypeinUserDefaults(type.rawValue)
            
            /// user type에 따라서 각 고객, 디자이너 정보 가져오기
            let collectionName = type.rawValue + "s"
            
            self.storeService.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore query error:", error.localizedDescription)
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents,
                      let userData = documents.first?.data() else {
                    print("User data not found")
                    completion(false)
                    return
                }
                
                switch self.userType {
                case .client:
                    if let name = userData["name"] as? String,
                       let email = userData["email"] as? String{
                        print("Name:", name)
                        print("Email:", email)
                        
                        self.currentClientID = user.uid
                        completion(true)
                    } else {
                        print("Invalid user data")
                        completion(false)
                    }
                case .designer:
                    if let userData = documents.first?.data() {
                        // 디자이너 정보 업데이트
                        if let name = userData["name"] as? String,
                           let email = userData["email"] as? String{
                            print("Name:", name)
                            print("Email:", email)
                            
                            self.currentDesignerID = user.uid
                            completion(true)
                        } else {
                            print("Invalid user data")
                            completion(false)
                        }
                    } else {
                        print("User data not found")
                        completion(false)
                    }
                    
                case .none:
                    return
                }
            }
        }
    }
    
    func registerClient(client: Client, password: String) {
        auth.createUser(withEmail: client.email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Error registering new user: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else { return }
            self.userSession = user

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
        }
    }
    
    func registerDesigner(designer: Designer, password: String) {
        auth.createUser(withEmail: designer.email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Error registering new user: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else { return }
            self.userSession = user

            print("DEBUG: Registered User successfully")

            let data: [String: Any] = [
                "id": user.uid,
                "name": designer.name,
                "email": designer.email,
                "phoneNumber": designer.phoneNumber,
                "description": designer.description ?? "",
                "imageURLString": designer.imageURLString ?? "",
                "designerScore": designer.designerScore,
                "reviewCount": designer.reviewCount,
                "followerCount": designer.followerCount,
                "skill": designer.skill,
                "chatRooms": designer.chatRooms
            ]

            self.storeService.collection("designers")
                .document(user.uid)
                .setData(data, merge: true)
        }
    }
    
    func checkEmailAvailability(_ email: String, _ userType: UserType, completion: @escaping (Bool) -> Void) {
        let collectionName = userType.rawValue + "s"
        
        self.storeService.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Firestore query error:", error.localizedDescription)
                completion(false)
                return
            }
            
            if (snapshot?.documents.count) != 0 {
                completion(true)
            } else {
                completion(false)
            }
        }
        
    }
    
    func signOut() {
        userSession = nil
        try? auth.signOut()
    }
}