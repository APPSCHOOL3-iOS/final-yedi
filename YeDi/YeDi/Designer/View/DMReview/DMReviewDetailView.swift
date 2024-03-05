//
//  DMReviewDetailView.swift
//  YeDi
//
//  Created by 송성욱 on 10/6/23.
//

import SwiftUI
import FirebaseFirestore

struct DMReviewDetailView: View {
    
    var review: Review
    
    var body: some View {
        List {
            Group {
                Section("평점") {
                    averageScore
                }
                
                Section("고객명") {
                    Text("\(review.reviewer)")
                }
                
                Section("디자이너 스타일 평가") {
                    Text("\(review.style)")
                }
                
                Section("리뷰 내용") {
                    reviewContent
                }
                
                Section("첨부 사진") {
                    attachedImage
                }
            }.listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("상세리뷰")
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(color: nil) { }
            }
        }
    }
    
    var averageScore: some View {
        HStack {
            StarScoreView(score: review.designerScore)
            
            Spacer()
            
            Text("\(FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yyyy.MM.dd.", from: review.date)) 작성")
        }
    }
    
    var reviewContent: some View {
        VStack(alignment: .leading) {
            Text("\(review.content)")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], alignment: .leading) {
                ForEach(review.keywordReviews) { keywordReview in
                    Text("\(keywordReview.keyword)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(white: 0.9), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    var attachedImage: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(review.imageURLStrings, id: \.self) { urlString in
                    AsnycCacheImage(url: urlString)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        DMReviewDetailView(review:
                .init(reviewer: "dAWO8ofNhPU2UuHeWG7u9OYncnk1",
                      date: "2023-10-16T13:29:08+0900",
                      keywordReviews: [
                        .init(keyword: "💚 원하는 스타일로 잘해줘요", isSelected: false, category: KeywordCategory(rawValue: "스타일")!),
                        .init(keyword: "💚 원하는 스타일로 잘해줘요", isSelected: false, category: KeywordCategory(rawValue: "스타일")!),
                        .init(keyword: "💚 원하는 스타일로 잘해줘요", isSelected: false, category: KeywordCategory(rawValue: "스타일")!),
                        .init(keyword: "💚 원하는 스타일로 잘해줘요", isSelected: false, category: KeywordCategory(rawValue: "스타일")!)], designerScore: 4, content: "단발로 잘라봤는데 인생 머리 찾은 것 같아서 기분이 너무 좋아요! 단발로 잘라봤는데 인생 머리 찾은 것단발로 잘라봤는데 인생 머리 찾은 것단발로 잘라봤는데 인생 머리 찾은 것",
                      imageURLStrings: [
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd",
                        "https://firebasestorage.googleapis.com:443/v0/b/yedi-b7f5a.appspot.com/o/reviews%2FDFE0319B-4003-4C62-B865-93BAB5E52E2C?alt=media&token=557576fe-21f3-4f32-af97-8534504d3bdd"
                      ],
                      reservationId: "6A446EB3-B4D0-4D4A-A0B5-EC3E9417ABFD",
                      style: "펌, 염색",
                      designer: "082C1661-F4DC-42EC-A03E-89C278C5A573"))
    }
}
