//
//  CMLastReservationListView.swift
//  YeDi
//
//  Created by Jaehui Yu on 2023/09/26.
//

import SwiftUI
import FirebaseFirestore

/// 고객 지난 예약 목록 뷰
struct CMLastReservationListView: View {
    // MARK: - Properties
    /// 유저 Auth 관리 뷰 모델
    @EnvironmentObject var userAuth: UserAuth
    /// 고객 예약 내역 뷰 모델
    @EnvironmentObject var reservationHistoryViewModel: CMReservationHistoryViewModel
    
    /// 지난 예약 목록 변수
    @State private var lastReservations: [Reservation] = []
    
    // MARK: - Body
    var body: some View {
        VStack {
            if lastReservations.isEmpty {
                Spacer()
                Text("지난 예약이 없습니다")
                    .fontWeight(.bold)
            } else {
                ScrollView {
                    ForEach(lastReservations.indices, id: \.self) { index in
                        let reservation = lastReservations[index]
                        NavigationLink {
                            CMReservationHistoryDetailView(reservation: reservation)
                        } label: {
                            CMReservationHistoryCellView(reservation: reservation)
                                .background(Color.gray6)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding([.leading, .trailing])
                                .padding(.top, 5)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear(perform: {
            Task {
                await reservationHistoryViewModel.fetchReservation(userAuth: userAuth)
                
                // 지난 예약만 가져오도록 필터링
                lastReservations = reservationHistoryViewModel.reservations.filter({ $0.isFinished == true })
                // 지난 예약 > 예약 일시가 먼 순으로 정렬
                lastReservations = lastReservations.sorted { $0.reservationTime > $1.reservationTime }
            }
        })
    }
}

#Preview {
    CMLastReservationListView()
        .environmentObject(UserAuth())
        .environmentObject(CMReservationHistoryViewModel())
}
