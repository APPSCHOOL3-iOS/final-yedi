//
//  CMSelectStyleView.swift
//  YeDi
//
//  Created by SONYOONHO on 2023/10/18.
//

// TODO: subColor 사용할 만한 곳이 있는지

import SwiftUI

struct CMSelectStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postDetailViewModel: PostDetailViewModel
    @EnvironmentObject var reservationViewModel: CMReservationViewModel
    @Binding var isPresentedNavigation: Bool
    @State private var selectedHairStyles: [HairStyle] = []
    @State private var isSelectedStyle: Bool = false
    @State private var animationRange: [Int] = []
    @State private var value: Int = 0
    var stringFormattedDate: String {
        FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "yyyy년 MM월 dd일 (EE)", from: selectedStringDate)
    }
    var stringFormattedTime: String {
        FirebaseDateFormatManager.sharedDateFormmatter.changeDateString(transition: "HH:mm", from: selectedStringDate)
    }
    let selectedStringDate: String
    let selectedTime: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toolbarView

            ScrollView {
                VStack(alignment: .leading) {
                    dateTimeView
                    divider
                }
                styleView(title: "커트", hairStyles: HairStyle.data.filter { $0.type == .cut })
                divider
                styleView(title: "펌", hairStyles: HairStyle.data.filter { $0.type == .perm })
                divider
                styleView(title: "염색", hairStyles: HairStyle.data.filter { $0.type == .color })
            }
            
            Divider()
            checkButtonView
        }
        .background(Color.whiteMainColor)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            animationRange = Array(repeating: 0, count: "\(value)".count)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                updateText()
            }
        }
        .onChange(of: value) { newValue in
            let extra = "\(value)".count - animationRange.count
            if extra > 0 {
                for _ in 0..<extra {
                    withAnimation(.easeIn(duration: 0.2)) {
                        animationRange.append(0)
                    }
                }
            } else {
                for _ in 0..<(-extra) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        animationRange.removeLast()
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateText()
            }
        }
    }
    
    func updateText() {
        let stringValue = "\(value)"
        for (index, value) in zip(0..<stringValue.count, stringValue) {
            var fraction = Double(index) * 0.15
            
            fraction = (fraction > 0.5 ? 0.5 : fraction)
            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 1 + fraction, blendDuration: 1 + fraction)) {
                animationRange[index] = (String(value) as NSString).integerValue
            }
        }
    }
    
    // MARK: - 툴바 뷰
    private var toolbarView: some View {
        HStack(alignment: .center) {
            DismissButton(color: Color.primary) { }
            Spacer()
        }
        .padding()
    }
    
    // MARK: - FooterView
    private var checkButtonView: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Text("총 결제금액")
                    .font(.subheadline)
                    .foregroundStyle(Color.primaryLabel)
                HStack(spacing: 0) {
                    ForEach(0..<animationRange.count, id: \.self) { index in
                        Text("0")
                            .font(.title2)
                            .fontWeight(.bold)
                            .opacity(0)
                            .overlay {
                                GeometryReader { proxy in
                                    let size = proxy.size
                                    
                                    VStack(spacing: 0) {
                                        ForEach(0...9, id: \.self) { number in
                                            
                                            Text("\(number)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .frame(width: size.width, height: size.height, alignment: .center)
                                                .foregroundStyle(Color.subColor)
                                        }
                                    }
                                    .offset(y: -CGFloat(animationRange[index]) * size.height)
                                }
                                .clipped()
                            }
                    }
                    Text("원")
                        .font(.subheadline)
                        .padding(.leading, 5)
                        .foregroundStyle(Color.primaryLabel)
                }
                
            }
            .padding(.horizontal)

            NavigationLink {
                CMReservationCheckView(isPresentedNavigation: $isPresentedNavigation, reservation: Reservation(clientUID: "", designerUID: postDetailViewModel.designer?.designerUID ?? "", reservationTime: selectedStringDate, hairStyle: selectedHairStyles, isFinished: false))
                    .environmentObject(reservationViewModel)
                    .environmentObject(postDetailViewModel)
            } label: {
                Text("\(isSelectedStyle ? "선택 완료 (\(selectedHairStyles.count)개 선택됨)" : "스타일을 선택해주세요")")
                    .font(.headline)
                    .foregroundStyle(isSelectedStyle ? Color.whiteMainColor : Color.whiteMainColor)
                    .fontWeight(.bold)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(isSelectedStyle ? Color.subColor : Color.gray4)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding([.bottom, .horizontal])
            .disabled(!isSelectedStyle)
        }
        .ignoresSafeArea()
        .padding(.top)
        .background(Color.whiteMainColor)
    }
    
    private var dateTimeView: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("예약 날짜")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top)
            
            HStack {
                Text("날짜")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                    .padding(.trailing)
                
                Text("\(stringFormattedDate)")
                    .font(.headline)
            }
            .padding(.vertical)
            
            HStack {
                Text("시간")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                    .padding(.trailing)
                
                Text("\(formatTime(stringFormattedTime))")
                    .font(.headline)
            }
        }
        .padding()
    }
    
    private func styleView(title: String, hairStyles: [HairStyle]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading)
            
            ForEach(hairStyles) { hair in
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(hair.name)")
                            .fontWeight(.medium)
                        
                        HStack(spacing: 2) {
                            Text("\(hair.price)")
                                .fontWeight(.bold)
                            Text("원")
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(selectedHairStyles.contains(hair) ? Color.subColor : Color.gray4) // Checkmark 색 변경
                }
                .onTapGesture {
                    toggleSelection(for: hair)
                    calculateTotalPrice()
                }
            }
            .padding(.horizontal)

        }
        .padding([.top])
    }
    
    private func toggleSelection(for hairStyle: HairStyle) {
        if selectedHairStyles.contains(hairStyle) {
            selectedHairStyles.removeAll { $0 == hairStyle }
        } else if !selectedHairStyles.contains(where: { $0.type == hairStyle.type }) {
            selectedHairStyles.append(hairStyle)
        } else {
            selectedHairStyles.removeAll { $0.type == hairStyle.type }
            selectedHairStyles.append(hairStyle)
        }
        self.isSelectedStyle = !selectedHairStyles.isEmpty
        let cutStyles = selectedHairStyles.filter { $0.type == .cut }
        let permStyles = selectedHairStyles.filter { $0.type == .perm }
        let colorStyles = selectedHairStyles.filter { $0.type == .color }

        selectedHairStyles = cutStyles + permStyles + colorStyles
    }
    
    private func calculateTotalPrice() {
        let total = selectedHairStyles.reduce(0) { $0 + $1.price }
        value = total
    }
    
    func formatTime(_ time: String) -> String {
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

private var divider: some View {
    Divider()
        .frame(minHeight: 10)
        .overlay(Color.divider)
}

#Preview {
    NavigationStack {
        CMSelectStyleView(isPresentedNavigation: .constant(true), selectedStringDate: "2023-10-22T16:02:13+0900", selectedTime: 11)
            .environmentObject(PostDetailViewModel())
            .environmentObject(CMReservationViewModel())
    }
}
