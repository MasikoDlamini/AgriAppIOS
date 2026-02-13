//
//  HomeView.swift
//  AgribusinessNewsApp
//
//  Created on 30 November 2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var webViewModel: WebViewModel
    @Binding var selectedTab: Int
    @State private var showWebView = false
    @State private var selectedURL = ""
    @StateObject private var newsService = NewsService()
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var latestNews: [NewsArticleModel] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Logo
                HeaderView()
                
                // Featured Article
                FeaturedArticleView(onTap: {
                    selectedURL = "https://agribusinessmedia.com"
                    showWebView = true
                })
                
                // Quick Categories
                CategoriesGridView(
                    onCategoryTap: { category in
                        switch category {
                        case "News":
                            selectedTab = 1
                        case "Magazines":
                            selectedTab = 2
                        case "Videos":
                            selectedURL = "https://agribusinessmedia.com/agri-tv"
                            showWebView = true
                        default:
                            selectedURL = "https://agribusinessmedia.com"
                            showWebView = true
                        }
                    }
                )
                
                // Latest News Section
                LatestNewsSection(
                    articles: latestNews,
                    onArticleTap: { url in
                        if let articleURL = URL(string: url) {
                            UIApplication.shared.open(articleURL)
                        }
                    },
                    onViewAllTap: {
                        selectedTab = 1
                    }
                )
                
                Spacer(minLength: 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await loadLatestNews()
        }
        .fullScreenCover(isPresented: $showWebView) {
            WebViewModal(url: selectedURL, isPresented: $showWebView, webViewModel: webViewModel)
        }
    }
    
    private func loadLatestNews() async {
        if let allNews = try? await newsService.fetchNews() {
            latestNews = Array(allNews.prefix(2))
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("AgribusinessLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            
            Divider()
        }
    }
}

// MARK: - Featured Article
struct FeaturedArticleView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background image with overlay
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=800&q=80")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.7)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    case .failure(_):
                        // Fallback gradient
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                    case .empty:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("FEATURED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(4)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Explore Today's Top Agricultural Stories")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                    
                    Text("Stay informed with the latest in agribusiness")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .padding(20)
            }
        }
        .frame(height: 200)
        .cornerRadius(0)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Categories Grid
struct CategoriesGridView: View {
    let onCategoryTap: (String) -> Void
    
    let categories = [
        CategoryItem(icon: "newspaper.fill", title: "News", color: .blue),
        CategoryItem(icon: "book.fill", title: "Magazines", color: .orange),
        CategoryItem(icon: "video.fill", title: "Videos", color: .red),
        CategoryItem(icon: "chart.line.uptrend.xyaxis", title: "Markets", color: .green)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categories) { category in
                    Button(action: {
                        onCategoryTap(category.title)
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.system(size: 32))
                                .foregroundColor(category.color)
                            Text(category.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Latest News Section
struct LatestNewsSection: View {
    let articles: [NewsArticleModel]
    let onArticleTap: (String) -> Void
    let onViewAllTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest News")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Stay updated with recent stories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onViewAllTap) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // News Articles
            if articles.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(articles) { article in
                        Button(action: {
                            onArticleTap(article.link)
                        }) {
                            HStack(spacing: 12) {
                                // Thumbnail
                                if let imageURL = article.image {
                                    AsyncImage(url: URL(string: imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        case .failure(_), .empty:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(LinearGradient(
                                                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.6)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Image(systemName: "newspaper.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.6)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "newspaper.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                // Content
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(article.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack {
                                        Text(article.category)
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(article.date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Web View Modal
struct WebViewModal: View {
    let url: String
    @Binding var isPresented: Bool
    @ObservedObject var webViewModel: WebViewModel
    
    init(url: String, isPresented: Binding<Bool>, webViewModel: WebViewModel) {
        self.url = url
        self._isPresented = isPresented
        self.webViewModel = webViewModel
        // Set URL immediately during initialization
        webViewModel.urlString = url
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                RefreshableWebView(viewModel: webViewModel)
                    .ignoresSafeArea(.all, edges: .bottom)
                
                if webViewModel.isLoading {
                    VStack {
                        ProgressView("Loading article...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        webViewModel.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                    .disabled(!webViewModel.canGoBack)
                }
            }
        }
    }
}

#Preview {
    HomeView(webViewModel: WebViewModel(), selectedTab: .constant(0))
}
