//
//  CMReservationHistoryCellView.swift
//  YeDi
//
//  Created by 박채영 on 2023/10/24.
//

import SwiftUI
import FirebaseFirestore

/// 고객 예약 내역 셀 뷰
struct CMReservationHistoryCellView: View {
    // MARK: - Properties
    /// 고객 예약 내역 뷰 모델
    @EnvironmentObject var reservationHistoryViewModel: CMReservationHistoryViewModel
    /// 고객 리뷰 뷰 모델
    @EnvironmentObject var reviewViewModel: CMReviewViewModel
    
    @State private var designer: Designer?
    @State private var shop: Shop?
    @State private var review: Review?
    
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    
    /// 표시할 예약 인스턴스
    let reservation: Reservation
    
    /// 예약 일시를 나타내는 String 타입 변수
    var reservationDate: String {
        return dateFormatter.changeDateString(transition: "MM월 dd일 HH시 mm분", from: reservation.reservationTime)
    }
    
    /// 예약 상태를 나타내는 Bool 타입 변수
    var isUpcomingReservation: Bool {
        return !reservation.isFinished ? true : false
    }
    
    /// 리뷰 작성 여부를 나타내는 Bool 타입 변수
    var isReviewExisting: Bool {
        return review != nil ? true : false
    }
    
    /// 리뷰 작성 여부에 따른 텍스트
    var reviewStatusText: String {
        return isReviewExisting ? "리뷰 작성 완료" : "리뷰 작성 전"
    }
    
    /// 디데이 텍스트
    var dDayText: String {
        let currentDate = dateFormatter.changeDateString(transition: "MM-dd", from: dateFormatter.firebaseDate(from: Date()))
        let reservationDate = dateFormatter.changeDateString(transition: "MM-dd", from: reservation.reservationTime)
        
        let startDate = dateFormatter.changeStringToDate(dateString: currentDate)
        let endDate = dateFormatter.changeStringToDate(dateString: reservationDate)
        let offsetComps = Calendar.current.dateComponents([.year, .month, .day], from: startDate, to: endDate)
        
        let dDay = offsetComps.day ?? 0
        
        return dDay == 0 ? "D-Day" : "D-\(dDay)"
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Spacer()
                // MARK: - 디데이 및 리뷰 작성 여부 표시 뱃지
                if isUpcomingReservation {
                    Text("\(dDayText)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(dDayText == "D-Day" ? .sub : .black)
                        )
                        .padding([.top, .trailing], 10)
                } else {
                    Text("\(reviewStatusText)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isReviewExisting ? Color.gray3 : .sub)
                        )
                        .padding([.top, .trailing], 10)
                }
            }
            
            Divider()
            
            Group {
                // MARK: - 디자이너 정보
                HStack {
                    Text("디자이너 정보")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(designer?.name ?? "Unknown")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryLabel)
                }
                .padding([.top, .horizontal])
                
                // MARK: - 샵 정보
                HStack {
                    Text("샵 정보")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(shop?.shopName ?? "Unknown")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryLabel)
                }
                .padding([.top, .horizontal])
                
                // MARK: - 예약 일시
                HStack {
                    Text("예약일시")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    Text("\(reservationDate) 예약")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryLabel)
                }
                .padding([.top, .horizontal])
                
                // MARK: - 시술 내역
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
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.primaryLabel)
                                    
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
            }
            .onAppear {
                Task {
                    // MARK: - 디자이너 및 샵 정보 패치
                    await reservationHistoryViewModel.fetchDesigner(designerId: reservation.designerUID)
                    self.designer = reservationHistoryViewModel.designer
                    self.shop = reservationHistoryViewModel.shop
                    
                    // MARK: - 예약건에 해당하는 리뷰 패치
                    guard let reservationId = reservation.id else { return }
                    self.review = reviewViewModel.reviews.filter { $0.reservationId == reservationId }.first
                }
            }
        }
    }
}

#Preview {
    CMReservationHistoryCellView(
        reservation: Reservation(
            clientUID: "",
            designerUID: "",
            reservationTime: "",
            hairStyle: [],
            isFinished: false
        )
    )
    .environmentObject(CMReservationHistoryViewModel())
    .environmentObject(CMReviewViewModel())
}
