//
//  CMDesignerProfileViewModel.swift
//  YeDi
//
//  Created by Jaehui Yu on 10/21/23.
//

import Foundation
import Firebase
import FirebaseFirestore

@MainActor
class CMDesignerProfileViewModel: ObservableObject {
    @Published var designerPosts: [Post] = []
    @Published var reviews: [Review] = []
    @Published var keywords: [String] = []
    @Published var keywordCount: [(String, Int)] = []
    @Published var isFollowing: Bool = false
    @Published var previousFollowerCount: Int = 0
    
    private let firestore = Firestore.firestore()
    private var currentUserUid: String? {
        return Auth.auth().currentUser?.uid
    }
    
    @MainActor
    func isFollowed(designerUid: String) async {
        guard let uid = currentUserUid else { return }
        
        do {
            let documentSnapshot = try await firestore.collection("following").document(uid).getDocument()
            guard let followingUids = documentSnapshot.data()?["uids"] as? [String] else { return }
            isFollowing = followingUids.contains(designerUid)
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
            let userDocument = firestore.collection("following").document(currentUserUid)
            let documentSnapshot = try await userDocument.getDocument()
            if documentSnapshot.exists {
                try await userDocument.updateData(["uids": FieldValue.arrayUnion([designerUid])])
            } else {
                try await userDocument.setData(["uids": [designerUid]])
            }
        } catch {
            print("Error following: \(error)")
        }
    }
    
    private func unfollowing(designerUid: String, currentUserUid: String) async {
        do {
            let userDocument = firestore.collection("following").document(currentUserUid)
            try await userDocument.updateData(["uids": FieldValue.arrayRemove([designerUid])])
        } catch {
            print("Error unfollowing: \(error)")
        }
    }
    
    func updateFollowerCountForDesigner(designerUID: String, followerCount: Int) async {
        guard !designerUID.isEmpty else {
            print("Invalid designer UID")
            return
        }
        
        let followingCollection = Firestore.firestore().collection("following")
        let designerDocument = Firestore.firestore().collection("designers").document(designerUID)
        
        do {
            let followingQuerySnapshot = try await followingCollection.whereField("uids", arrayContains: designerUID).getDocuments()
            let followerCount = followingQuerySnapshot.documents.count

            if followerCount != previousFollowerCount {
                try await designerDocument.updateData(["followerCount": followerCount])
                previousFollowerCount = followerCount
                print("Follower count updated to \(followerCount)")
            } else {
                print("No change in follower count")
            }
            
        } catch let error {
            print("Error updating follower count: \(error.localizedDescription)")
        }
    }
    
    func formattedFollowerCount(followerCount: Int) -> String {
        if followerCount < 10_000 {
            return "\(followerCount)"
        } else if followerCount < 1_000_000 {
            let followers = Double(followerCount) / 10_000.0
            if followers.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(followers))만"
            } else {
                return "\(followers)만"
            }
        } else {
            let millions = followerCount / 10_000
            return "\(millions)만"
        }
    }
    
    func fetchDesignerPosts(designerUID: String) {
        firestore.collection("posts")
            .whereField("designerID", isEqualTo: designerUID)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching designer posts: \(error.localizedDescription)")
                    return
                }
                
                self.designerPosts = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Post.self)
                } ?? []
            }
    }
    
    func fetchReview(designerUID: String) {
        firestore.collection("reviews")
            .whereField("designer", isEqualTo: designerUID)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                
                self.reviews = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Review.self)
                } ?? []
            }
    }
    
    func fetchKeywords(designerUID: String) {
        firestore.collection("reviews")
            .whereField("designer", isEqualTo: designerUID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                
                let keywordCountDict = querySnapshot?.documents.reduce(into: [String: Int]()) { result, document in
                    if let keywordReviews = document.data()["keywordReviews"] as? [[String: Any]] {
                        for keywordReview in keywordReviews {
                            if let keyword = keywordReview["keyword"] as? String {
                                result[keyword, default: 0] += 1
                            }
                        }
                    }
                } ?? [:]
                
                let sortedKeywords = keywordCountDict.sorted { $0.key < $1.key }
                
                DispatchQueue.main.async {
                    self.keywords = sortedKeywords.map { $0.key }
                    self.keywordCount = sortedKeywords
                }
            }
    }
}
