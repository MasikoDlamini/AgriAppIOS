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
    @StateObject private var videoService = VideoService()
    @StateObject private var magazineService = MagazineService()
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var latestNews: [NewsArticleModel] = []
    @State private var latestVideos: [Video] = []
    @State private var latestMagazine: Magazine?
    @State private var selectedArticle: NewsArticleModel?
    @State private var selectedVideo: Video?
    @State private var showMagazine = false
    @State private var isLoading = true
    @State private var showMenu = false
    @State private var selectedCategory: ArticleCategory?
    @State private var categoryArticles: [NewsArticleModel] = []
    @State private var isCategoryLoading = false
    
    var featuredArticles: [NewsArticleModel] {
        Array(latestNews.prefix(5))
    }
    
    var remainingArticles: [NewsArticleModel] {
        Array(latestNews.dropFirst(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with hamburger menu
                        HeaderView(onMenuTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenu = true
                            }
                        })
                        
                        // Category filter banner
                        if let category = selectedCategory {
                            CategoryFilterBanner(
                                category: category,
                                onClear: {
                                    selectedCategory = nil
                                    categoryArticles = []
                                }
                            )
                        }
                        
                        if selectedCategory != nil {
                            // Show category-filtered content
                            CategoryContentView(
                                articles: categoryArticles,
                                isLoading: isCategoryLoading,
                                onArticleTap: { article in
                                    selectedArticle = article
                                }
                            )
                        } else if isLoading {
                        // Show skeleton loader while loading
                        HomeLoadingSkeleton()
                    } else {
                        // Featured Slideshow
                        if !featuredArticles.isEmpty {
                            FeaturedArticleSlideshow(
                                articles: featuredArticles,
                                onArticleTap: { article in
                                    selectedArticle = article
                                }
                            )
                        } else {
                            FeaturedArticleSlideshow(
                                articles: [],
                                onArticleTap: { _ in
                                    selectedURL = "https://agribusinessmedia.com"
                                    showWebView = true
                            }
                        )
                    }
                    
                    // Quick Categories
                    CategoriesGridView(
                        onCategoryTap: { category in
                            switch category {
                            case "News":
                                selectedTab = 1
                            case "Magazines":
                                selectedTab = 2
                            case "Videos":
                                selectedTab = 3
                            default:
                                selectedURL = "https://agribusinessmedia.com"
                                showWebView = true
                            }
                        }
                    )
                    
                    // Magazine Highlight Section
                    if let magazine = latestMagazine {
                        MagazineHighlightSection(
                            magazine: magazine,
                            onMagazineTap: {
                                showMagazine = true
                            },
                            onViewAllTap: {
                                selectedTab = 2
                            }
                        )
                    }
                    
                    // Agri-TV Preview Section
                    AgriTVPreviewSection(
                        videos: latestVideos,
                        onVideoTap: { video in
                            selectedVideo = video
                        },
                        onViewAllTap: {
                            selectedTab = 3
                        }
                    )
                    
                    // Latest News Section
                    LatestNewsSection(
                        articles: remainingArticles,
                        onArticleTap: { article in
                            selectedArticle = article
                        },
                        onViewAllTap: {
                            selectedTab = 1
                        }
                    )
                    
                    Spacer(minLength: 20)
                    } // End of else block for isLoading
                    } // End of else for selectedCategory
                }
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                if let category = selectedCategory {
                    await loadCategoryArticles(category)
                } else {
                    await refreshAllContent()
                }
            }
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .navigationDestination(item: $selectedVideo) { video in
                YouTubePlayerView(video: video)
            }
            .task {
                await loadAllContent()
            }
            
            // Side Menu Overlay
            if showMenu {
                SideMenuView(
                    isPresented: $showMenu,
                    selectedCategory: $selectedCategory,
                    onCategorySelected: { category in
                        if let cat = category {
                            Task {
                                await loadCategoryArticles(cat)
                            }
                        }
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(100)
            }
        } // End of ZStack
        .fullScreenCover(isPresented: $showWebView) {
            WebViewModal(url: selectedURL, isPresented: $showWebView, webViewModel: webViewModel)
        }
        .fullScreenCover(isPresented: $showMagazine) {
            if let magazine = latestMagazine, let url = URL(string: magazine.pdfUrl) {
                NavigationStack {
                    SafariView(url: url)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showMagazine = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func loadAllContent() async {
        isLoading = true
        async let news = newsService.fetchNews()
        async let videos = videoService.fetchVideos()
        async let magazines = magazineService.fetchMagazines()
        
        if let allNews = try? await news {
            latestNews = Array(allNews.prefix(11))
        }
        if let allVideos = try? await videos {
            latestVideos = Array(allVideos.prefix(5))
        }
        if let allMagazines = try? await magazines, let first = allMagazines.first {
            latestMagazine = first
        }
        isLoading = false
    }
    
    private func refreshAllContent() async {
        async let news = newsService.fetchNews()
        async let videos = videoService.fetchVideos()
        async let magazines = magazineService.fetchMagazines()
        
        if let allNews = try? await news {
            latestNews = Array(allNews.prefix(11))
        }
        if let allVideos = try? await videos {
            latestVideos = Array(allVideos.prefix(5))
        }
        if let allMagazines = try? await magazines, let first = allMagazines.first {
            latestMagazine = first
        }
    }
    
    private func loadCategoryArticles(_ category: ArticleCategory) async {
        isCategoryLoading = true
        if let articles = try? await newsService.fetchNewsByCategory(category.id) {
            categoryArticles = articles
        }
        isCategoryLoading = false
    }
}

// MARK: - Category Filter Banner
struct CategoryFilterBanner: View {
    let category: ArticleCategory
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.green)
            
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("(\(category.count) articles)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: onClear) {
                HStack(spacing: 4) {
                    Text("Clear")
                        .font(.subheadline)
                    Image(systemName: "xmark.circle.fill")
                }
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.1))
    }
}

// MARK: - Category Content View
struct CategoryContentView: View {
    let articles: [NewsArticleModel]
    let isLoading: Bool
    let onArticleTap: (NewsArticleModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                NewsLoadingSkeleton()
            } else if articles.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No articles found")
                        .font(.headline)
                    
                    Text("Try selecting a different category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(articles) { article in
                        Button(action: {
                            onArticleTap(article)
                        }) {
                            CategoryArticleCard(article: article)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Category Article Card
struct CategoryArticleCard: View {
    let article: NewsArticleModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageURL = article.image {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    case .empty:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 100, height: 80)
                .cornerRadius(8)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 80)
                    .overlay(
                        Image(systemName: "newspaper")
                            .foregroundColor(.green)
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
                
                Text(article.excerpt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(article.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Magazine Highlight Section
struct MagazineHighlightSection: View {
    let magazine: Magazine
    let onMagazineTap: () -> Void
    let onViewAllTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .foregroundColor(.orange)
                    Text("Latest Magazine")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: onViewAllTap) {
                    HStack(spacing: 4) {
                        Text("All Issues")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Magazine Card
            Button(action: onMagazineTap) {
                HStack(spacing: 16) {
                    // Magazine Cover
                    MagazineCoverPreview(magazine: magazine)
                        .frame(width: 120, height: 160)
                    
                    // Magazine Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(magazine.issueNumber)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                        
                        Text(magazine.monthYear)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(magazine.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        HStack {
                            Text("Read Now")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Magazine Cover Preview
struct MagazineCoverPreview: View {
    let magazine: Magazine
    
    var body: some View {
        ZStack {
            // Background gradient matching MagazinesView style
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.95)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                Text("AGRIBUSINESS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                Text("MEDIA")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(magazine.issueNumber)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(magazine.monthYear)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.vertical, 12)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Header
struct HeaderView: View {
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                VStack(spacing: 0) {
                    Text("AGRIBUSINESS")
                        .font(.system(size: 22, weight: .black, design: .default))
                        .foregroundColor(.green)
                    Text("NEWS")
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .tracking(6)
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
        }
    }
}

// MARK: - Featured Article Slideshow
struct FeaturedArticleSlideshow: View {
    let articles: [NewsArticleModel]
    let onArticleTap: (NewsArticleModel) -> Void
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            if !articles.isEmpty {
                // Use TabView for synchronized image + text sliding
                TabView(selection: $currentIndex) {
                    ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                        FeaturedSlideItem(article: article)
                            .tag(index)
                            .onTapGesture {
                                onArticleTap(article)
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 200)
                
                // Pagination dots
                HStack(spacing: 8) {
                    ForEach(0..<articles.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            } else {
                // Placeholder when no articles
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
                
                HStack(spacing: 8) {
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            startAutoRotation()
        }
        .onDisappear {
            stopAutoRotation()
        }
    }
    
    private func startAutoRotation() {
        guard !articles.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % articles.count
            }
        }
    }
    
    private func stopAutoRotation() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Featured Slide Item
struct FeaturedSlideItem: View {
    let article: NewsArticleModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image with overlay
            if let imageURL = article.image {
                AsyncImage(url: URL(string: imageURL)) { phase in
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
                        FeaturedPlaceholderBackground()
                    case .empty:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                            .overlay(ProgressView())
                    @unknown default:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                    }
                }
            } else {
                FeaturedPlaceholderBackground()
            }
            
            // Content overlay
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
                
                Text(article.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                
                Text(article.excerpt)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
            }
            .padding(20)
        }
        .frame(height: 200)
    }
}

// MARK: - Featured Placeholder Background
struct FeaturedPlaceholderBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green.opacity(0.9)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 200)
    }
}

// MARK: - Categories Horizontal Scroll
struct CategoriesGridView: View {
    let onCategoryTap: (String) -> Void
    
    let categories = [
        CategoryItem(icon: "newspaper.fill", title: "News", color: .blue),
        CategoryItem(icon: "book.fill", title: "Magazines", color: .orange),
        CategoryItem(icon: "video.fill", title: "Videos", color: .red)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories) { category in
                        Button(action: {
                            onCategoryTap(category.title)
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(category.color)
                                Text(category.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 100, height: 90)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 12)
    }
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

// MARK: - Agri-TV Preview Section
struct AgriTVPreviewSection: View {
    let videos: [Video]
    let onVideoTap: (Video) -> Void
    let onViewAllTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "play.tv.fill")
                        .foregroundColor(.red)
                    Text("Agri-TV")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
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
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if videos.isEmpty {
                // Loading state with skeleton
                HorizontalVideoSkeleton()
            } else {
                // Horizontal scrolling videos
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos) { video in
                            VideoPreviewCard(video: video)
                                .onTapGesture {
                                    onVideoTap(video)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Video Preview Card
struct VideoPreviewCard: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                if let thumbnailUrl = video.youtubeThumbnailUrl,
                   let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            VideoThumbnailPlaceholder()
                        case .empty:
                            Color.gray.opacity(0.3)
                                .overlay(ProgressView())
                        @unknown default:
                            VideoThumbnailPlaceholder()
                        }
                    }
                } else {
                    VideoThumbnailPlaceholder()
                }
                
                // Play button overlay
                Circle()
                    .fill(Color.red)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .offset(x: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .frame(width: 200, height: 112)
            .cornerRadius(8)
            .clipped()
            
            // Title
            Text(video.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
        }
    }
}

// MARK: - Video Thumbnail Placeholder
struct VideoThumbnailPlaceholder: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            VStack(spacing: 4) {
                Image(systemName: "video.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("AGRI-TV")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
        }
    }
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
    let onArticleTap: (NewsArticleModel) -> Void
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
                // Loading state with skeleton
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        NewsArticleSkeletonCard()
                    }
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 12) {
                    ForEach(articles) { article in
                        Button(action: {
                            onArticleTap(article)
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
