//
//  CMFollowingListView.swift
//  YeDi
//
//  Created by 박채영 on 2023/09/25.
//

import SwiftUI

struct CMFollowingListView: View {
    // MARK: - Properties
    @StateObject var postDetailViewModel = PostDetailViewModel()
    
    @EnvironmentObject var profileViewModel: CMProfileViewModel
    
    @State private var isFollowingDesigner: Bool = true
    @State private var isFollowing: Bool = true
    
    // MARK: - Body
    var body: some View {
        VStack {
            if profileViewModel.followedDesigner.isEmpty {
                Text("팔로잉한 디자이너가 없습니다.")
                    .padding()
            } else {
                ScrollView {
                    ForEach(profileViewModel.followedDesigner, id: \.id) { designer in
                        followingList(designer: designer)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await profileViewModel.fetchFollowedDesigner()
            }
        }
    }
    
    private func followingList(designer: Designer) -> some View {
        HStack(alignment: .top) {
            if let imageURLString = designer.imageURLString {
                DMAsyncImage(url: imageURLString)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 50, maxHeight: 50)
                    .clipShape(Circle())
                    .offset(y: -5)
                    .padding(.trailing, 4)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 50, maxHeight: 50)
                    .clipShape(Circle())
                    .offset(y: -5)
                    .padding(.trailing, 4)
            }

            VStack(alignment: .leading) {
                Text("\(designer.name)")
                Text("서울")
                    .font(.subheadline)
            }
            
            Spacer()
            
            Button {
                Task {
                    await postDetailViewModel.toggleFollow(designerUid: designer.designerUID)
                }
                isFollowing.toggle()
            } label: {
                Text("팔로우")
                    .font(.system(size: 14))
                    .foregroundStyle(isFollowing ? .black : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 7)
                    .background(isFollowing ? .white : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isFollowing ? .black : .white, lineWidth: 1)
                    )
            }
        }
        .onAppear {
            Task {
                await postDetailViewModel.isFollowed(designerUid: designer.designerUID)
                isFollowing = postDetailViewModel.isFollowing
            }
        }
    }
}

#Preview {
    CMFollowingListView()
        .environmentObject(CMProfileViewModel())
}
