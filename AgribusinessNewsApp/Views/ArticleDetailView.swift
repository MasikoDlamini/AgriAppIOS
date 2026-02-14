//
//  ArticleDetailView.swift
//  AgribusinessNewsApp
//
//  Created on 14 February 2026.
//

import SwiftUI

struct ArticleDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var isShowingShare = false
    
    let article: NewsArticleModel
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Featured Image
                    if let imageURL = article.image, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 250)
                                    .overlay(ProgressView())
                                    .cornerRadius(12)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(height: 250)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white)
                                    )
                                    .cornerRadius(12)
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
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                            .cornerRadius(12)
                    }
                    
                    // Article Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Label(article.category, systemImage: "tag")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Label(article.date, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                    
                    // Article Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text(article.excerpt)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ArticleContentView(content: article.content)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(16)
            }
            
            // Header with Back Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            bookmarkManager.toggleBookmark(article)
                        }) {
                            Image(systemName: bookmarkManager.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: {
                            isShowingShare = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowingShare) {
            ShareSheet(url: URL(string: article.link), title: article.title)
        }
    }
    
    private func shareArticle() {
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

// MARK: - Share Sheet View
struct ShareSheet: View {
    let url: URL?
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        if let url = url {
            ActivityViewController(activityItems: [title, url])
        } else {
            VStack {
                Text("Unable to share")
                    .font(.headline)
                Button("Dismiss") {
                    dismiss()
                }
                .padding()
            }
        }
    }
}

// MARK: - Activity View Controller Wrapper
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Article Content View
struct ArticleContentView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseContent(content), id: \.self) { paragraph in
                if paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                } else {
                    Text(paragraph)
                        .lineSpacing(2)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func parseContent(_ html: String) -> [String] {
        let paragraphs = html.components(separatedBy: "</p>")
        return paragraphs.map { para in
            para.replacingOccurrences(of: "<p>", with: "")
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "<br/>", with: "\n")
                .replacingOccurrences(of: "<strong>", with: "")
                .replacingOccurrences(of: "</strong>", with: "")
                .replacingOccurrences(of: "<em>", with: "")
                .replacingOccurrences(of: "</em>", with: "")
                .replacingOccurrences(of: "[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&#8211;", with: "–")
                .replacingOccurrences(of: "&#8217;", with: "'")
                .replacingOccurrences(of: "&#8220;", with: "\"")
                .replacingOccurrences(of: "&#8221;", with: "\"")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: NewsArticleModel(
            id: 1,
            title: "Sample Article Title",
            link: "https://example.com",
            excerpt: "This is a sample excerpt of the article that gives a brief overview of the content.",
            image: nil,
            category: "Agriculture",
            date: "2h ago",
            timestamp: "2026-02-14T10:00:00Z",
            content: "This is the full article content. It contains multiple paragraphs discussing important topics in agriculture. The content is properly formatted for reading within the app instead of redirecting to the web."
        ))
    }
}
