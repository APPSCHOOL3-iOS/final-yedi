//
//  CMPostViewModel.swift
//  YeDi
//
//  Created by Jaehui Yu on 2023/09/27.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class CMPostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    var lastDocumentSnapshot: DocumentSnapshot?
    let pageSize: Int = 3
    let postCollection = Firestore.firestore().collection("posts")
    let followingCollection = Firestore.firestore().collection("following")
    
    func fetchPosts() async {
        var query = postCollection
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDocumentSnapshot = self.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
        
        do {
            let querySnapshot = try await query.getDocuments()
            
            if !querySnapshot.isEmpty {
                self.posts.append(contentsOf: querySnapshot.documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as: Post.self) // Post 모델로 디코딩
                })
                
                self.lastDocumentSnapshot = querySnapshot.documents.last
                print("Fetched page. Total count:", self.posts.count)
            }
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    func fetchPostsForFollowedDesigners(clientID: String) async {
        do {
            let designerIDs = try await getFollowedDesignerIDs(forClientID: clientID)
            
            if let designerIDs = designerIDs, !designerIDs.isEmpty {
                let query = postCollection.whereField("designerID", in: designerIDs)

                do {
                    let querySnapshot = try await query.getDocuments()
                    
                    self.posts = querySnapshot.documents.compactMap { queryDocumentSnapshot in
                        try? queryDocumentSnapshot.data(as: Post.self) // Post 모델로 디코딩
                    }
                } catch {
                    print("Error fetching posts: \(error)")
                }
            } else {
                print("No followed designers found.")
            }
            
        } catch {
            print("Error fetching followed designer posts: \(error)")
        }
    }
    
    func getFollowedDesignerIDs(forClientID clientID: String) async throws -> [String]? {
        let clientDocument = followingCollection.document(clientID)
        
        do {
            let documentSnapshot = try await clientDocument.getDocument()
            
            if documentSnapshot.exists {
                if let data = documentSnapshot.data(), let designerIDs = data["uids"] as? [String] {
                    return designerIDs
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } catch {
            print("Error getting following document: \(error)")
            throw error
        }
    }
}
