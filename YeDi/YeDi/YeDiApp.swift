//
//  YeDiApp.swift
//  YeDi
//
//  Created by 이승준 on 2023/09/22.
//

import SwiftUI
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
    @StateObject var profileViewModel: CMProfileViewModel = CMProfileViewModel()
    @StateObject var reviewViewModel: CMReviewViewModel = CMReviewViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userAuth)
                .environmentObject(profileViewModel)
                .environmentObject(reviewViewModel)
        }
    }
}