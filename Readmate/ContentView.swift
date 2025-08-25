//
//  ContentView.swift
//  Readmate
//
//  Created by Abhiraj Vengadesh on 8/18/25.
//

import SwiftUI

struct ContentView: View {
    init() {
        // Set the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appBackground)
        
        // Set the text color for normal and selected states
        let normalColor = UIColor(Color.accentPurple.opacity(0.6))
        let selectedColor = UIColor(Color.accentPurple)
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: normalColor]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }

            ScannerView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Scanner")
                }

            AIAssistantView()
                .tabItem {
                    Image(systemName: "message")
                    Text("AI Assistant")
                }
        }
        .accentColor(.accentPurple)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LibraryViewModel(forPreview: true))
    }
}
