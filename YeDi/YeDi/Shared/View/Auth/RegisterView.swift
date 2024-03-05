//
//  RegisterView.swift
//  YeDi
//
//  Created by yunjikim on 2023/10/06.
//

import SwiftUI
    
struct RegisterView: View {
    var userType: UserType
    
    @EnvironmentObject private var userAuth: UserAuth
    @Environment(\.dismiss) private var dismiss
    
    private let authRegex = AuthRegex.shared
    private let instance = FirebaseDateFormatManager.sharedDateFormmatter
    
    /// 고객, 디자이너 공통 프로퍼티
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var profileImageURLString: String = ""
    @State private var password: String = ""
    @State private var doubleCheckPassword: String = ""
    /// 고객 프로퍼티 (연산프로퍼티 birthDate 포함)
    @State private var selectedGender: String = "여성"
    
    /// 디자이너 프로퍼티
    @State private var description: String = ""
    @State private var rank: Rank = .Owner
    @State private var shop: Shop = .init(shopName: "", headAddress: "", subAddress: "", detailAddress: "", openingHour: "", closingHour: "", closedDays: [])
    @State private var isShowDesignerShopEditView: Bool = false
    
    /// caution 프로퍼티
    @State private var cautionEmail: String = ""
    @State private var cautionPassword: String = ""
    @State private var cautionDoubleCheckPassword: String = ""
    @State private var cautionName: String = ""
    @State private var cautionPhoneNumber: String = ""
    @State private var cautionBirth: String = ""
    /// valid 프로퍼티
    @State private var isEmailValid: Bool = true
    @State private var isPasswordValid: Bool = true
    @State private var isDoubleCheckPasswordValid: Bool = true
    @State private var isPhoneNumberValid: Bool = true
    @State private var isBirthValid: Bool = true
    /// empty 프로퍼티
    @State private var isNotEmptyName: Bool = true
    @State private var isNotEmptyDescription: Bool = true
    /// birth 프로퍼티
    @State private var changedBirthText: String = "생년월일"
    @State private var selectedBirthDate = Date()
    @State private var birthDate: String = ""
    @State private var isShowingDatePicker: Bool = false
    
    @State private var isShowingPassword: Bool = false
    @State private var isShowingDoubleCheckPassword: Bool = false
    
    private let genders: [String] = ["여성", "남성"]
    private let ranks: [Rank] = [.Owner, .Principal, .Designer, .Intern]
    
    var body: some View {
        VStack {
            switch userType {
            case .client:
                registerForClient
            case .designer:
                registerForDesigner
            }
        }
    }
    
    private var registerForClient: some View {
        VStack(alignment: .leading) {
            ScrollView {
                inputUserInfo
            }
            .onTapGesture {
                hideKeyboard()
            }
            
            registerButton
        }
        .navigationTitle("고객 회원가입")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(color: nil) { }
            }
        }
    }
    
    private var registerForDesigner: some View {
        VStack(alignment: .leading) {
            ScrollView {
                inputUserInfo
                inputDesignerDescription
                inputShopInfo
            }
            .onTapGesture {
                hideKeyboard()
            }
            
            registerButton
        }
        .navigationTitle("디자이너 회원가입")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(color: nil) { }
            }
        }
    }
    
    private var inputUserInfo: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("이메일")
                    requiredFieldMark
                }
                
                TextField("이메일", text: $email)
                    .keyboardType(.emailAddress)
                    .signInTextFieldStyle(isTextFieldValid: $isEmailValid)
                    .onChange(of: email) { newValue in
                        if !checkEmail() {
                            email = newValue.trimmingCharacters(in: .whitespaces)
                        }
                    }
                
                if isEmailValid {
                    Text(cautionEmail)
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    Text(cautionEmail)
                        .cautionTextStyle()
                }
            }
            .padding(.top)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("패스워드")
                    requiredFieldMark
                }
                
                HStack {
                    if isShowingPassword {
                        TextField("패스워드", text: $password)
                    } else {
                        SecureField("패스워드", text: $password)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingPassword.toggle()
                    }, label: {
                        Image(systemName: isShowingPassword ? "eye.fill" : "eye.slash.fill")
                    })
                }
                .signInTextFieldStyle(isTextFieldValid: $isPasswordValid)
                .onChange(of: password) { newValue in
                    password = newValue.trimmingCharacters(in: .whitespaces)
                }
                
                Text(cautionPassword)
                    .cautionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("패스워드 체크")
                    requiredFieldMark
                }
                
                HStack {
                    if isShowingDoubleCheckPassword {
                        TextField("패스워드", text: $doubleCheckPassword)
                    } else {
                        SecureField("패스워드", text: $doubleCheckPassword)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingDoubleCheckPassword.toggle()
                    }, label: {
                        Image(systemName: isShowingDoubleCheckPassword ? "eye.fill" : "eye.slash.fill")
                    })
                }
                .signInTextFieldStyle(isTextFieldValid: $isDoubleCheckPasswordValid)
                .onChange(of: doubleCheckPassword) { newValue in
                    if !doubleCheckPasswordValid() {
                        doubleCheckPassword = newValue.trimmingCharacters(in: .whitespaces)
                    }
                }
                
                Text(cautionDoubleCheckPassword)
                    .cautionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("이름")
                    requiredFieldMark
                }
                TextField("이름", text: $name)
                    .signInTextFieldStyle(isTextFieldValid: $isNotEmptyName)
                    .onChange(of: name) { newValue in
                        if !checkEmptyName() {
                            name = newValue.trimmingCharacters(in: .whitespaces)
                        }
                            
                    }
                
                Text(cautionName)
                    .cautionTextStyle()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("휴대폰 번호")
                    requiredFieldMark
                }
                TextField("휴대폰 번호", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .signInTextFieldStyle(isTextFieldValid: $isPhoneNumberValid)
                    .onChange(of: phoneNumber) { newValue in
                        if !checkPhoneNumber() {
                            phoneNumber = newValue.trimmingCharacters(in: .whitespaces)
                        }
                    }
                
                Text(cautionPhoneNumber)
                    .cautionTextStyle()
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("생년월일")
                    requiredFieldMark
                }
                HStack {
                    Text(changedBirthText)
                        .foregroundStyle(changedBirthText=="생년월일" ? Color.placeholderText : Color.primaryLabel)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingDatePicker.toggle()
                    }, label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.primaryLabel)
                    })
                }
                .signInTextFieldStyle(isTextFieldValid: $isBirthValid)
                
                Text(cautionBirth)
                    .cautionTextStyle()
            }
            .sheet(isPresented: $isShowingDatePicker, content: {
                VStack {
                    DatePicker("생년월일", selection: $selectedBirthDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()

                    Button(action: {
                        let date = instance.firebaseDate(from: selectedBirthDate)
                        birthDate = instance.changeDateString(transition: "yyyy년 MM월 dd일", from: date)

                        changedBirthText = birthDate

                        isShowingDatePicker.toggle()
                    }, label: {
                        Text("선택 완료")
                            .frame(width: 330, height: 30)
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                }
                .presentationDetents([.fraction(0.4)])
            })
            
            HStack(alignment: .center) {
                HStack {
                    Text("성별")
                    requiredFieldMark
                }
                HStack(spacing: 0) {
                    ForEach(genders, id: \.self) { gender in
                        Button(action: {
                            selectedGender = gender
                        }, label: {
                            Text(gender)
                                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                                .foregroundStyle(Color.primaryLabel)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(selectedGender == gender ? Color.gray4 : Color.gray6)
                                )
                        })
                        .background {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray6)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
    
    private var inputDesignerDescription: some View {
        VStack(alignment: .leading) {
            Text("소개글")
            
            TextField("디자이너 소개글", text: $description, axis: .vertical)
                .signInTextFieldStyle(isTextFieldValid: $isNotEmptyDescription)
        }
        .padding(.horizontal)
    }
    
    private var inputShopInfo: some View {
        VStack {
            Divider()
                .foregroundStyle(Color.separator)
                .padding(.vertical)
            
            Button {
                isShowDesignerShopEditView = true
            } label: {
                Text("샵정보 입력")
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.white)
                    .background {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pointColor)
                    }
            }
        }
        .padding([.horizontal, .bottom])
        .sheet(isPresented: $isShowDesignerShopEditView) {
            DMShopEditView(shop: $shop,
                           rank: $rank,
                           isShowDesignerShopEditView: $isShowDesignerShopEditView)
        }
    }
    
    private var registerButton: some View {
        VStack {
            Button {
                pressedButtonRegister(userType)
            } label: {
                Text("회원가입")
                    .buttonModifier(.mainColor)
            }
        }
        .padding([.horizontal, .bottom])
    }
    
    private var requiredFieldMark: some View {
        Text("*")
            .foregroundStyle(Color.subColor)
    }
    
    private func pressedButtonRegister(_ userType: UserType) {
        switch userType {
        case .client:
            if checkEmail() && checkPassword() && doubleCheckPasswordValid() && checkEmptyName() && checkPhoneNumber() && checkBirth() {
                let client = Client(
                    id: UUID().uuidString,
                    name: name,
                    email: email,
                    profileImageURLString: "",
                    phoneNumber: phoneNumber,
                    gender: selectedGender,
                    birthDate: birthDate,
                    favoriteStyle: "",
                    chatRooms: []
                )
                userAuth.registerClient(client: client, password: password) { success in
                    if success {
                        dismiss()
                    } else {
                        cautionEmail = "이미 존재하는 이메일입니다."
                        isEmailValid = false
                    }
                }
            }
        case .designer:
            if checkEmail() && checkPassword() && doubleCheckPasswordValid() && checkEmptyName() && checkPhoneNumber() {
                let designer = Designer(
                    id: nil,
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    description: description,
                    designerScore: 0,
                    reviewCount: 0,
                    followerCount: 0,
                    skill: [],
                    chatRooms: [],
                    birthDate: birthDate,
                    gender: selectedGender,
                    rank: rank,
                    designerUID: ""
                )
                
                userAuth.registerDesigner(designer: designer, shop: shop, password: password) { success in
                    if success {
                        dismiss()
                    } else {
                        cautionEmail = "이미 존재하는 이메일입니다."
                        isEmailValid = false
                    }
                }
            }
        }
    }
    
    private func checkEmail() -> Bool {
        if authRegex.checkEmailValid(email) {
            cautionEmail = ""
            isEmailValid = true
        } else if !authRegex.checkEmailValid(email) {
            cautionEmail = "올바르지 않은 이메일 주소입니다"
            isEmailValid = false
        }
        return isEmailValid
    }
    
    private func checkPassword() -> Bool {
        if authRegex.checkPasswordValid(password) {
            cautionPassword = ""
            isPasswordValid = true
        } else {
            cautionPassword = "알파벳, 숫자를 이용하여 6자 이상의 비밀번호를 입력해주세요."
            isPasswordValid = false
        }
        return isPasswordValid
    }
    
    private func doubleCheckPasswordValid() -> Bool {
        if password == doubleCheckPassword {
            cautionDoubleCheckPassword = ""
            isDoubleCheckPasswordValid = true
        } else {
            cautionDoubleCheckPassword = "패스워드가 일치하지 않습니다."
            isDoubleCheckPasswordValid = false
        }
        return isDoubleCheckPasswordValid
    }
    
    private func checkEmptyName() -> Bool {
        if !name.isEmpty {
            cautionName = ""
            isNotEmptyName = true
        } else {
            cautionName = "필수 입력사항입니다."
            isNotEmptyName = false
        }
        return isNotEmptyName
    }
    
    private func checkPhoneNumber() -> Bool {
        if authRegex.checkPhoneNumberValid(phoneNumber) {
            cautionPhoneNumber = ""
            isPhoneNumberValid = true
        } else {
            cautionPhoneNumber = "올바르지 않은 휴대폰 번호입니다"
            isPhoneNumberValid = false
        }
        return isPhoneNumberValid
    }
    
    private func checkBirth() -> Bool {
        if selectedBirthDate > Date() {
            cautionBirth = "올바르지 않은 생년월일입니다"
            isBirthValid = false
        } else {
            cautionBirth = ""
            isBirthValid = true
        }
        return isBirthValid
    }
}
