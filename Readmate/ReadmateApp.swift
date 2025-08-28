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
    @StateObject private var themeManager = ThemeManager()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.currentTheme.appBackground)
        
        let selectedColor = UIColor(themeManager.currentTheme.accentPurple)
        let normalColor = UIColor.white
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: normalColor]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        UITableView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            if isFirstLaunch {
                WelcomeView(isFirstLaunch: $isFirstLaunch)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            } else {
                ContentView()
                    .environmentObject(libraryViewModel)
                    .environmentObject(aiViewModel)
                    .environmentObject(themeManager)
            }
        }
    }
}
