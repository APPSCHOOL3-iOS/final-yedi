//
//  CMReservationInfoView.swift
//  YeDi
//
//  Created by 박채영 on 2023/10/13.
//

import SwiftUI
import FirebaseFirestore

/// 고객 예약 정보 뷰
struct CMReservationInfoView: View {
    // MARK: - Properties
    /// 고객 예약 내역 뷰 모델
    @EnvironmentObject var cmReservationHistoryViewModel: CMReservationHistoryViewModel
    
    @State private var designerName: String = ""
    @State private var designerRank: String = ""
    @State private var designerShop: String = ""
    @State private var reservationDate: String = ""
    @State private var styles: [String] = []
    
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    
    /// 표시할 예약 인스턴스
    var reservation: Reservation
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Group {
                // MARK: - 디자이너 직급 및 이름, 시술 내역
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(designerRank) \(designerName)")
                        .font(.title3)
                    HStack {
                        ForEach(styles, id: \.self) { style in
                            if styles.last == style {
                                Text("\(style)")
                                    .font(.title)
                            } else {
                                Text("\(style),")
                                    .font(.title)
                            }
                        }
                    }
                }
                .fontWeight(.semibold)
                
                // MARK: - 예약 일자
                HStack {
                    Text("\(reservationDate) 예약")
                    Spacer()
                }
            }
            .offset(y: 65)
            
            Spacer()
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 50)
                .frame(height: 300)
                .foregroundColor(.white)
                .shadow(color: Color.gray3, radius: 5, x: 0, y: 5)
                .opacity(0.2)
        )
        .offset(y: -70)
        .onAppear {
            Task {
                await cmReservationHistoryViewModel.fetchDesigner(designerId: reservation.designerUID)
                
                designerName = cmReservationHistoryViewModel.designer?.name ?? "Unknown"
                designerRank = cmReservationHistoryViewModel.designer?.rank.rawValue ?? "디자이너"
                designerShop = cmReservationHistoryViewModel.shop?.shopName ?? "프리랜서"
                
                reservationDate = dateFormatter.changeDateString(transition: "MM월 dd일 HH시 mm분", from: reservation.reservationTime)
                
                for hairStyle in reservation.hairStyle {
                    styles.append(hairStyle.name)
                }
            }
        }
    }
}

#Preview {
    CMReservationInfoView(reservation: Reservation(clientUID: "", designerUID: "", reservationTime: "", hairStyle: [], isFinished: true))
}
