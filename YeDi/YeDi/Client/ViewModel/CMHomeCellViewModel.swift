//
//  CMHomeCellViewModel.swift
//  YeDi
//
//  Created by Jaehui Yu on 10/6/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

@MainActor
class CMHomeCellViewModel: ObservableObject {
    @Published var designer: Designer?
    @Published var isLiked: Bool = false
    @Published var showHeartImage: Bool = false
    @Published var selectedImageIndex: Int = 0
    @Published var shouldShowMoreText: Bool = false
    let firestore = Firestore.firestore()
    
    func fetchDesignerInfo(post: Post) async {
        let designerDocument = firestore.collection("designers").document(post.designerID)
        
        do {
            let designerDocumentSnapshot = try await designerDocument.getDocument()
            designer = try? designerDocumentSnapshot.data(as: Designer.self)
            
            let shopCollection = designerDocument.collection("shop")
            let shopQuerySnapshot = try await shopCollection.getDocuments()
            let shopData = shopQuerySnapshot.documents.compactMap { document in
                return try? document.data(as: Shop.self)
            }
            designer?.shop = shopData.first
        } catch {
            print("Error fetching designer document: \(error)")
        }
    }
    
    func checkIfLiked(forClientID clientID: String, post: Post) async {
        do {
            let likedPostQuerySnapshot = try await firestore.collection("likedPosts")
                .whereField("clientID", isEqualTo: clientID)
                .whereField("postID", isEqualTo: post.id ?? "")
                .getDocuments()
            
            if !likedPostQuerySnapshot.isEmpty {
                // Firestore에서 해당 게시물을 찜되어 있는 경우
                self.isLiked = true
            } else {
                // Firestore에서 해당 게시물을 찜되어 있지 않은 경우
                self.isLiked = false
            }
        } catch {
            print("Error checking liked post: \(error)")
        }
    }
    
    func likePost(forClientID clientID: String, post: Post) {
        let likedPostCollection = firestore.collection("likedPosts")
        
        likedPostCollection
            .whereField("clientID", isEqualTo: clientID)
            .whereField("postID", isEqualTo: post.id ?? "")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking liked post: \(error)")
                    return
                }
                
                if let document = snapshot?.documents.first {
                    // 이미 찜한 게시물이므로 Firestore에서 삭제
                    document.reference.delete { error in
                        if let error = error {
                            print("Error unliking post: \(error)")
                        } else {
                            print("Post unliked successfully.")
                            self.isLiked = false
                        }
                    }
                } else {
                    // 아직 찜하지 않은 게시물인 경우 Firestore에 추가
                    let likedPostData: [String: Any] = [
                        "clientID": clientID,
                        "postID": post.id ?? "",
                        "isLiked": true,
                        "timestamp": FieldValue.serverTimestamp()
                    ]
                    
                    likedPostCollection.addDocument(data: likedPostData) { error in
                        if let error = error {
                            print("Error liking post: \(error)")
                        } else {
                            print("Post liked successfully.")
                            self.isLiked = true
                        }
                    }
                }
            }
    }
}
