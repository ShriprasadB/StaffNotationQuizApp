//
//  StaffNotationQuizAppApp.swift
//  StaffNotationQuizApp
//
//  Created by Shri on 6/27/26.
//

import SwiftUI
import FirebaseCore

@main
struct StaffNotationQuizAppApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
