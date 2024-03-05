//
//  CMReservationDateTimeView.swift
//  YeDi
//
//  Created by SONYOONHO on 2023/09/27.
//

import SwiftUI

struct CMReservationDateTimeView: View {
    @EnvironmentObject var postDetailViewModel: PostDetailViewModel
    @StateObject var reservationViewModel: CMReservationViewModel = CMReservationViewModel()
    @State private var currentMonth: Int = 0
    @State private var currentDate: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Int = 0
    @State private var isLoaded: Bool = false
    @Binding var isPresentedAlert: Bool
    @Binding var isPresentedNavigation: Bool
    private var isDateTimeSelected: Bool {
        selectedTime != 0
    }
    private var startTime: Int {
        reservationViewModel.openingTime
    }
    private var endTime: Int {
        reservationViewModel.closingTime
    }
    private let interval = 1
    private var isCurrentMonth: Bool {
        currentMonth == 0
    }
    private let days: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    let designerID: String
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            titleView
            monthView
            weekdaysView
            calendarView
            divider
            reservationTimeView
            Spacer()
            footerView
        }
        .background(Color.whiteMainColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                isLoaded = false
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await reservationViewModel.fetchCalendar(designerUID: designerID)
                    }
                    
                    group.addTask {
                        await reservationViewModel.fetchOperatingTime(designerUID: designerID)
                    }
                    
                    group.addTask {
                        await reservationViewModel.fetchAvailableReservationTime(date: selectedDate, designerUID: postDetailViewModel.designer?.designerUID ?? "")
                    }
                    
                }
                isLoaded = true
            }
        }
        .onChange(of: currentMonth) { newValue in
            withAnimation(.easeOut) {
                currentDate = getCurrentMonth()
            }
        }
        .alert(
            "주의",
            isPresented: $isPresentedAlert
        ) {
            Button("확인") {
            }
        } message: {
            Text("예약 시간을 지키지 못해 발생하는 모든 불이익은 책임지지 않으니 신중한 예약 부탁드립니다.")
        }
    }

    private var divider: some View {
        Divider()
            .frame(minHeight: 10)
            .overlay(Color.divider)
            .padding(.top)
    }
    
    private var calendarView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
            ForEach(extractDate()) { value in
                CardView(value: value)
                    .background(
                        Circle()
                            .fill(Color.subColor)
                            .opacity(calculateOpacity(value: value))
                    )
                    .onTapGesture {
                        if !value.isClosed {
                            if !value.isPast {
                                selectedDate = value.date
                                selectedTime = 0
                                Task {
                                    isLoaded = false
                                    await reservationViewModel.fetchAvailableReservationTime(date: selectedDate, designerUID: postDetailViewModel.designer?.designerUID ?? "")
                                    isLoaded = true
                                }
                            }
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 툴바 뷰
    private var toolbarView: some View {
        HStack(alignment: .center) {
            DismissButton(color: Color.primaryLabel) { }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 타이틀 뷰
    @ViewBuilder
    private var titleView: some View {
        HStack {
            Text("날짜선택")
                .foregroundStyle(Color.primaryLabel)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding([.horizontal, .bottom])
        
        Divider()
            .padding([.horizontal, .bottom])
    }
    
    // MARK: -  요일 뷰
    private var weekdaysView: some View {
        HStack {
            ForEach(days, id: \.self) { day in
                Text("\(day)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - 달력 뷰
    private var monthView: some View {
        HStack {
            Button {
                if currentMonth > 0 {
                    currentMonth -= 1
                    currentDate = Date() // 이번달 이전의 달로 이동할 때 currentDate를 초기화
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(isCurrentMonth ? .gray : Color.subColor)
                
            }
            .disabled(isCurrentMonth)
            
            Text("\(extraData()[0]). \(extraData()[1])")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button {
                currentMonth += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(Color.subColor)
            }
        }
        .padding(.bottom)
    }
    
    // MARK: - 달력 날짜 뷰
    @ViewBuilder
    func CardView(value: CalendarModel) -> some View {
        VStack {
            if value.day != -1 {
                Text("\(value.day)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(calculateTextColor(value: value))
                    .frame(maxWidth: .infinity)
                
                if value.isClosed &&
                    !value.isPast {
                    Text("휴무")
                        .font(.caption)
                        .foregroundStyle(Color.subColor)
                }
            }
        }
        .padding(.vertical, 7)
    }
    
    // MARK: - 시간 선택 뷰
    private var reservationTimeView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("시간선택")
                    .foregroundStyle(Color.primaryLabel)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding([.horizontal, .vertical])

            Divider()
                .padding([.horizontal, .bottom])
            if isLoaded {
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [GridItem(.flexible(minimum: 50), spacing: 20)]) {
                        ForEach(startTime..<(endTime + 1), id: \.self) { hour in
                            let timeString = String(format: "%02d:00", hour)
                            let isRerserved = reservationViewModel.impossibleTime.contains(hour)
                            let isPastTime: Bool = {
                                if Calendar.current.isDateInToday(selectedDate) {
                                    return hour <= Calendar.current.component(.hour, from: Date())
                                }
                                return false
                            }()
                            
                            Text(timeString)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(isRerserved || isPastTime ? Color.gray : (selectedTime == hour ? .white : Color.primaryLabel))
                                .padding(.vertical, 13)
                                .padding(.horizontal, 15)
                                .background(
                                    Capsule()
                                        .foregroundStyle(isRerserved || isPastTime ? Color.gray4 : (selectedTime == hour ? Color.subColor : Color.tertiarySystemGroupedBackground))
                                )
                                .onTapGesture {
                                    if !isRerserved && !isPastTime {
                                        if selectedTime == hour {
                                            selectedTime = 0
                                        } else {
                                            selectedTime = hour
                                            let calendar = Calendar.current
                                            let newDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)!
                                            selectedDate = newDate
                                        }
                                    } else {
                                        // TODO: 토스트 메세지로 "예약이 되었거나 이미 지난 시간대 입니다." 알림
                                    }
                                }
                        }
                    }
                    .padding(.leading)
                }
                .scrollIndicators(.hidden)
            } else {
                ProgressView()
            }
        }
    }
    
    private var footerView: some View {
        NavigationLink {
            CMSelectStyleView(isPresentedNavigation: $isPresentedNavigation, selectedStringDate: FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: selectedDate), selectedTime: selectedTime)
                .environmentObject(postDetailViewModel)
                .environmentObject(reservationViewModel)
        } label: {
            Text("\(isDateTimeSelected ? "스타일 선택하기" : "날짜 / 시간을 선택해주세요")")
                .foregroundStyle(isDateTimeSelected ? Color.whiteMainColor : Color.whiteMainColor)
                .fontWeight(.bold)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(isDateTimeSelected ? Color.subColor : Color.gray4)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding([.horizontal, .bottom])
        .disabled(!isDateTimeSelected)
    }
}

// MARK: - 날짜 & UI 처리 메서드
private extension CMReservationDateTimeView {
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    private func calculateOpacity(value: CalendarModel) -> Double {
        if isSameDay(date1: value.date, date2: selectedDate) && value.isToday {
            return 1.0
        } else if isSameDay(date1: value.date, date2: selectedDate) {
            return 0.2
        } else {
            return 0.0
        }
    }
    
    private func calculateTextColor(value: CalendarModel) -> Color {
        if isSameDay(date1: value.date, date2: selectedDate) && value.isToday {
            return .white
        } else if value.isToday {
            return .subColor
        } else if isSameDay(date1: value.date, date2: selectedDate) {
            return .subColor
        } else if value.isPast {
            return .gray
        } else if value.isClosed {
            return .gray
        } else {
            return .primary
        }
    }
    
    // MARK: - 선택 된 현재 년, 월을 문자열 배열로 반환
    /// 예시 : `["2023", "10"]`
    private func extraData() -> [String] {
        let dateString = FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: currentDate)
        let date = FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "YYYY MM", from: dateString)
        return date.components(separatedBy: " ")
    }
    
    // MARK: - 선택 된 현재 달의 Date값을 가져옴
    private func getCurrentMonth() -> Date {
        let calendar = Calendar.current
        guard let currentMonth = calendar.date(byAdding: .month, value: self.currentMonth, to: Date()) else {
            return Date()
        }
        
        return currentMonth
    }
    
    // MARK: - 선택 된 월의 날짜 정보를 추출하여 각 날짜에 대한 데이터를 CalendarModel객체 배열로 반환
    private func extractDate() -> [CalendarModel] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        
        let firstDayOfMonth = calendar.date(from: components)!

        let today = Calendar.current.startOfDay(for: Date())
        
        var days = firstDayOfMonth.getAllDates().compactMap { date -> CalendarModel in
            let day = calendar.component(.day, from: date)
            let isPast = calendar.compare(date, to: today, toGranularity: .day) == .orderedAscending
            let isToday = calendar.isDate(date, inSameDayAs: today)
            
            let oneDayAgo = calendar.date(byAdding: .day, value: +1, to: date)!
            let isClosed = reservationViewModel.dates.contains { reservationDate in
                return calendar.isDate(reservationDate, inSameDayAs: oneDayAgo)
            }
            
            return CalendarModel(day: day, date: date, isPast: isPast, isToday: isToday, isClosed: isClosed)
        }
        
        let firstWeekday = calendar.component(.weekday, from: days.first?.date ?? Date())
        
        for _ in 0..<firstWeekday - 1 {
            days.insert(CalendarModel(day: -1, date: Date(), isPast: true, isToday: false, isClosed: false), at: 0)
        }
        
        return days
    }
}

extension Date {
    // MARK: - 주어진 날짜를 기준으로 해당 월의 모든 날짜를 배열로 반환
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        return range.compactMap { day -> Date in
            // 날짜의 `day` 값으로 현재 월의 첫번째 날로부터 날짜를 계산
            return calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }
}

struct CalendarModel: Identifiable {
    let id = UUID().uuidString
    var day: Int
    let date: Date
    let isPast: Bool
    let isToday: Bool
    let isClosed: Bool
}
