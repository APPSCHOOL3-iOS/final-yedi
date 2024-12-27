//
//  CMLikedPostViewModel.swift
//  YeDi
//
//  Created by Jaehui Yu on 10/6/23.
//

import SwiftUI
import FirebaseFirestore

class CMLikedPostViewModel: ObservableObject {
    @Published var likedPosts: [Post] = []
    let firestore = Firestore.firestore()
    
    func fetchLikedPosts(forClientID clientID: String) {
        let likedPostsCollection = firestore.collection("likedPosts")
        
        likedPostsCollection
            .whereField("clientID", isEqualTo: clientID)
            .getDocuments { [weak self] likedPostQuerySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching liked posts: \(error)")
                    return
                }
                
                let likedPostIDs = likedPostQuerySnapshot?.documents.compactMap { document in
                    document["postID"] as? String
                } ?? []
                
                guard !likedPostIDs.isEmpty else {
                    DispatchQueue.main.async {
                        self.likedPosts.removeAll()
                    }
                    return
                }
                
                self.fetchPosts(withIDs: likedPostIDs)
            }
    }
    
    private func fetchPosts(withIDs postIDs: [String]) {
        let postsCollection = firestore.collection("posts")
        
        postsCollection
            .whereField(FieldPath.documentID(), in: postIDs)
            .getDocuments { [weak self] postQuerySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                let fetchedPosts = postQuerySnapshot?.documents.compactMap { document in
                    try? document.data(as: Post.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self.likedPosts = fetchedPosts
                }
            }
    }
}

