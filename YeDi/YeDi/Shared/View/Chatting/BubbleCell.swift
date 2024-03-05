//
//  BubbleCell.swift
//  YeDi
//
//  Created by yunjikim on 2023/09/30.
//

import SwiftUI

struct BubbleCell: View {
    let chat: CommonBubble
    let isMyBubble: Bool
    
    private var chatTime: String {
        let instance = FirebaseDateFormatManager.sharedDateFormmatter
        let date = instance.changeDateString(transition: "MM/dd HH:mm", from: chat.date)
        return date
    }
    
    var body: some View {
        VStack(alignment: isMyBubble ? .trailing : .leading, spacing: 0) {
            HStack(alignment: .top) {
                messageBubble
            }
        }
        .frame(maxWidth: .infinity, alignment: isMyBubble ? .trailing : .leading)
        .padding(.horizontal, 10)
        .padding(.bottom, 5)
    }
    
    private var messageBubble: some View {
        HStack(alignment: .bottom) {
            if isMyBubble {
                HStack(alignment: .center) {
                    if !chat.isRead {
                        readMarkCircle
                    }
                    chatDateMark
                }
            }
            
            switch chat.messageType {
            case .textBubble:
                Text(chat.content ?? "")
                    .chatBubbleModifier(isMyBubble)
            case .imageBubble:
                ImageBubbleCell(imagePath: chat.imagePath ?? "")
            case .boardBubble:
                BoardBubbleCell(boardBubble: chat, isMyBubble: isMyBubble)
            }
            
            if !isMyBubble {
                HStack(alignment: .center) {
                    chatDateMark
                    if !chat.isRead {
                        readMarkCircle
                    }
                }
            }
        }
    }
    
    private var chatDateMark: some View {
        Text(changetoDateFormat(chat.date))
            .font(.caption2)
            .foregroundStyle(.gray)
    }
    
    private var readMarkCircle: some View {
        Circle()
            .frame(width: 8, height: 8)
            .foregroundStyle(Color.subColor)
    }
    
    /// 채팅방  최근 메세지 날짜 표출형식 커스텀 메소드
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
                dateFomatter.dateFormat = "MM/dd HH:mm"
                return dateFomatter.string(from: date)
            } else {
                // 그 외 올해가 아닌 데이터 날짜는 년.월, 일 형식의 String을 반환
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd HH:mm"
                return formatter.string(from: date)
            }
        }
    }
}
