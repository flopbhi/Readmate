//
//  ReadmateApp.swift
//  Readmate
//
//  Created by Abhiraj Vengadesh on 8/18/25.
//

import SwiftUI

@main
struct ReadmateApp: App {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var aiViewModel = AIAssistantViewModel()

    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                WelcomeView(isFirstLaunch: $isFirstLaunch)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            } else {
                ContentView()
                    .environmentObject(libraryViewModel)
                    .environmentObject(aiViewModel)
            }
        }
    }
}
