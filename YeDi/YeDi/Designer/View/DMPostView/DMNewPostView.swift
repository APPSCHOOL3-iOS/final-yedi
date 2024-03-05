//
//  NewPostView.swift
//  YeDi
//
//  Created by 박찬호 on 2023/09/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

// 메인 게시물 생성 뷰
struct DMNewPostView: View {
    // MARK: - Properties
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var postViewModel: DMPostViewModel

    @StateObject private var profileViewModel: DMProfileViewModel = DMProfileViewModel()
    
    @State private var title = ""
    @State private var description = ""
    @State private var imageUrls: [String] = []
    @State private var hairCategory: HairCategory = .Else
    @State private var price: String = ""
    
    @State private var isShowingAlert = false
    @State private var isShowingPhotoPicker: Bool = false

    let hairCategoryArray: [HairCategory] = [
        HairCategory.Cut,
        HairCategory.Dying,
        HairCategory.Perm,
        HairCategory.Else
    ]
    
    private var isFormValid: Bool {
        return !title.isEmpty && !description.isEmpty && !imageUrls.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            contentForm
            
            Spacer()
            
            VStack {
                // MARK: - 게시물 생성 버튼
                Button {
                    createPost()
                } label: {
                    Text("확인")
                }
                .buttonModifier(.main)
                .padding([.leading, .trailing, .bottom])
            }
        }
        .navigationTitle("새 게시물")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
            self.title = ""
            self.description = ""
            self.imageUrls = []
            self.hairCategory = .Else
            self.price = ""
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("생성 완료"),
                message: Text("게시물이 생성되었습니다."),
                dismissButton: .default(Text("확인")) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                DismissButton(color: nil, action: {})
            }
        }
    }
    
    // MARK: - Custom Views
    /// 컨텐츠 폼
    private var contentForm: some View {
        VStack(alignment: .leading) {
            // MARK: - 시술 사진 수정 섹션
            PhotoSelectionView(selectedPhotoURLs: $imageUrls, isShowingPhotoPicker: $isShowingPhotoPicker)
                .sheet(isPresented: $isShowingPhotoPicker) {
                    PhotoPicker { imageURL in
                        imageUrls.append(imageURL.absoluteString)
                    }
                }
            
            Group {
                // MARK: - 카테고리 섹션
                categoryPickerView
                
                // MARK: - 시술명 섹션
                Text("제목")
                    .fontWeight(.semibold)
                TextField("시술명", text: $title)
                    .textFieldModifier()
                    .padding(.bottom)
                
                // MARK: - 내용 섹션
                Text("내용")
                    .fontWeight(.semibold)
                TextField("내용", text: $description, axis: .vertical)
                    .textAreaModifier(200)
                    .padding(.bottom)
                
                Text("가격")
                    .fontWeight(.semibold)
                TextField("가격", text: $price)
                    .textFieldModifier()
                    .keyboardType(.numberPad)
            }
            .padding([.leading, .trailing], 20)
        }
    }
    
    /// 게시물 생성 버튼
    private var postButton: some View {
        VStack {
            Spacer()
            Button("게시물 생성") {
                createPost()
            }
            .buttonModifier(.mainColor)
            .cornerRadius(10)
            .padding([.horizontal, .bottom])
            .disabled(!isFormValid)
        }
    }
    
    /// 시술 카테고리 피커 뷰
    private var categoryPickerView: some View {
        HStack {
            Text("시술 카테고리")
                .fontWeight(.semibold)
            Spacer()
            Picker("", selection: $hairCategory) {
                ForEach(hairCategoryArray, id: \.self) { style in
                    Text("\(style.rawValue)")
                }
            }
            .tint(.main)
        }
    }
    
    // MARK: - Helper Functions
    /// 게시물 생성 함수
    private func createPost() {
        let photos = imageUrls.map { Photo(id: UUID().uuidString, imageURL: $0) }
        let newPost = Post(
            id: UUID().uuidString,
            designerID: userAuth.currentDesignerID ?? "Unknown",
            location: profileViewModel.shop.headAddress,
            title: title,
            description: description,
            photos: photos,
            comments: 0,
            timestamp: FirebaseDateFormatManager.sharedDateFormmatter.firebaseDate(from: Date()),
            hairCategory: hairCategory,
            price: Int(price) ?? 0
        )
        
        Task {
            await postViewModel.savePostToFirestore(post: newPost, imageURLs: imageUrls)
        }
        isShowingAlert = true
    }
}

// MARK: - InputField
/// 입력 필드를 표현하는 SwiftUI 뷰
struct InputField: View {
    // MARK: - Properties
    var title: String
    @Binding var text: String
    var placeholder: String
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            HStack {
                Text(displayText)
                    .foregroundStyle(isPlaceholderText ? .gray : .black)
                Spacer()
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helpers
    /// 텍스트가 비어 있거나 플레이스홀더와 동일한지 확인
    private var isPlaceholderText: Bool {
        return text.isEmpty || text == placeholder
    }
    
    /// 표시할 텍스트 결정
    private var displayText: String {
        if text.isEmpty || text == placeholder {
            return placeholder
        } else {
            return text
        }
    }
}

// MARK: - TextEditorView
/// 텍스트 편집기 뷰
struct TextEditorView: View {
    enum Field {
        case editor
    }
    
    // MARK: - Properties
    var editingField: String
    @Binding var text: String
    var placeholder: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @FocusState private var focusedField: Field?
    @State private var showPlaceholder: Bool = true
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($focusedField, equals: .editor)
                .onChange(of: text) { newValue in
                    showPlaceholder = newValue.isEmpty
                }
                .onAppear {
                    // 키보드를 가능한 빨리 표시
                    DispatchQueue.main.async {
                        focusedField = .editor
                        showPlaceholder = text.isEmpty
                    }
                }
                .onTapGesture {
                    if showPlaceholder {
                        text = ""
                        showPlaceholder = false
                    }
                }
                .padding()
                .navigationTitle(editingField)
                .navigationBarBackButtonHidden(true)  // 뒤로 가기 버튼 숨기기
            
            // 플레이스홀더 표시
            if showPlaceholder {
                Text(placeholder)
                    .foregroundStyle(.gray)
                    .padding(.top, 25)
                    .padding(.leading, 23)
                    .onTapGesture {
                        text = ""
                        showPlaceholder = false
                        focusedField = .editor
                    }
            }
            
            // 확인 버튼
            VStack {
                Spacer()
                Button("게시물 생성") {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    DMNewPostView()
        .environmentObject(DMPostViewModel())
}
