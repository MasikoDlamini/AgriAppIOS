//
//  NewsPageView.swift
//  AgribusinessNewsApp
//
//  Created on 30 November 2025.
//

import SwiftUI

struct NewsPageView: View {
    @ObservedObject var webViewModel: WebViewModel
    @StateObject private var newsService = NewsService()
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var searchText = ""
    @State private var showingBookmarks = false
    
    var filteredArticles: [NewsArticleModel] {
        if searchText.isEmpty {
            return newsService.articles
        }
        return newsService.articles.filter { article in
            article.title.localizedCaseInsensitiveContains(searchText) ||
            article.excerpt.localizedCaseInsensitiveContains(searchText) ||
            article.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Search
                    NewsHeaderWithSearch(
                        searchText: $searchText,
                        onRefresh: {
                            Task {
                                try? await newsService.fetchNews()
                            }
                        }
                    )
                    
                    if newsService.isLoading && newsService.articles.isEmpty {
                        // Loading state
                        ProgressView("Loading news...")
                            .padding(40)
                    } else if let error = newsService.error {
                        // Error state
                        ErrorView(message: error, onRetry: {
                            Task {
                                try? await newsService.fetchNews()
                            }
                        })
                    } else if filteredArticles.isEmpty {
                        // Empty state
                        if searchText.isEmpty {
                            EmptyNewsView()
                        } else {
                            SearchEmptyView(searchText: searchText)
                        }
                    } else {
                        // News articles with bookmark & share
                        LazyVStack(spacing: 16) {
                            ForEach(filteredArticles) { article in
                                NewsArticleCardWithActions(
                                    article: article,
                                    isBookmarked: bookmarkManager.isBookmarked(article),
                                    onTap: {
                                        if let url = URL(string: article.link) {
                                            Task { @MainActor in
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    },
                                    onBookmark: {
                                        bookmarkManager.toggleBookmark(article)
                                    },
                                    onShare: {
                                        shareArticle(article)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .refreshable {
                try? await newsService.fetchNews()
            }
            
            // Loading overlay when refreshing
            if newsService.isLoading && !newsService.articles.isEmpty {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 80)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            if newsService.articles.isEmpty {
                try? await newsService.fetchNews()
            }
        }
    }
    
    private func shareArticle(_ article: NewsArticleModel) {
        guard let url = URL(string: article.link) else { return }
        let activityVC = UIActivityViewController(
            activityItems: [article.title, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Header with Search
struct NewsHeaderWithSearch: View {
    @Binding var searchText: String
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest News")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("From Agribusiness Media")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search news...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Search Empty View
struct SearchEmptyView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Results Found")
                .font(.headline)
            
            Text("No articles match '\(searchText)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - News Article Card with Actions
struct NewsArticleCardWithActions: View {
    let article: NewsArticleModel
    let isBookmarked: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                NewsArticleCardContent(article: article)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Action buttons
            HStack(spacing: 0) {
                Button(action: onBookmark) {
                    HStack {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        Text(isBookmarked ? "Saved" : "Save")
                    }
                    .font(.subheadline)
                    .foregroundColor(isBookmarked ? .green : .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .frame(height: 20)
                
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - News Article Card Content
struct NewsArticleCardContent: View {
    let article: NewsArticleModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
                // Image if available
                if let imageURL = article.image, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.5)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "newspaper")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                
                // Article content
                VStack(alignment: .leading, spacing: 12) {
                    // Category and date
                    HStack {
                        Text(article.category)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                        
                        Text(article.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    // Title
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Excerpt
                    if !article.excerpt.isEmpty {
                        Text(article.excerpt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Read more
                    HStack {
                        Text("Read more")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(16)
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Load News")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding(40)
    }
}

// MARK: - Empty View
struct EmptyNewsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No News Available")
                .font(.headline)
            
            Text("Check back later for updates")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

// MARK: - News Header
struct NewsHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest News")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Stay updated with agribusiness insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "newspaper.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Category Filter
struct CategoryFilterView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.green : Color(.systemBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Featured News
struct FeaturedNewsView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image placeholder with gradient
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 240)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("FEATURED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(4)
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Text("Agricultural Innovation Transforms Industry")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        HStack {
                            Label("Technology", systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                            Text("2 hours ago")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(20)
                }
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Latest News Grid
struct LatestNewsGridView: View {
    let onArticleTap: (String) -> Void
    
    let newsArticles = [
        NewsArticle(
            title: "Sustainable Farming Practices Gain Momentum",
            category: "Sustainability",
            time: "3h ago",
            color: .green
        ),
        NewsArticle(
            title: "Global Food Security Challenges",
            category: "Policy",
            time: "5h ago",
            color: .orange
        ),
        NewsArticle(
            title: "Market Analysis: Crop Prices Rise",
            category: "Markets",
            time: "7h ago",
            color: .purple
        ),
        NewsArticle(
            title: "AI in Agriculture: The Future is Here",
            category: "Technology",
            time: "9h ago",
            color: .blue
        ),
        NewsArticle(
            title: "Climate Impact on African Agriculture",
            category: "Environment",
            time: "12h ago",
            color: .red
        ),
        NewsArticle(
            title: "Organic Farming Expansion Worldwide",
            category: "Sustainability",
            time: "1d ago",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(newsArticles) { article in
                Button(action: {
                    onArticleTap("https://agribusinessmedia.com/news")
                }) {
                    HStack(spacing: 16) {
                        // Thumbnail with category color
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [article.color.opacity(0.6), article.color.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "newspaper")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        // Article info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(article.title)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            HStack {
                                Text(article.category)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(article.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(article.color.opacity(0.15))
                                    .cornerRadius(4)
                                
                                Text(article.time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let time: String
    let color: Color
}

// MARK: - Load More Button
struct LoadMoreButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("View All News")
                    .font(.body)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                    .font(.body)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.green)
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

#Preview {
    NewsPageView(webViewModel: WebViewModel())
}
