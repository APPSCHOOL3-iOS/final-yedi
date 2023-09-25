//
//  DMGridView.swift
//  YeDi
//
//  Created by 박찬호 on 2023/09/26.
//

import SwiftUI

struct DMGridView: View {
    // 샘플 게시글 데이터
    let samplePosts = [
        Post(id: "1", designerID: "원장루디", location: "예디샵 홍대지점", title: "물결 펌", description: "This is post 1", photos: [Photo(id: "p1", imageURL: "https://i.pinimg.com/564x/1a/cb/ac/1acbacd1cbc2a1510c629305e71b9847.jpg")], comments: 5, timestamp: "1시간 전"),
        Post(id: "2", designerID: "원장루디", location: "예디샵 홍대지점", title: "댄디 컷", description: "This is post 2", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/9a/bc/3a/9abc3a447d42aaa0f4be2e85eeb16ddc.jpg")], comments: 3, timestamp: "2시간 전"),
        Post(id: "3", designerID: "원장루디", location: "예디샵 신촌지점", title: "레이어드 컷", description: "This is post 3", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/c2/01/37/c20137b32560228cd0c9643466cf968c.jpg")], comments: 2, timestamp: "3시간 전"),
        Post(id: "4", designerID: "원장루디", location: "예디샵 신촌지점", title: "스퀴즈 펌", description: "This is post 4", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/fe/c2/c9/fec2c9a3c317834baf6febf5f8a081c9.jpg")], comments: 4, timestamp: "4시간 전"),
        Post(id: "5", designerID: "원장루디", location: "예디샵 강남지점", title: "볼륨 매직", description: "This is post 5", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/77/30/e2/7730e2eeb462d300bc1b481b6920f5e6.jpg")], comments: 6, timestamp: "5시간 전"),
        Post(id: "6", designerID: "원장루디", location: "예디샵 강남지점", title: "보브 컷", description: "This is post 6", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/d0/51/46/d0514632125c3f4cf49cfa17570049ba.jpg")], comments: 1, timestamp: "6시간 전"),
        Post(id: "7", designerID: "원장루디", location: "예디샵 이대지점", title: "웨이브 펌", description: "This is post 7", photos: [Photo(id: "p2", imageURL: "https://i.pinimg.com/564x/07/99/7f/07997ffa51df81ea13dde1e995e448ed.jpg")], comments: 2, timestamp: "7시간 전")
    ]
    
    
    // 그리드 레이아웃
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // 이미지 크기
    let imageSize: CGFloat = 174
    
    // 메인 뷰
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(samplePosts, id: \.id) { post in
                        NavigationLink(destination: DMPostView(selectedPost: post)) {
                            PostThumbnail(post: post, imageSize: imageSize)
                        }
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("내 게시물")
        }
    }
}

// 게시물 썸네일 컴포넌트
struct PostThumbnail: View {
    let post: Post
    let imageSize: CGFloat
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // 이미지
            AsyncImage(url: post.photos.first?.imageURL ?? "")
                .scaledToFill()
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(12)
                .clipped()
            // 이미지 스타일링
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
            
            // 제목
            Text(post.title)
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    DMGridView()
}