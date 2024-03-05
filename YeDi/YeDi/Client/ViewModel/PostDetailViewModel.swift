//
//  PostDetailViewModel.swift
//  YeDi
//
//  Created by SONYOONHO on 2023/09/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

final class PostDetailViewModel: ObservableObject {
    @Published var selectedImages: [String] = []
    @Published var selectedImageID: String = ""
    @Published var isFollowing: Bool = false
    @Published var isLiked: Bool = false
    @Published var designer: Designer?
    
    private let db = Firestore.firestore()
    private var currentUserUid: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Client의 팔로잉 목록에 특정한 Designer가 포함되어 있는지 여부를 Bool값으로 `isFollowing`에 반영
    /// - Parameter designerUid: Client 팔로잉 목록에서 찾을 DesignerUid
    @MainActor
    func isFollowed(designerUid: String) async {
        guard let uid = currentUserUid else { return }
        
        do {
            let document = try await db.collection("following").document(uid).getDocument()
            guard let followingUids = document.data()?["uids"] as? [String] else { return }
            
            self.isFollowing = followingUids.contains(designerUid)
        } catch {
            print("Error getting document: \(error)")
        }
    }
    
    @MainActor
    func toggleFollow(designerUid: String) async {
        guard let uid = currentUserUid else { return }
        
        if isFollowing {
            isFollowing = false
            await unfollowing(designerUid: designerUid, currentUserUid: uid)
        } else {
            isFollowing = true
            await following(designerUid: designerUid, currentUserUid: uid)
        }
    }
    
    private func following(designerUid: String, currentUserUid: String) async {
        do {
            let documentSnapshot = try await db.collection("following").document(currentUserUid).getDocument()
            if documentSnapshot.exists {
                try await db.collection("following").document(currentUserUid).updateData([
                    "uids": FieldValue.arrayUnion([designerUid])
                ])
            } else {
                try await db.collection("following").document(currentUserUid).setData([
                    "uids": [designerUid]
                ])
            }
        } catch {
            print("Error following: \(error)")
        }
    }
    
    private func unfollowing(designerUid: String, currentUserUid: String) async {
        do {
            try await db.collection("following").document(currentUserUid).updateData([
                "uids": FieldValue.arrayRemove([designerUid])
            ])
        } catch {
            print("Error unfollowing: \(error)")
        }
    }
    
    @MainActor
    func toggleLike(post: Post) async {
        guard let uid = currentUserUid else { return }
        
        if isLiked {
            isLiked = false
            await unLikePost(post: post, clientID: uid)
        } else {
            isLiked = true
            await likePost(post: post, clientID: uid)
        }
    }
    
    private func unLikePost(post: Post, clientID: String) async {
        guard let postID = post.id else { return }
        do {
            let querySnapshot = try await db.collection("likedPosts").whereField("clientID", isEqualTo: clientID).whereField("postID", isEqualTo: postID).getDocuments()
            for document in querySnapshot.documents {
                try await db.collection("likedPosts").document(document.documentID).delete()
            }
        } catch {
            
        }
    }
    
    private func likePost(post: Post, clientID: String) async {
        guard let postId = post.id else { return }
        do {
            let like = Like(clientID: clientID, postID: postId, isLiked: true, timestamp: FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: Date()))
            try db.collection("likedPosts").addDocument(from: like)
        } catch {
            print("likePost Error: \(error)")
        }
    }
    
    @MainActor
    func isLikedPost(post: Post) async {
        guard let uid = currentUserUid else { return }
        guard let postId = post.id else { return }
        do {
            let document = try await db.collection("likedPosts").whereField("clientID", isEqualTo: uid).whereField("postID", isEqualTo: postId).getDocuments()
            
            if document.isEmpty {
                self.isLiked = false
            } else {
                self.isLiked = true
            }
        } catch {
            print("isLikedPost error: \(error)")
        }
    }
    
    @MainActor
    func getDesignerProfile(designerUid: String) async {
        do {
            let document = try await db.collection("designers").document(designerUid).getDocument()
            self.designer = try document.data(as: Designer.self)
            
            let querySnapshot = try await db.collection("designers").document(designerUid).collection("shop").getDocuments()
            let shop = querySnapshot.documents.compactMap { document in
                return try? document.data(as: Shop.self)
            }
            self.designer?.shop = shop.first
        } catch {
            print("getDesignerProfile Error: \(error)")
        }
    }
}

struct Like: Identifiable, Codable {
    @DocumentID var id: String?
    let clientID: String
    let postID: String
    let isLiked: Bool
    let timestamp: String
}
