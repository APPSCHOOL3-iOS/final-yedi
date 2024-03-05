//
//  CMDesignerReviewDetailView.swift
//  YeDi
//
//  Created by Jaehui Yu on 10/22/23.
//

import SwiftUI

struct CMDesignerReviewDetailView: View {
    var review: Review
    private let imageDimension: CGFloat = (UIScreen.main.bounds.width) - 10
    @State private var selectedImageIndex: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Text(review.style)
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    VStack(alignment: .trailing) {
                        RatingView(score: review.designerScore, maxScore: 5, filledColor: .yellow)
                        Text("\(FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yy.MM.dd", from: review.date))")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                    
                }
                
                if review.imageURLStrings.count == 1 {
                    AsnycCacheImage(url: review.imageURLStrings[0])
                        .scaledToFill()
                        .frame(width: imageDimension, height: imageDimension)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<review.imageURLStrings.count, id: \.self) { index in
                            AsnycCacheImage(url: review.imageURLStrings[index])
                                .scaledToFill()
                                .frame(width: imageDimension, height: imageDimension)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .cornerRadius(8)
                    
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: imageDimension)
                }
                Text(review.content)
                    .padding(.bottom)
                
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
                }
                
            }
            .padding()
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
