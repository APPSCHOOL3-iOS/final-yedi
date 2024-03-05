//
//  CMNewReviewView.swift
//  YeDi
//
//  Created by 박채영 on 2023/09/27.
//

import SwiftUI
import PhotosUI

/// 고객 리뷰 작성 뷰
struct CMNewReviewView: View {
    // MARK: - Properties
    /// 현재 프레젠테이션 dismiss용 환경 변수
    @Environment(\.dismiss) var dismiss
    /// 유저 Auth 관리 뷰 모델
    @EnvironmentObject var userAuth: UserAuth
    /// 고객 리뷰 뷰 모델
    @EnvironmentObject var reviewViewModel: CMReviewViewModel
    
    @State private var reviewPhotoURLs: [String] = []
    @State private var reviewKeywords: [Keyword] = []
    @State private var reviewScore: Int = 0
    @State private var reviewContent: String = ""
    
    /// 유효성 검사 결과 Alert용 Bool 타입 변수
    @State private var isShowingValidationAlert: Bool = false
    /// 업로드 상태를 표시하는 Bool 타입 변수
    @State private var isUploading: Bool = false
    
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    
    /// 표시할 예약 인스턴스
    var reservation: Reservation
    
    /// 업로드 상태에 따른 버튼 텍스트
    var uploadButtonText: String {
        return isUploading ? "업로드 중..." : "리뷰 등록"
    }
    
    /// 리뷰 유효성 검사
    var isReadyToUpload: Bool {
        return !reviewPhotoURLs.isEmpty && !reviewKeywords.isEmpty && !reviewContent.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                CMReservationInfoView(reservation: reservation)
                
                Spacer(minLength: 10)
                
                CMReviewSelectPhotosView(selectedPhotoURLs: $reviewPhotoURLs)
                
                CMReviewSelectKeywordsView(selectedKeywords: $reviewKeywords)
                
                CMReviewGiveScoreView(reviewScore: $reviewScore)
                
                CMReviewWriteContentView(reviewContent: $reviewContent)
                
                Spacer()
            }
            uploadButton
        }
        .onDisappear {
            isUploading.toggle()
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                DismissButton(color: nil, action: {})
            }
        }
        .alert("모든 항목을 채워주세요", isPresented: $isShowingValidationAlert) {
            Button(role: .cancel) {
                isShowingValidationAlert.toggle()
            } label: {
                Text("확인")
            }
        }
    }
    
    /// 리뷰 업로드용 커스텀 버튼
    private var uploadButton: some View {
        Button(action: {
            if isReadyToUpload {
                isUploading.toggle()
                
                guard let reservationId = reservation.id else { return }
                
                var styles: [String] = []
                for hairStyle in reservation.hairStyle {
                    styles.append(hairStyle.name)
                }
                
                if let clientId = userAuth.currentClientID {
                    // MARK: - 새 리뷰 인스턴스 생성
                    let newReview = Review(
                        id: UUID().uuidString,
                        reviewer: clientId,
                        date: dateFormatter.firebaseDate(from: Date()),
                        keywordReviews: reviewKeywords,
                        designerScore: reviewScore,
                        content: reviewContent,
                        imageURLStrings: reviewPhotoURLs,
                        reservationId: reservationId,
                        style: styles.joined(separator: ", "),
                        designer: reservation.designerUID
                    )
                    
                    // MARK: - 리뷰 업로드 및 dismiss
                    Task {
                        await reviewViewModel.uploadReview(review: newReview)
                        dismiss()
                    }
                }
            } else {
                isShowingValidationAlert.toggle()
            }
        }, label: {
            Text(uploadButtonText)
        })
        .buttonModifier(.mainColor)
        .padding()
    }
}

#Preview {
    CMNewReviewView(reservation: Reservation(clientUID: "", designerUID: "", reservationTime: "", hairStyle: [], isFinished: true))
}
