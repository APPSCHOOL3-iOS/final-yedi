//
//  ReservationView.swift
//  YeDi
//
//  Created by 송성욱 on 2023/09/26.
//

import SwiftUI

struct ReservationView: View {
    // Properties
    @State private var show: Bool = false
    @State private var isClicked: Bool = false
    @State private var isShowing: Bool = false
    @State private var currentDay: Date = .init()
    @State var showingRestDaySetting: Bool = false
    @State var showingBreakTimeSetting: Bool = false
    @State var selectedDate: Date = Date()
    @State var clientName: String = ""
    @ObservedObject var reservationVM = ReservationVM()
    
    // MARK: - Reservation List View
    var body: some View {
        VStack {
            HCustomCalendar(selectedDate: $selectedDate)
                .padding(.bottom)
                .padding(.horizontal)
                .scrollIndicators(.hidden)
            HStack {
                VStack {
                    Divider()
                }
                Text("예약현황")
                    .font(.caption)
                    .foregroundStyle(.gray)
                VStack {
                    Divider()
                }
            }
            .padding(.horizontal)
            
            ZStack {
                ScrollView {
                    TimeLineView()
                }
                .padding(.horizontal, 10)
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        FloatingButton(show: $show, showingRestDaySetting: $showingRestDaySetting, showingBreakTimeSetting: $showingBreakTimeSetting)
                            .padding(.top)
                            .padding(.bottom)
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .onAppear {
            reservationVM.getReservation()
        }
        .refreshable {
            reservationVM.getReservation()
        }
    }
    
    /// - Timeline Main View
    @ViewBuilder
    func TimeLineView() -> some View {
        ScrollViewReader { proxy in
            let hours = Calendar.current.hours
            let midHour = hours[hours.count / 2]
            VStack {
                ForEach(hours, id: \.self) { hour in
                    TimelineViewRow(hour)
                        .id(hour)
                }
            }
            .onAppear {
                proxy.scrollTo(midHour)
            }
        }
    }
    
    // MARK: - Timeline View Row
    @ViewBuilder
    func TimelineViewRow(_ date: Date) -> some View {
        HStack(alignment: .top) {
            Text(date.toString("h a"))
                .font(.body)
                .frame(width: 50, alignment: .leading)
            
            /// - Filter Reservations by time
            let filteredReservations = reservationVM.reservations.filter { reservation in
                if let reservationTime = stringToDate(reservation.reservationTime, format: "yyyy-MM-dd'T'HH:mm:ssZZZZZ") {
                    return Calendar.current.isDate(reservationTime, inSameDayAs: selectedDate) && Calendar.current.component(.hour, from: reservationTime) == Calendar.current.component(.hour, from: date)
                }
                return false
                // 필터링된 예약 데이터를 사용하여 뷰에 업데이트
                // filteredReservations를 사용하여 뷰를 업데이트
            }
            
            // 예약이 비어있으면 셀에 표시를 안해주고 예약 내용이 있을 시 셀에 내용을 보여줍니다.
            if filteredReservations.isEmpty {
                Rectangle()
                    .stroke(.gray.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, lineCap: .butt, lineJoin: .bevel))
                    .frame(height: 0.5)
                    .offset(y: 10)
            } else {
                /// - Reservation View
                VStack(spacing: 10) {
                    ForEach(filteredReservations) { reservation in
                        reservationRow(reservation)
                        // 다른 예약 정보 필드를 표시할 수 있습니다.
                    }
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // Expand HStack to full width
        .padding(.vertical, 15)
    }
    
    // MARK: - Reservation History Row
    @ViewBuilder
    func reservationRow(_ reservation: Reservation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(clientName)
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(reservation.hairStyle) { style in
                HStack {
                    Text("\(style.name)")
                        .font(.system(size: 15))
                    Spacer()
                    Text("\(style.type.rawValue)")
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 10)
                
                Text("\(style.price)원")
                    .font(.system(size: 15))
                    .padding(.leading, 10)
            }
            HStack {
                Text("\(FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yy.MM.dd. HH:mm", from: reservation.reservationTime))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(reservation.isFinished ? "시술완료" : "예약완료")")
                    .font(.system(size: 15))
                    .padding(3)
                    .foregroundStyle(Color.whiteMainColor)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(reservation.isFinished ? Color.mainColor : Color.accentColor)
                    }
            }
            .padding(.leading, 10)
        }
        .hAlign(.leading)
        .padding(12)
        .background {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray3)
                    .frame(width: 310)
                Rectangle()
                    .fill(.gray)
                    .frame(width: 4)
                
            }
        }
        .onAppear {
            reservationVM.getClientData(for: reservation.clientUID) { client in
                clientName = client.name
            }
        }
    }
    
    func stringToDate(_ dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - Custom FloatingButton [완성]
struct FloatingButton: View {
    @Binding var show: Bool
    @State var angle: Double = 180
    @Binding var showingRestDaySetting: Bool
    @Binding var showingBreakTimeSetting: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if self.show {
                Button {
                    showingRestDaySetting.toggle()
                } label: {
                    Text("휴무")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray3)
                        .frame(width: 30, height: 30).padding(7)
                }
                .background(Color.white)
                .foregroundColor(Color.gray4)
                .clipShape(Circle())
                .shadow(radius: 5)
                .sheet(isPresented: $showingRestDaySetting, content: {
                    WkDaySettingDetail(showingRestDaySetting: $showingRestDaySetting)
                })
                
                Button {
                    showingBreakTimeSetting.toggle()
                } label: {
                    Text("휴게")
                        .font(.system(size: 15))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray3)
                        .frame(width: 30, height: 30).padding(7)
                }
                .background(Color.white)
                .foregroundColor(Color.gray4)
                .clipShape(Circle())
                .shadow(radius: 5)
                .sheet(isPresented: $showingBreakTimeSetting, content: {
                    TimeSettingDetail(showingBreakTimeSetting: $showingBreakTimeSetting)
                })
            }
            
            Button {
                self.show.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .resizable()
                    .frame(width: 30, height: 30).padding(7)
            }
            .background(Color.white)
            .foregroundColor(Color.gray4)
            .clipShape(Circle())
            .shadow(radius: 5)
            .rotationEffect(.init(degrees: self.show ? 100 : 0))
        }
        .animation(.spring, value: angle)
    }
}

// MARK: - Extension
extension View {
    func hAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
}

extension Calendar {
    /// - Return 24 Hours in  a day
    var hours: [Date] {
        let startOfDay = self.startOfDay(for: Date())
        var hours: [Date] = []
        for index in 0..<24 {
            if let date =  self.date(byAdding: .hour, value: index, to: startOfDay) {
                hours.append(date)
            }
        }
        return hours
    }
    
    /// - Used to Store Data of Each Week Day
    struct WeekDay: Identifiable {
        var id: UUID = .init()
        var string: String
        var date: Date
        var isToday: Bool = false
    }
}

extension Date {
    func toString(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

#Preview {
    ReservationView()
}
