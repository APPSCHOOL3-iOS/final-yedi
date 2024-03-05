//
//  CMHomeCellView.swift
//  YeDi
//
//  Created by Jaehui Yu on 2023/09/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct CMHomeCellView: View {
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var consultationViewModel: ConsultationViewModel
    @StateObject private var viewModel = CMHomeCellViewModel()
    private(set) var post: Post
    
    /// 상담하기 버튼 채팅방 시트 표출 변수
    @State private var showChattingRoom = false
    
    var body: some View {
        VStack {
            CMHomeCellHeaderView(viewModel: viewModel, post: post)
            CMHomeCellPostImageView(viewModel: viewModel, post: post)
            CMHomeCellPostButtonView(viewModel: viewModel, post: post)
            CMHomeCellPostDescriptionView(viewModel: viewModel, post: post)
        }
        .padding(.bottom)
        .overlay( // 이미지를 2번 연속 눌렀을 경우 이미지 위에 하트 이미지가 뜨도록 설정
            ZStack {
                if viewModel.showHeartImage {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundStyle(Color.subColor)
                        .padding()
                        .zIndex(1) // 메시지를 이미지 위에 배치
                }
            }
        )
        .onChange(of: consultationViewModel.showChattingRoom, perform: { value in
            showChattingRoom = consultationViewModel.showChattingRoom
        })
        .fullScreenCover(isPresented: $showChattingRoom) {
            ChatRoomSheetView(chatRoomId: consultationViewModel.chatRoomId)
                .task {
                    if let currentClientID = userAuth.currentClientID {
                        await viewModel.checkIfLiked(forClientID: currentClientID, post: post)
                    }
                }
        }
        .task {
            await viewModel.fetchDesignerInfo(post: post)
            await viewModel.checkIfLiked(forClientID: userAuth.currentClientID ?? "", post: post)
        }
    }
}

// MARK: - Post Header
private struct CMHomeCellHeaderView: View {
    @ObservedObject private var viewModel: CMHomeCellViewModel
    private(set) var post: Post
    
    fileprivate init(viewModel: CMHomeCellViewModel, post: Post) {
        self.viewModel = viewModel
        self.post = post
    }
    
    fileprivate var body: some View {
        
        if let designer = viewModel.designer {
            NavigationLink(destination: CMDesignerProfileView(designer: designer)) {
                HStack {
                    // 디자이너 프로필 이미지
                    
                    if let imageURLString = designer.imageURLString {
                        AsnycCacheImage(url: imageURLString)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 50, maxHeight: 50)
                            .clipShape(Circle())
                    } else {
                        Text(String(designer.name.first ?? " ").capitalized)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.quaternarySystemFill))
                                    .foregroundColor(Color.primaryLabel)

                    }
                    // 디자이너 아이디 & 디자이너 근무 지점
                    VStack(alignment: .leading) {
                        Text(designer.name)
                            .foregroundStyle(Color.primaryLabel)
                        Text(designer.shop?.shopName ?? "Shop 이름")
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                    .padding(.leading, 4)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Post Image
private struct CMHomeCellPostImageView: View {
    @EnvironmentObject var userAuth: UserAuth
    @ObservedObject private var viewModel: CMHomeCellViewModel
    private(set) var post: Post
    
    private let imageDimension: CGFloat = (UIScreen.main.bounds.width)
    
    fileprivate init(viewModel: CMHomeCellViewModel, post: Post) {
        self.viewModel = viewModel
        self.post = post
    }
    
    fileprivate var body: some View {
        // 업로드한 이미지의 수가 1장일 경우와 1장 이상일 경우 분리
        // 1장의 경우는 단순히 이미지를 불러오고
        // 1장 이상일 경우에는 TabView를 이용하여 사진을 넘길 수 있음
        if post.photos.count == 1 {
            NavigationLink(destination: CMFeedDetailView(post: post)) {
                AsnycCacheImage(url: post.photos[0].imageURL)
                    .scaledToFill()
                    .frame(width: imageDimension, height: imageDimension)
                    .clipped()
                    .onTapGesture(count: 2) { // 이미지를 2번 연속 눌렀을 때
                        viewModel.isLiked = true
                        viewModel.showHeartImage = true
                        viewModel.likePost(forClientID: userAuth.currentClientID ?? "", post: post)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            viewModel.showHeartImage = false
                        }
                    }
            }
        } else {
            TabView(selection: $viewModel.selectedImageIndex) {
                ForEach(0..<post.photos.count, id: \.self) { index in
                    NavigationLink(destination: CMFeedDetailView(post: post)) {
                        AsnycCacheImage(url: post.photos[index].imageURL)
                            .scaledToFill()
                            .frame(width: imageDimension, height: imageDimension)
                            .clipped()
                            .tag(index)
                            .overlay( // 현재 이미지가 총 이미지 중에서 몇 번째인지를 나타냄
                                ZStack {
                                    Text("\(viewModel.selectedImageIndex + 1)/\(post.photos.count)")
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 7)
                                        .background {
                                            Capsule(style: .continuous)
                                                .foregroundStyle(.black.opacity(0.5))
                                        }
                                        .padding()
                                }
                                    .frame(maxWidth: .infinity, alignment: .topTrailing), alignment: .topTrailing
                            )
                    }
                }
                .onTapGesture(count: 2) { // 이미지를 2번 연속 눌렀을 때
                    viewModel.isLiked = true
                    viewModel.showHeartImage = true
                    viewModel.likePost(forClientID: userAuth.currentClientID ?? "", post: post)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        viewModel.showHeartImage = false
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: imageDimension)
        }
    }
}

// MARK: - Post Button
private struct CMHomeCellPostButtonView: View {
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var consultationViewModel: ConsultationViewModel
    @ObservedObject private var viewModel: CMHomeCellViewModel
    private(set) var post: Post
    
    fileprivate init(viewModel: CMHomeCellViewModel, post: Post) {
        self.viewModel = viewModel
        self.post = post
    }
    
    var body: some View {
        
        HStack {
            // 게시글 찜 Button
            Button(action: {
                viewModel.isLiked.toggle()
                viewModel.likePost(forClientID: userAuth.currentClientID ?? "", post: post)
            }, label: {
                Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(viewModel.isLiked ? Color.subColor : Color.primaryLabel)
            })
            Spacer()
            // 상담하기 Button
            Button(action: {
                consultationViewModel.proccessConsulation(designerId: post.designerID, post: post)
            }, label: {
                Text("상담하기")
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
                    .background {
                        Capsule(style: .continuous)
                            .stroke(Color.primaryLabel.opacity(0.5), lineWidth: 1)
                    }
            })
            .foregroundColor(Color.primaryLabel)
        }
        .padding(.horizontal)
    }
}

// MARK: - Post Description
private struct CMHomeCellPostDescriptionView: View {
    @ObservedObject private var viewModel: CMHomeCellViewModel
    private(set) var post: Post
    
    fileprivate init(viewModel: CMHomeCellViewModel, post: Post) {
        self.viewModel = viewModel
        self.post = post
    }
    
    fileprivate var body: some View {
        
        HStack {
            if viewModel.shouldShowMoreText || post.description?.count ?? 0 <= 60 {
                Text("\(viewModel.designer?.name ?? "디자이너 이름") ").fontWeight(.semibold) + Text(post.description ?? "")
            } else {
                Text("\(viewModel.designer?.name ?? "디자이너 이름") ").fontWeight(.semibold) + Text(post.description?.prefix(60) ?? "") + Text("...더보기")
                
            }
            Spacer()
        }
        .foregroundStyle(Color.primaryLabel)
        .padding(.horizontal)
        .onTapGesture {
            viewModel.shouldShowMoreText.toggle()
        }
        
        HStack {
            Text("\(FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yyyy년 MM월 dd일", from: post.timestamp))")
                .font(.footnote)
                .foregroundStyle(.gray)
            Spacer()
        }
        .padding(.horizontal)
    }
}
