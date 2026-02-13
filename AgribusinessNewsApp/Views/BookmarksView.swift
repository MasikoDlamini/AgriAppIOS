//
//  BookmarksView.swift
//  AgribusinessNewsApp
//
//  Created on 1 December 2025.
//

import SwiftUI

struct BookmarksView: View {
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var showWebView = false
    @State private var selectedURL = ""
    @StateObject private var webViewModel = WebViewModel()
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if bookmarkManager.bookmarkedArticles.isEmpty {
                    EmptyBookmarksView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bookmarkManager.bookmarkedArticles) { article in
                                BookmarkArticleCard(
                                    article: article,
                                    onTap: {
                                        selectedURL = article.link
                                        showWebView = true
                                    },
                                    onRemove: {
                                        bookmarkManager.removeBookmark(article)
                                    },
                                    onShare: {
                                        shareArticle(article)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Saved Articles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !bookmarkManager.bookmarkedArticles.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Clear All Bookmarks?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    bookmarkManager.clearAllBookmarks()
                }
            } message: {
                Text("This will remove all saved articles.")
            }
            .fullScreenCover(isPresented: $showWebView) {
                WebViewModal(url: selectedURL, isPresented: $showWebView, webViewModel: webViewModel)
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

struct EmptyBookmarksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Saved Articles")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Bookmark articles to read them later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct BookmarkArticleCard: View {
    let article: NewsArticleModel
    let onTap: () -> Void
    let onRemove: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Thumbnail
                    if let imageURL = article.image {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure(_), .empty:
                                placeholderImage
                            @unknown default:
                                placeholderImage
                            }
                        }
                    } else {
                        placeholderImage
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(3)
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
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Action buttons
                HStack(spacing: 0) {
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
                    
                    Divider()
                        .frame(height: 20)
                    
                    Button(action: onRemove) {
                        HStack {
                            Image(systemName: "bookmark.slash")
                            Text("Remove")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            )
    }
}

#Preview {
    BookmarksView()
}
