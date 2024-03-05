//
//  CMReviewDetailView.swift
//  YeDi
//
//  Created by 박채영 on 2023/10/24.
//

import SwiftUI

/// 고객 리뷰 디테일 뷰
struct CMReviewDetailView: View {
    // MARK: - Properties
    @State private var displayedImageIndex: Int = 0
    
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    /// 스크린 width에 따른 이미즈 크기 지정 변수
    private let imageDimension: CGFloat = screenWidth
    
    /// 표시할 리뷰 인스턴스
    let review: Review
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - 리뷰 이미지
                if review.imageURLStrings.count == 1 {
                    AsnycCacheImage(url: review.imageURLStrings[0])
                        .scaledToFill()
                        .frame(width: imageDimension, height: imageDimension)
                        .clipped()
                        .offset(y: -20)
                } else {
                    TabView(selection: $displayedImageIndex) {
                        ForEach(0..<review.imageURLStrings.count, id: \.self) { index in
                            AsnycCacheImage(url: review.imageURLStrings[index])
                                .scaledToFill()
                                .frame(width: imageDimension, height: imageDimension)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: imageDimension)
                    .offset(y: -20)
                }
                
                // MARK: - 리뷰 주요 컨텐츠
                HStack {
                    Text(review.style)
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    RatingView(score: review.designerScore, maxScore: 5, filledColor: .yellow)
                }
                .padding([.bottom, .leading, .trailing])
                
                Text(review.content)
                    .padding([.bottom, .leading, .trailing])
                
                ForEach(review.keywordReviews) { keyword in
                    HStack {
                        Text(keyword.keyword)
                        Spacer()
                    }
                    .foregroundStyle(Color.primaryLabel)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.quaternarySystemFill)
                    }
                    .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                }
                
                HStack {
                    Spacer()
                    Text("\(dateFormatter.changeDateString(transition: "yy.MM.dd", from: review.date)) 작성")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                .padding([.top, .leading, .trailing])
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                DismissButton(color: nil, action: {})
            }
        }
    }
}

#Preview {
    CMReviewDetailView(
        review: Review(
            reviewer: "",
            date: "",
            keywordReviews: [],
            designerScore: 0,
            content: "",
            imageURLStrings: [],
            reservationId: "",
            style: "",
            designer: ""
        )
    )
}
