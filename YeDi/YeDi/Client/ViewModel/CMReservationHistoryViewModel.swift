//
//  CMReservationHistoryViewModel.swift
//  YeDi
//
//  Created by 박채영 on 2023/10/24.
//

import SwiftUI
import FirebaseFirestore

/// 예약 내역 뷰 모델
class CMReservationHistoryViewModel: ObservableObject {
    // MARK: - Properties
    /// 예약 목록 변수
    @Published var reservations: [Reservation] = []
    /// 디자이너 변수
    @Published var designer: Designer?
    /// 샵 변수
    @Published var shop: Shop?
    /// 리뷰 변수
    @Published var review: Review?
    
    /// reservations 컬렉션 참조 변수
    let rCollectionRef = Firestore.firestore().collection("reservations")
    /// designers 컬렉션 참조 변수
    let dCollectionRef = Firestore.firestore().collection("designers")
    /// reviews 컬렉션 참조 변수
    let rvCollectionRef = Firestore.firestore().collection("reviews")
    
    // MARK: - Method
    /// 예약 패치 메서드
    @MainActor
    func fetchReservation(userAuth: UserAuth) async {
        self.reservations = []
        
        do {
            if let clientId = userAuth.currentClientID {
                let docSnapshot = try await rCollectionRef.whereField("clientUID", isEqualTo: clientId).getDocuments()
                
                for doc in docSnapshot.documents {
                    if let reservation = try? doc.data(as: Reservation.self) {
                        self.reservations.append(reservation)
                    }
                }
                
                checkReservationStatus()
            }
        } catch {
            print("Error fetching reservation list: \(error)")
        }
    }
    
    /// 예약 내역 상태 확인 메서드
    /// - 예약 일시가 현재 시각보다 이전인 예약건의 isFinished 프로퍼티를 true로 바꾸기 위함
    func checkReservationStatus() {
        for index in 0..<reservations.count {
            let singleTonDF = FirebaseDateFormatManager.sharedDateFormmatter
            let reservationTime = singleTonDF.changeDateString(transition: "MM-dd HH:mm", from: reservations[index].reservationTime)
            let currentTime = singleTonDF.changeDateString(transition: "MM-dd HH:mm", from: singleTonDF.firebaseDate(from: Date()))
            
            if reservationTime < currentTime {
                reservations[index].isFinished = true
            }
        }
    }
    
    /// 디자이너 패치 메서드
    @MainActor
    func fetchDesigner(designerId: String) async {
        designer = nil
        shop = nil
        
        let docRef = dCollectionRef.document(designerId)
        do {
            let document = try await docRef.getDocument()
            if let _ = document.data() {
                
                designer = try document.data(as: Designer.self)
                
                let shopRef = docRef.collection("shop")
                let shopSnapshot = try await shopRef.getDocuments()
                let shopData = shopSnapshot.documents.compactMap { document in
                    return try? document.data(as: Shop.self)
                }
                
                shop = shopData.first
            }
        } catch {
            print("Error fetching designer info: \(error)")
        }
    }
    
    /// 리뷰 패치 메서드
    /// - 해당 예약에 작성된 리뷰가 있는지 판단하기 위한 메서드
    @MainActor
    func fetchReview(clientId: String, reservationId: String) async {
        self.review = nil
        
        do {
            let docSnapshot = try await rvCollectionRef
                .whereField("reviewer", isEqualTo: clientId)
                .whereField("reservationId", isEqualTo: reservationId)
                .getDocuments()
            
            for doc in docSnapshot.documents {
                if let review = try? doc.data(as: Review.self) {
                    self.review = review
                }
            }
        } catch {
            print("Error fetching reservation list: \(error)")
        }
    }
}
