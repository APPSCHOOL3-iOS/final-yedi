//
//  YeDiApp.swift
//  YeDi
//
//  Created by 이승준 on 2023/09/22.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct YeDiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userAuth = UserAuth()
    @StateObject var consultationViewModel = ConsultationViewModel()
    @StateObject var cmProfileViewModel: CMProfileViewModel = CMProfileViewModel()
    @StateObject var reviewViewModel: CMReviewViewModel = CMReviewViewModel()
    @StateObject var dmPostViewModel: DMPostViewModel = DMPostViewModel()
    @StateObject var chattingListViewModel = ChattingListRoomViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userAuth)
                .environmentObject(consultationViewModel)
                .environmentObject(cmProfileViewModel)
                .environmentObject(reviewViewModel)
                .environmentObject(dmPostViewModel)
                .environmentObject(chattingListViewModel)
        }
    }
}
