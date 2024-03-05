//
//  CMReservationCheckView.swift
//  YeDi
//
//  Created by SONYOONHO on 2023/10/22.
//

import SwiftUI

struct CMReservationCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var reservationViewModel: CMReservationViewModel
    @EnvironmentObject var postDetailViewModel: PostDetailViewModel
    @Binding var isPresentedNavigation: Bool
    @State private var scale = 0.5
    let reservation: Reservation
    var stringFormattedDate: String {
        FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yyyy년 MM월 dd일 (EE)", from: reservation.reservationTime)
    }
    var stringFormattedTime: String {
        FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "HH:mm", from: reservation.reservationTime)
    }
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            
            informationView
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.subColor)
                Text("예약 정보")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryLabel)
                        
                Spacer()
            }
            .padding([.horizontal, .top])
            
            designerView
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding([.horizontal, .bottom])
                .padding(.top, 10)
            Spacer()
            
            completionButtonView
        }
        .background(Color.divider)
        .navigationBarBackButtonHidden(true)
    }
    
    private var informationView: some View {
        VStack(alignment: .center) {
            
            HStack {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(maxWidth: 10)
                        .foregroundStyle(Color.subColor)
                }
            }
            .padding(.vertical)
            
            Text("예약을 확정하기 전")
            Text("예약 정보를 다시 한번 확인해주세요")
        }
        .padding(.vertical)
    }
    // MARK: - 툴바 뷰
    private var toolbarView: some View {
        HStack(alignment: .center) {
            DismissButton(color: Color.primary) { }
            Spacer()
        }
        .padding()
        .background(Color.whiteMainColor)
    }
    
    private var designerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if postDetailViewModel.designer?.imageURLString != "" {
                    AsnycCacheImage(url: postDetailViewModel.designer?.imageURLString ?? "")
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 60, maxHeight: 60)
                            .clipShape(Circle())
                } else {
                    Text(String(postDetailViewModel.designer?.name.first ?? " ").capitalized)
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.quaternarySystemFill))
                                .foregroundColor(Color.primaryLabel)
                }

                VStack(alignment: .leading) {
                    Text("\(postDetailViewModel.designer?.name ?? "디자이너")")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(postDetailViewModel.designer?.description ?? "소개")")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 10)
            }
            .padding(.bottom)
            
            Divider()
            
            Group {
                HStack {
                    Text("샵 정보")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("루디헤어 연신내점")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding([.top, .horizontal])
                
                HStack {
                    Text("예약날짜")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(stringFormattedDate)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding([.top, .horizontal])
                
                HStack {
                    Text("예약시간")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(formatTime(stringFormattedTime))")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding([.top, .horizontal])
                
                HStack(alignment: .top) {
                    Text("스타일")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Group {
                            ForEach(reservation.hairStyle) { hairStyle in
                                VStack(alignment: .trailing) {
                                    Text("\(hairStyle.name)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Text("\(hairStyle.price)원")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .padding(.bottom, 10)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding([.top, .horizontal])
                
                Divider()

                HStack(spacing: 0) {
                    Text("총 금액")
                        .foregroundStyle(Color.primaryLabel)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(totalPrice())")
                        .fontWeight(.bold)
                        .font(.title3)
                        .foregroundStyle(Color.subColor)
                    Text("원")
                }
                .padding()
            }
        }
        .padding([.horizontal, .top])
        .background(Color.whiteMainColor)
    }
    
    private var completionButtonView: some View {
        VStack {
            Button {
                Task {
                    await reservationViewModel.createReservation(reservation: reservation)
                    isPresentedNavigation = false
                }
                
            } label: {
                Text("예약하기")
                    .font(.headline)
                    .foregroundStyle(Color.whiteMainColor)
                    .fontWeight(.bold)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.subColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
    }
    
    private var divider: some View {
        Divider()
            .frame(minHeight: 15)
            .overlay(Color.lightGrayColor)
    }
    
    private func totalPrice() -> Int {
        return reservation.hairStyle.reduce(0) { $0 + $1.price }
    }
    
    private func formatTime(_ time: String) -> String {
        if let hour = Int(time.prefix(2)), let minute = Int(time.suffix(2)) {
            if hour < 12 {
                return "오전 \(hour):\(minute)0"
            } else if hour == 12 {
                return "오후 \(hour):\(minute)0"
            } else {
                return "오후 \(hour - 12):\(minute)0"
            }
        } else {
            return "유효하지 않은 입력"
        }
    }
}

#Preview {
    CMReservationCheckView(isPresentedNavigation: .constant(true), reservation: Reservation(clientUID: "", designerUID: "", reservationTime: "2023년 10월 22일 일요일", hairStyle: [HairStyle(name: "레이어드컷", type: .cut, price: 45000), HairStyle(name: "리프펌", type: .perm, price: 46000)], isFinished: false))
        .environmentObject(PostDetailViewModel())
        .environmentObject(CMReservationViewModel())
}
