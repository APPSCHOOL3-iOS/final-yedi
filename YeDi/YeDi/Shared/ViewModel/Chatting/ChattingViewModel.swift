//
//  ChattingViewModel.swift
//  YeDi
//
//  Created by 이승준 on 2023/09/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class ChattingViewModel: ObservableObject {
    @Published var chatRoomId: String = ""
    @Published var chattings: [CommonBubble] = []
    @Published var receivedBubbleId: [String] = []
    @Published var userProfile: [String: ChatListUserInfo] = [:]
    @Published var anyMoreChats: Bool = false ///더 불러올 채팅이 있는지 없는지 판단하는 프로퍼티
    
    let limitLength = 13 ///더 불러오기에 쓸 채팅버블 개수 제한 변수
    var storePath: String {
        return "chatRooms/\(chatRoomId)/bubbles"
    }
    var storageRef = Storage.storage().reference()
    let storeService = Firestore.firestore() ///클라이언트와 디자이너 정보를 불러오기 위함
    private var sotreListener: ListenerRegistration? ///채팅을 읽는 전용 리스너 => 제거하기 위함
    
    var isFirstListening: Bool = true ///현재 채팅을 불러오는 것이 처음 인지를 체크하기 위한 변수
    
    /// deinit 확인용 메서드
    deinit {
        //print("deinit ChattingViewModel()")
    }
    
    final func removeListener() { ///리스너 제거 함수
        sotreListener?.remove()
    }
    
    @MainActor
    func fetchFirstChattingBubbles() {
        self.sotreListener = storeService.collection(storePath) //채팅방의 위치
            .limit(toLast: limitLength)
            .order(by: "date")
            .addSnapshotListener { [weak self] querySnapshot, _ in
                guard let querySnapshot = querySnapshot else {
                    print("Error fetching documents: fetchFirstChattingBubbles()")
                    return
                }
                
                querySnapshot.documentChanges.forEach { diff in
                    guard let bubble = try? diff.document.data(as: CommonBubble.self) else {
                        print("Error decoding bubble data : fetchFirstChattingBubbles()")
                        return
                    }
                    
                    switch diff.type {
                    case .added:
                        if !(self?.chattings.contains { $0.id == bubble.id } ?? false) {
                            self?.chattings.append(bubble)
                        }
                    case .modified:
                        self?.chattings = self?.updateChatting(chattings: self?.chattings ?? [], diff: bubble) ?? []
                    default:
                        break
                    }
                }
                ///첫 Listener 호출
                if (self?.isFirstListening) != nil {
                    self!.isFirstListening = false
                }
            }
        self.anyMoreChat() /// 더 불러올 채팅이 없는지 검사
    }
    
    @MainActor
    func fetchMoreChattingBubble() {
        guard !self.chattings.isEmpty else { ///빈 채팅방에서 더 보기를 눌러도 에러 X
            self.anyMoreChats = false /// 빈 채팅방 이므로 더 보기를 비활성화
            print("No more messages to fetch : fetchMoreChattingBubble()")
            return
        }
        
        storeService.collection(storePath)   ///채팅방의 위치
            .whereField("date", isLessThan: self.chattings[0].date) ///최근 메시지보다 더 오래된 메시지를 불러온다.
            .limit(toLast: limitLength) ///limitLength값에 맞게 길이 제한
            .order(by: "date")          ///채팅의 순서 date 기준
            .getDocuments { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: fetchMoreChattingBubble()")
                    return
                }
                let moreBubbles = documents.compactMap { try? $0.data(as: CommonBubble.self) }
                self?.chattings = moreBubbles + (self?.chattings ?? [])
            }
        /// 더 불러올 채팅이 없는지 검사
        self.anyMoreChat()
    }
    
    /// 더 불러올 채팅 버블이 있는지 검사하는 코드
    func anyMoreChat() {
        guard !self.chattings.isEmpty else { ///빈 채팅방에서 더 보기를 눌러도 에러 X
            print("No more messages to fetch : fetchMoreChattingBubble()")
            return
        }
        
        storeService.collection(storePath)
            .whereField("date", isLessThan: self.chattings[0].date)
            .limit(toLast: 1)
            .order(by: "date") ///채팅의 순서 date 기준
            .getDocuments { [weak self] querySnapshot, _ in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: fetchMoreChattingBubble()")
                    return
                }
                if documents.first != nil {
                    self?.anyMoreChats = true
                } else {
                    self?.anyMoreChats = false
                }
            }
    }
    
    /// 모든 상대방 버블을 조회하여 "isRead" 필드의 값을 변경하는 함수
    func updateChattingBubbleReadState() {
        for documentId in receivedBubbleId {
            storeService.collection(storePath).document(documentId).updateData(["isRead": true])
        }
    }
    
    /// 채팅방에서 상대방 버블 아이디 가져오와서 배열(receivedBubbleId)로 저장하는 함수
    /// 마지막에 updateChattingBubbleReadState()를 실행한다.
    func getReceivedBubbleId(chatRoomId: String, sender: String) {
        storeService.collection(storePath).whereField("sender", isEqualTo: sender).getDocuments { [weak self] querySnapshot, error in
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let documents = querySnapshot?.documents else {
                return
            }
            
            let data = documents.map { queryDocumentSnapshot in
                queryDocumentSnapshot.documentID
            }
            
            self?.receivedBubbleId = data
            self?.updateChattingBubbleReadState()
        }
    }
    
    ///텍스트 버블을 보내는 메소드
    func sendTextBubble(content: String, sender: String) {
        let instance = FirebaseDateFormatManager.sharedDateFormmatter
        
        let bubble = CommonBubble( content: content, date: "\(instance.firebaseDate(from: Date()))", sender: sender, isRead: false)
        
        sendBubble(bubble: bubble, chatRoomId: chatRoomId)
    }
    
    ///게시물 버블을 보내는 메소드
    func sendBoardBubble(content: String, imagePath: String, sender: String) {
        let instance = FirebaseDateFormatManager.sharedDateFormmatter
        
        let bubble = CommonBubble(content: content, imagePath: imagePath,
                                  date: "\(instance.firebaseDate(from: Date()))",
                                  sender: sender, isRead: false
                                  
        )
        
        sendBubble(bubble: bubble, chatRoomId: chatRoomId)
    }
    
    ///이미지 버블을 보내는 메소드
    func sendImageBubble(imageData: Data, sender: String, chatRoomId id: String) {
        
        let bubble: CommonBubble = CommonBubble(imagePath: "", date: "", sender: "", isRead: false)
        let instance = FirebaseDateFormatManager.sharedDateFormmatter
        
        self.storageRef = storageRef.child("\(bubble.id).jpg")
        
        _ = storageRef.putData(imageData, metadata: nil) { [weak self] metadata, _ in
            guard metadata != nil else {
                print("이미지 업로드 중 에러 발생")
                return
            }
            
            ///You can also access to download URL after upload.
            self?.storageRef.downloadURL { [weak self] url, _ in
                
                guard url != nil else {
                    print("이미지 URL생성 중 에러 발생")
                    return
                }
                
                let imageURL = "\(String(describing: url!))"
                
                let updatedBubble = CommonBubble(imagePath: "\(imageURL)", 
                                                 date: "\(instance.firebaseDate(from: Date()))",
                                                 sender: sender, isRead: false)
                
                self?.sendBubble(bubble: updatedBubble, chatRoomId: id)
                
            }
        }
    }
    
    ///상담하기를 누르면 채팅방이 생성된 이후에 자동으로 고객에서 디자이너에게 "이 게시물을 보고 상담하러 왔습니다."
    ///매개변수 : 게시물 아이디 값
    func startingBoardBubble(postID: String, sender: String) {
        ///게시물들이 있는 파이어스토어 데이터베이스 이름
        let databasePosts = Firestore.firestore().collection("posts/\(postID)")
        
        ///게시물을 지정된 구조체형에 맞게 변환
        databasePosts.getDocuments { [weak self] snapshot, _ in
            let id = postID
            
            if let docData = snapshot?.documents as? [String: Any],
               let designerID = docData["designerID"] as? String,
               let location = docData["location"] as? String,
               let title = docData["title"] as? String,
               let description = docData["description"] as? String,
               let hairCategory = docData["hairCategory"] as? HairCategory,

               let price = docData["price"] as? Int,
               let photosDataArray = docData["photos"] as? [[String: Any]] {
                
                // photos 필드 처리
                var photos: [Photo] = []
                
                for photoData in photosDataArray {
                    if let photoID = photoData["id"] as? String,
                       let imageURLString = photoData["imageURL"] as? String {
                        
                        // Photo 객체 생성 및 배열에 추가
                        let photo = Photo(id: photoID, imageURL: imageURLString)
                        photos.append(photo)
                    }
                }
                
                let post = Post(id: id, designerID: designerID, location: location, 
                                title: title, description: description, photos: photos,
                                comments: 0, timestamp: "", hairCategory: hairCategory, price: price)
                ///새로 생성된 채팅방에 바로 게시물 버블 보내기
                self?.sendBoardBubble(content: "이 게시물 보고 상담하러 왔어요", imagePath: post.photos[0].imageURL, sender: sender)
            }
        }
    }
    
    ///self.chattings의 채팅 내용을 업데이트 해주는 코드
    ///사용처 : 읽음처리
    private func updateChatting(chattings: [CommonBubble], diff: CommonBubble) -> [CommonBubble] {
        var tempchat = chattings
        
        ///id로 찾아서 바꿔주기
        if let index = chattings.firstIndex(where: { $0.id == diff.id }) {
            tempchat[index] = diff
        }
        
        return tempchat
    }
    
    /// 채팅방마다 유저 닉네임, url사진을 userProfile variable에 저장하는 메소드
    final func fetchUserInfo(login type: UserType, chatRooms id: String) {
        let colRef: CollectionReference
        
        // MARK: 상대방 유저정보가 필요 하므로 로그인한 계정과 반대인 Collection 탐색
        if type == UserType.client {
            colRef = storeService.collection("designers")
        } else {
            colRef = storeService.collection("clients")
        }
        
        colRef.whereField("chatRooms", arrayContains: chatRoomId).getDocuments { [weak self] snapshot, error in
            if error != nil {
                print("Error getting userProfile: fetchUserInfo()")
                return
            }
            
            if let snapshot = snapshot, !snapshot.isEmpty {
                for document in snapshot.documents {
                    var userInfo: ChatListUserInfo
                    
                    if type == .client {
                        userInfo = ChatListUserInfo(uid: document.documentID,
                                                    name: document.data()["name"] as? String ?? "",
                                                        profileImageURLString: document.data()["imageURLString"] as? String ?? "")
                    } else {
                        userInfo = ChatListUserInfo(uid: document.documentID,
                                                    name: document.data()["name"] as? String ?? "",
                                                    profileImageURLString: document.data()["profileImageURLString"] as? String ?? "")
                    }
                    
                    self?.userProfile[id] = userInfo
                }
            }
        }
    }
    
    ///버블을 보내는 메소드
    private func sendBubble(bubble: CommonBubble, chatRoomId id: String) {
        let data: [String: Any] = [
            "id": bubble.id,
            "content": bubble.content ?? "",
            "imagePath": bubble.imagePath ?? "",
            "date": bubble.date,
            "messageType": bubble.messageType.rawValue,
            "sender": bubble.sender,
            "isRead": bubble.isRead
        ]
        
        storeService.collection("chatRooms/\(id)/bubbles").addDocument(data: data) { error in
            if error != nil {
                print("Error adding document: sendBubble()")
            } else {
                //print("Document added successfully.")
            }
        }
    }
    
    final func changetoDateFormat(_ bubbleDate: Date) -> String {
        let instance = FirebaseDateFormatManager.sharedDateFormmatter
        let date = instance.firebaseDate(from: bubbleDate)
        return date
    }
}
