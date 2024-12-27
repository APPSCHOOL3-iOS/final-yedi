//
//  CMSearchViewModel.swift
//  YeDi
//
//  Created by Jaehui Yu on 10/6/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct RecentItem: Identifiable {
    let id = UUID()
    let isSearch: Bool
    let text: String
    let designer: Designer?
}

class CMSearchViewModel: ObservableObject {
    @Published var designers: [Designer] = []
    @Published var searchText: String = ""
    @Published var recentSearches: [String] = []
    @Published var recentDesigners: [Designer] = []
    @Published var recentItems: [RecentItem] = []
    @Published var isTextFieldActive: Bool = false
    
    private let db = Firestore.firestore()
    
    var filterDesigners: [Designer] {
        if searchText.isEmpty {
            return []
        } else {
            return designers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var filteredDesignerCount: Int {
        return filterDesigners.count
    }
    
    init() {
        loadData()
    }
    
    // 디자이너 정보 불러오기
    func loadData() {
        let db = Firestore.firestore()
        
        db.collection("designers").getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents")
                return
            }
            
            var designersWithShops: [Designer] = []
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                if var designer = try? document.data(as: Designer.self) {
                    let designerID = document.documentID
                    let shopCollection = db.collection("designers").document(designerID).collection("shop")
                    
                    dispatchGroup.enter()
                    
                    shopCollection.getDocuments { (shopSnapshot, shopError) in
                        if let shopError = shopError {
                            print("Shop data retrieval failed: \(shopError)")
                        } else {
                            if let shopData = shopSnapshot?.documents.compactMap({ try? $0.data(as: Shop.self) }) {
                                designer.shop = shopData.first
                            }
                        }
                        
                        designersWithShops.append(designer)
                        
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.designers = designersWithShops
            }
        }
    }
    
    //최근 검색어 저장
    func saveRecentSearch() {
        if !searchText.isEmpty {
            if !recentItems.contains(where: { $0.isSearch && $0.text == searchText }) {
                let newItem = RecentItem(isSearch: true, text: searchText, designer: nil)
                recentItems.insert(newItem, at: 0)
                
                if recentItems.count > 5 {
                    recentItems.removeLast()
                }
                
                UserDefaults.standard.set(recentItems.map { [$0.text: $0.isSearch] }, forKey: "RecentItems")
            }
        }
    }
    
    // 최근 검색어 삭제
    func removeRecentSearch(_ search: String) {
        if let index = recentItems.firstIndex(where: { $0.isSearch && $0.text == search }) {
            recentItems.remove(at: index)
            UserDefaults.standard.set(recentItems.map { [$0.text: $0.isSearch] }, forKey: "RecentItems")
        }
    }
    
    // 최근 방문 디자이너 저장
    func addRecentDesigner(_ designer: Designer) {
        if !recentItems.contains(where: { !$0.isSearch && $0.designer?.id == designer.id }) {
            let newItem = RecentItem(isSearch: false, text: designer.name, designer: designer)
            recentItems.insert(newItem, at: 0)
            
            if recentItems.count > 5 {
                recentItems.removeLast()
            }
            
            UserDefaults.standard.set(recentItems.map { [$0.text: $0.isSearch] }, forKey: "RecentItems")
        }
    }
    
    // 최근 방문 디자이너 삭제
    func removeRecentDesigner(_ designer: Designer) {
        if let index = recentItems.firstIndex(where: { !$0.isSearch && $0.designer?.id == designer.id }) {
            recentItems.remove(at: index)
            UserDefaults.standard.set(recentItems.map { [$0.text: $0.isSearch] }, forKey: "RecentItems")
        }
    }
    
    // 최근 검색 내역 불러오기
    func loadRecentItems() {
        if let loadedItems = UserDefaults.standard.array(forKey: "RecentItems") as? [[String: Bool]] {
            recentItems = loadedItems.compactMap { recentItemDict in
                if let (key, value) = recentItemDict.first {
                    if let designer = designers.first(where: { $0.name == key }), value == false {
                        return RecentItem(isSearch: value, text: key, designer: designer)
                    } else {
                        return RecentItem(isSearch: value, text: key, designer: nil)
                    }
                }
                return nil
            }
        }
    }

    
    // 최근 검색 내역 전체 삭제
    func removeAllRecentItems() {
        recentItems.removeAll()
        
        UserDefaults.standard.removeObject(forKey: "RecentItems")
    }
}
