//
//  ChattingListRoomView.swift
//  YeDi
//
//  Created by 김성준 on 2023/09/26.
//

import SwiftUI
import Firebase

struct ChattingListRoomView: View {
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var chattingListRoomViewModel: ChattingListRoomViewModel

    var body: some View {
        VStack {
            if chattingListRoomViewModel.isEmptyChattingList {
                Text("채팅 내역이 없습니다.")
                    .foregroundStyle(.gray)
            } else {
                List {
                    ForEach(chattingListRoomViewModel.chattingRooms, id: \.id) { chattingRoom in
                        HStack(alignment: .center) {
                            NavigationLink(destination: ChatRoomView(chatRoomId: chattingRoom.id), label: {
                                Text("")
                            })
                            .opacity(0)
                            .frame(width: 0, height: 0)
                            .background()
                            
                            if let imageURLString = chattingListRoomViewModel.userProfile[chattingRoom.id]?.profileImageURLString {
                                if imageURLString.isEmpty {
                                    Text(String(chattingListRoomViewModel.userProfile[chattingRoom.id]?.name.first ?? " ").capitalized)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .frame(width: 50, height: 50)
                                        .background(Circle().fill(Color.quaternarySystemFill))
                                        .foregroundColor(Color.primaryLabel)
                                } else {
                                    AsnycCacheImage(url: imageURLString)
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                }
                            }
                                
                            VStack(alignment: .leading, spacing: 5) {
                                Text(chattingListRoomViewModel.userProfile[chattingRoom.id]?.name ?? "UnKown")
                                    .font(.system(size: 17, weight: .semibold))
                                HStack {
                                    VStack(alignment: .leading) {
                                        if let recentMessage =  chattingRoom.chattingBubles?.first {
                                            if recentMessage.messageType == MessageType.imageBubble {
                                                Text("사진")
                                                    .foregroundStyle(.gray)
                                                    .lineLimit(1)
                                            } else {
                                                Text(recentMessage.content ?? "메세지가 비어있습니다.")
                                                    .foregroundStyle(.gray)
                                                    .lineLimit(1)
                                            }
                                            
                                            Text(changetoDateFormat(recentMessage.date))
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                            
                                        } else {
                                            Text("메세지가 존재하지 않습니다")
                                                .foregroundStyle(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if chattingListRoomViewModel.unReadCount[chattingRoom.id] ?? 0 != 0 {
                                        UnReadCountCircle(unreadCount: chattingListRoomViewModel.unReadCount[chattingRoom.id] ?? 0)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
                .animation(.easeInOut, value: chattingListRoomViewModel.chattingRooms)
                .listStyle(.plain)
                .navigationTitle("")
            }
        }
        .onAppear {
            chattingListRoomViewModel.fetchChattingList(login: userAuth.userType)
        }
        .onDisappear {
            chattingListRoomViewModel.removeListener()
        }
    }
    
    /// 채팅방 리스트 최근 메세지 날짜 표출형식 커스텀 메소드
    private func changetoDateFormat(_ messageDate: String) -> String {
        let dateFomatter = FirebaseDateFormatManager.sharedDateFormmatter.firebaseDateFormat()
        let date = dateFomatter.date(from: messageDate) ?? Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            dateFomatter.dateFormat = "HH:mm"
            return dateFomatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let currentYear = calendar.component(.year, from: Date())
            let messageYear = calendar.component(.year, from: date)
            // 올해 년도의 메세지인 경우 월/일 반환
            if currentYear == messageYear {
                dateFomatter.dateFormat = "MM/dd"
                return dateFomatter.string(from: date)
            } else {
                // 그 외 올해가 아닌 데이터 날짜는 년.월, 일 형식의 String을 반환
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                return formatter.string(from: date)
            }
        }
    }

}

#Preview {
    ChattingListRoomView()
        .environmentObject(ChattingListRoomViewModel())
        .environmentObject(UserAuth())
}
