//
//  CMReviewListView.swift
//  YeDi
//
//  Created by 박채영 on 2023/09/25.
//

import SwiftUI

/// 리뷰 리스트 뷰
struct CMReviewListView: View {
    // MARK: - Properties
    /// 유저 Auth 관리 뷰 모델
    @EnvironmentObject var userAuth: UserAuth
    /// 고객 리뷰 뷰 모델
    @EnvironmentObject var reviewViewModel: CMReviewViewModel
    
    // MARK: - Body
    var body: some View {
        VStack {
            if reviewViewModel.reviews.isEmpty {
                Text("작성된 리뷰가 없습니다.")
                    .padding()
            } else {
                ScrollView {
                    ForEach(reviewViewModel.reviews) { review in
                        CMReviewCellView(review: review)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await reviewViewModel.fetchReview(userAuth: userAuth)
            }
        }
    }
}

/// 리뷰 셀 뷰
struct CMReviewCellView: View {
    // MARK: - Properties
    /// 리뷰 디테일 Sheet용 Bool 타입 변수
    @State private var isShowingReviewDetailSheet: Bool = false
    
    /// 표시할 리뷰 인스턴스
    let review: Review
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    /// 스크린 width에 따른 이미즈 크기 지정 변수
    private let imageDimension = screenWidth / 3
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - 리뷰할 스타일 & 별점
                    HStack {
                        Text(review.style)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primaryLabel)
                        Spacer()
                        RatingView(score: review.designerScore, maxScore: 5, filledColor: .yellow)
                    }
                    .padding(.bottom, 5)
                    
                    // MARK: - 리뷰 내용
                    Text(review.content)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.primaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    // MARK: - 리뷰 작성 일자
                    Text("\(FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yyyy년 MM월 dd일", from: review.date))")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                .padding()
                
                // MARK: - 리뷰 이미지
                ZStack(alignment: .topTrailing) {
                    AsnycCacheImage(url: review.imageURLStrings[0])
                        .scaledToFill()
                        .frame(width: imageDimension, height: imageDimension)
                        .clipped()
                        .cornerRadius(5)
                    
                    // 이미지가 여러 장인 경우 아이콘 표시
                    if review.imageURLStrings.count > 1 {
                        Image(systemName: "square.on.square.fill")
                            .foregroundColor(.white)
                            .padding(5)
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.quaternarySystemFill)
                .onTapGesture {
                    isShowingReviewDetailSheet.toggle()
                }
        }
        .padding(5)
        .sheet(isPresented: $isShowingReviewDetailSheet, content: {
            CMReviewDetailView(review: review)
        })
    }
}

#Preview {
    CMReviewListView()
        .environmentObject(UserAuth())
        .environmentObject(CMReviewViewModel())
}
