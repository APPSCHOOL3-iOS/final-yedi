//
//  CMReservationHistoryDetailView.swift
//  YeDi
//
//  Created by Jaehui Yu on 2023/09/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

/// 예약 내역 디테일 뷰
struct CMReservationHistoryDetailView: View {
    // MARK: - Properties
    /// 고객 예약 내역 뷰 모델
    @EnvironmentObject var reservationHistoryViewModel: CMReservationHistoryViewModel
    
    @State private var designerName: String = ""
    @State private var designerRank: String = ""
    @State private var designerShop: String = ""
    @State private var designerShopAddress: String = ""
    @State private var reservationDate: String = ""
    @State private var styles: [String] = []
    @State private var price: Int = 0
    
    /// 샵 위치를 표시하기 위한 변수
    @State private var shop = MKCoordinateRegion()
    /// 주소 복사 확인용 Alert를 위한 Bool 타입 변수
    @State private var isShowingCopyAlert: Bool = false
    
    /// 싱글톤 date formatter
    private let dateFormatter = FirebaseDateFormatManager.sharedDateFormmatter
    
    /// 표시할 예약 인스턴스
    var reservation: Reservation
    
    /// 예약 상태를 나타내는 Bool 타입 변수
    var isUpcomingReservation: Bool {
        return !reservation.isFinished ? true : false
    }
    
    /// 예약 상태에 따른 텍스트
    var reservationStatusText: String {
        return !reservation.isFinished ? "다가오는 예약" : "지난 예약"
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Group {
                        // MARK: - 디자이너 정보 및 시술 내역
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
                        
                        // MARK: - 예약 일시 및 상태 정보
                        HStack {
                            Text(reservationDate)
                            Spacer()
                            Text(reservationStatusText)
                                .foregroundStyle(.white)
                                .padding(EdgeInsets(top: 7, leading: 15, bottom: 7, trailing: 15))
                                .background(
                                    Capsule(style: /*@START_MENU_TOKEN@*/.continuous/*@END_MENU_TOKEN@*/)
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    .offset(y: 50)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .frame(height: 300)
                        .foregroundColor(.white)
                        .shadow(color: .gray3, radius: 5, x: 0, y: 5)
                        .opacity(0.2)
                )
                .offset(y: -50)
                
                Spacer(minLength: 30)
                
                // MARK: - 샵 정보
                VStack(alignment: .leading) {
                    Text("샵 정보")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                    
                    Divider()
                        .frame(width: 360)
                        .background(Color.systemFill)
                        .padding(.bottom, 5)
                    
                    HStack {
                        Text("\(designerShopAddress)")
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.sub)
                            .onTapGesture {
                                UIPasteboard.general.string = designerShopAddress
                                isShowingCopyAlert.toggle()
                            }
                            .alert("클립보드에 복사되었습니다.", isPresented: $isShowingCopyAlert) {
                                Button("확인", role: .cancel) {
                                    isShowingCopyAlert.toggle()
                                }
                            }
                    }
                    
                    Map(coordinateRegion: $shop)
                        .frame(minHeight: 200)
                }
                .padding([.leading, .trailing])
                
                // MARK: - 결제 정보
                VStack(alignment: .leading) {
                    Text("결제정보")
                        .font(.system(size: 18))
                        .fontWeight(.semibold)
                    
                    Divider()
                        .frame(width: 360)
                        .background(Color.systemFill)
                    
                    HStack {
                        Text("결제수단")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        Text("카드 결제")
                    }
                    .padding(.top)
                    
                    HStack {
                        Text("결제금액")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        Text("\(price)원")
                    }
                    .padding(.top)
                }
                .padding()
                
                Spacer()
            }
            
            HStack {
                if isUpcomingReservation && reservationHistoryViewModel.review == nil {
                    NavigationLink {
                        CMNewReviewView(reservation: reservation)
                    } label: {
                        HStack {
                            Spacer()
                            Text("리뷰 작성")
                            Spacer()
                        }
                        .buttonModifier(.main)
                    }
                }
            }
            .padding([.leading, .trailing])
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                DismissButton(color: nil, action: {})
            }
        }
        .onAppear {
            Task {
                guard let reservationId = reservation.id else { return }
                
                styles = []
                
                await reservationHistoryViewModel.fetchDesigner(designerId: reservation.designerUID)
                await reservationHistoryViewModel.fetchReview(clientId: reservation.clientUID, reservationId: reservationId)
                
                // MARK: - 디자이너 및 샵, 예약 정보 패치
                let designer = reservationHistoryViewModel.designer
                let shop = reservationHistoryViewModel.shop
                
                designerName = designer?.name ?? ""
                designerRank = designer?.rank.rawValue ?? ""
                designerShop = shop?.shopName ?? ""
                designerShopAddress = "\(shop?.headAddress ?? "") \(shop?.subAddress ?? "") \(shop?.detailAddress ?? "")"
                reservationDate = dateFormatter.changeDateString(transition: "MM월 dd일 HH시 mm분", from: reservation.reservationTime)
                
                // MARK: - 시술 내역 패치
                for hairStyle in reservation.hairStyle {
                    styles.append(hairStyle.name)
                    price += hairStyle.price
                }
                
                // MARK: - 샵 정보 패치
                self.shop.center = CLLocationCoordinate2D(
                    latitude: reservationHistoryViewModel.shop?.latitude ?? 0,
                    longitude: reservationHistoryViewModel.shop?.longitude ?? 0
                )
                
                self.shop.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
}

#Preview {
    CMReservationHistoryDetailView(
        reservation:
            Reservation(
                clientUID: "",
                designerUID: "",
                reservationTime: "",
                hairStyle: [],
                isFinished: true
            )
    )
    .environmentObject(CMReservationHistoryViewModel())
}
