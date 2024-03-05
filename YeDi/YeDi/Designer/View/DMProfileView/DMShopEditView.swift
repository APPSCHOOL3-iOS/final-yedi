//
//  DMShopEditView.swift
//  YeDi
//
//  Created by 김성준 on 10/18/23.
//
// ToDo: 휴무일 설정 필요

import SwiftUI

struct DMShopEditView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    let dateFomatter = FirebaseDateFormatManager.sharedDateFormmatter
    
    @Binding var shop: Shop
    @Binding var rank: Rank
    @Binding var isShowDesignerShopEditView: Bool
    
    @State private var isNotEmptyDescription: Bool = true
    @State private var isPhoneNumberValid: Bool = false
    
    @State private var closedDay: String = ""
    
    @State private var isShowingOpeningHourDatePicker: Bool = false
    @State private var isShowingClosingHourDatePicker: Bool = false
    @State private var previewTextOpeningHour: String = "10:00 오전"
    @State private var previewTextClosingHour: String = "19:00 오후"
    @State private var openingHour: Date = Date()
    @State private var closingHour: Date = Date()
    
    var initOpeningDate: Date {
        let stringDate = "2000-01-01T10:00:00+0900"
        guard let date = dateFomatter.firebaseDateFormat().date(from: stringDate) else { return Date() }
        return date
    }
    var initClosingDate: Date {
        let stringDate = "2000-01-01T19:00:00+0900"
        guard let date = dateFomatter.firebaseDateFormat().date(from: stringDate) else { return Date() }
        return date
    }
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userAuth: UserAuth
    private let ranks: [Rank] = [.Owner, .Principal, .Designer, .Intern]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center) {
                        HStack {
                            Text("직급")
                            requiredFieldMark
                        }
                        
                        Spacer()
                        
                        Menu(rank.rawValue) {
                            Picker("select your rank", selection: $rank) {
                                ForEach(ranks, id: \.self) { rank in
                                    Text(rank.rawValue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(11)
                            .foregroundStyle(Color.primary)
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.quaternarySystemFill)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(11)
                        .foregroundStyle(Color.primary)
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.quaternarySystemFill)
                        }
                        
                    }
                    
                    Group {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("샵 이름")
                            TextField("이름", text: $shop.shopName)
                                .signInTextFieldStyle(isTextFieldValid: $isNotEmptyDescription)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("오픈 시간")
                                Button {
                                    isShowingOpeningHourDatePicker.toggle()
                                } label: {
                                    Text(previewTextOpeningHour)
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(Color.primaryLabel)
                                        .background {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.quaternarySystemFill)
                                        }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("마감 시간")
                                Button {
                                    isShowingClosingHourDatePicker.toggle()
                                } label: {
                                    Text(previewTextClosingHour)
                                        .foregroundStyle(Color.primaryLabel)
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.quaternarySystemFill)
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 7)
                        .sheet(isPresented: $isShowingOpeningHourDatePicker) {
                            VStack {
                                DatePicker("오픈 시간", selection: $openingHour, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                
                                Button {
                                    let stringHour = dateFomatter.firebaseDate(from: openingHour)
                                    let hour = dateFomatter.changeDateString(transition: "HH:mm a", from: stringHour)
                                    previewTextOpeningHour = hour
                                    
                                    isShowingOpeningHourDatePicker.toggle()
                                } label: {
                                    Text("선택 완료")
                                        .frame(width: 330, height: 30)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                            }
                            .presentationDetents([.fraction(0.4)])
                        }
                        .sheet(isPresented: $isShowingClosingHourDatePicker) {
                            VStack {
                                DatePicker("마감 시간", selection: $closingHour, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                
                                Button {
                                    let stringHour = dateFomatter.firebaseDate(from: closingHour)
                                    let hour = dateFomatter.changeDateString(transition: "HH:mm a", from: stringHour)
                                    previewTextClosingHour = hour
                                    
                                    isShowingClosingHourDatePicker.toggle()
                                } label: {
                                    Text("선택 완료")
                                        .frame(width: 330, height: 30)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                            }
                            .presentationDetents([.fraction(0.4)])
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("휴무일")
                            TextField("요일", text: $closedDay)
                                .signInTextFieldStyle(isTextFieldValid: $isNotEmptyDescription)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("시/군/구")
                            TextField("시/군/구", text: $shop.headAddress)
                                .textFieldModifier()
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("도로명")
                            TextField("도로명", text: $shop.subAddress)
                                .textFieldModifier()
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("상세주소")
                            TextField("상세주소 ", text: $shop.detailAddress)
                                .textFieldModifier()
                        }
                          
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .onDisappear(perform: {
                    setCordinate()
                    convertDateString()
                })
                .onAppear(perform: {
                    let firebaseDateFormat = dateFomatter.firebaseDateFormat()
                    
                    closedDay = shop.closedDays.first ?? ""
                    openingHour = firebaseDateFormat.date(from: shop.openingHour) ?? initOpeningDate
                    closingHour = firebaseDateFormat.date(from: shop.closingHour) ?? initClosingDate
                })
                .onTapGesture(perform: {
                    hideKeyboard()
                })
                .toolbar(content: {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button(role: .cancel, action: {
                            convertDateString()
                        }, label: {
                            Text("닫기")
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                        })
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(role: .destructive, action: {
                            convertDateString()
                        }, label: {
                           Text("완료")
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                        })
                    }
                })
            }
        }
    }
    
    private func setCordinate() {
        if !shop.headAddress.isEmpty && !shop.subAddress.isEmpty {
            let address = shop.headAddress + shop.subAddress
            let _: () = locationManager.getCoordinate(addressString: address) { coordinate, error in
                guard error == nil else { return }
                
                shop.latitude = coordinate.latitude
                shop.longitude = coordinate.longitude
            }
        }
    }
    
    private var requiredFieldMark: some View {
        Text("*")
            .foregroundStyle(Color.subColor)
    }
    
    private func convertDateString() {
        let fomatter = FirebaseDateFormatManager.sharedDateFormmatter
        
        shop.openingHour = fomatter.firebaseDate(from: openingHour)
        shop.closingHour = fomatter.firebaseDate(from: closingHour)
        shop.closedDays = [closedDay]
        
        isShowDesignerShopEditView = false
    }
}

#Preview {
    NavigationStack {
        DMShopEditView(
            shop: .constant(.init(
                shopName: "",
                headAddress: "",
                subAddress: "",
                detailAddress: "",
                openingHour: "",
                closingHour: "",
                closedDays: [])),
            rank: .constant(Rank.Owner),
            isShowDesignerShopEditView: .constant(false)
        )
        .environmentObject(LocationManager())
    }
}
