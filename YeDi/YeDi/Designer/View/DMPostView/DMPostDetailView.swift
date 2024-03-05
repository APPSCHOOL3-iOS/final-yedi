//
//  DMPostDetailView.swift
//  YeDi
//
//  Created by yunjikim on 2023/10/22.
//

import SwiftUI
import FirebaseFirestore

struct DMPostDetailView: View {
    // MARK: - Properties
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var postViewModel: DMPostViewModel
    @StateObject var designerProfileViewModel: DMProfileViewModel = DMProfileViewModel()
    
    let instance = FirebaseDateFormatManager.sharedDateFormmatter
    
    @State var selectedPost: Post
    let safeArea: EdgeInsets
    let size: CGSize
    
    var postDate: String {
        instance.changeDateString(transition: "yyyy년 MM월 dd일", from: selectedPost.timestamp)
    }
    
    /// 포스트 사진 인덱스
    @State private var selectedTab = 0
    /// 수정 및 삭제를 위한 액션 Sheet용 Bool타입 변수
    @State private var isShowingActionSheet: Bool = false
    /// 삭제 확인을 위한 Alert용 Bool타입 변수
    @State private var isShowingDeleteAlert: Bool = false
    /// 수정 뷰로 이동하기 위한 Bool타입 변수
    @State private var navigateToEditView: Bool = false
    /// 새로고침 여부를 나타내기 위한 Bool타입 변수
    @State private var shouldRefresh: Bool = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    imageTabView
                    hairInfoView
                    descriptionInfoView
                    feedInfoView
                }
            }
        }
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            refreshPost(post: selectedPost)
        }
        .refreshable {
            refreshPost(post: selectedPost)
        }
    }
    
    private var toolbarView: some View {
        HStack {
            DismissButton(color: nil) {}
            
            Spacer()
            
            // MARK: - 수정, 삭제 액션 버튼
            HStack {
                NavigationLink(isActive: $navigateToEditView) {
                    DMEditPostView(post: $selectedPost, shouldRefresh: $shouldRefresh)
                } label: {
                    Button(action: {
                        isShowingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .imageScale(.large)
                            .foregroundColor(Color.primary)
                    }
                }
            }
            // MARK: - 수정 및 삭제를 위한 액션 Sheet
            .actionSheet(isPresented: $isShowingActionSheet) {
                ActionSheet(title: Text("선택"), buttons: [
                    .default(Text("수정"), action: {
                        navigateToEditView = true
                    }),
                    .destructive(Text("삭제"), action: {
                        isShowingDeleteAlert = true
                    }),
                    .cancel()
                ])
            }
        }
        // MARK: - 삭제 확인 Alert
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("삭제 확인"),
                message: Text("이 게시물을 정말로 삭제하시겠습니까?"),
                primaryButton: .default(Text("취소")),
                secondaryButton: .destructive(Text("삭제"), action: {
                    postViewModel.deletePost(selectedPost: selectedPost)
                    
                    DispatchQueue.main.async {
                        presentationMode.wrappedValue.dismiss()
                    }
                })
            )
        }
        .padding([.horizontal, .bottom])
        .padding(.top, safeArea.top)
    }
    
    @ViewBuilder
    private var imageTabView: some View {
        let height = size.height * 0.4
        
        TabView(selection: $selectedTab) {
            ForEach(Array(selectedPost.photos.enumerated()), id: \.element.id) { index, photo in
                AsnycCacheImage(url: photo.imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height * 0.6)
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: selectedPost.photos.count > 1 ? .automatic : .never))
        .background(.black)
        .frame(height: height * 1.4)
    }
    
    private var feedInfoView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("좋아요 \(selectedPost.comments)개")
                    .padding(.bottom, 8)
                
                Spacer()
                
                Text(postDate)
            }
            .font(.caption)
            .foregroundStyle(.gray)
        }
        .padding([.horizontal, .top])
    }
    
    private var descriptionInfoView: some View {
        VStack(alignment: .leading) {
            Text(selectedPost.title)
                .font(.headline)
                .padding(.bottom, 2)
            
            Text("\(selectedPost.description ?? "")")
        }
        .padding(.horizontal)
    }
    
    private var hairInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("카테고리")
                    .foregroundColor(Color.secondaryLabel)
                Spacer()
                Text(selectedPost.hairCategory.rawValue)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("가격")
                    .foregroundColor(Color.secondaryLabel)
                Spacer()
                Text("\(selectedPost.price)")
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondarySystemBackground)
        }
        .padding(.vertical)
        .padding(.horizontal, 12)
    }
    
    // MARK: - 새로고침 함수
    func refreshPost(post: Post) {
        // 게시글 ID 확인
        guard let postId = selectedPost.id else { return }

        // Firestore에서 게시글 정보 업데이트
        Firestore.firestore().collection("posts")
            .document(postId)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching document: \(error)")
                } else if let document = try? snapshot?.data(as: Post.self) {
                    selectedPost = document
                } else {
                    print("Error decoding post.")
                }
            }
    }
}
