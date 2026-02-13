//
//  ContentView.swift
//  AgribusinessNewsApp
//
//  Created on 29 November 2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var tabViewModel = TabViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView(
                    webViewModel: tabViewModel.homeWebViewModel,
                    selectedTab: $selectedTab
                )
                .navigationBarHidden(true)
            }
            .tabItem {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            }
            .tag(0)
            
            NavigationView {
                NewsPageView(webViewModel: tabViewModel.newsWebViewModel)
                    .navigationBarHidden(true)
            }
            .tabItem {
                VStack {
                    Image(systemName: "newspaper.fill")
                    Text("News")
                }
            }
            .tag(1)
            
            MagazinesView()
            .tabItem {
                VStack {
                    Image(systemName: "book.fill")
                    Text("Magazines")
                }
            }
            .tag(2)
            
            BookmarksView()
            .tabItem {
                VStack {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
            }
            .tag(3)
        }
        .accentColor(.green)
    }
}

struct WebTabView: View {
    @ObservedObject var webViewModel: WebViewModel
    let title: String
    
    var body: some View {
        NavigationView {
            ZStack {
                RefreshableWebView(viewModel: webViewModel)
                    .edgesIgnoringSafeArea(.bottom)
                
                if webViewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        webViewModel.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!webViewModel.canGoBack)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
