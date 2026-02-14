//
//  NewsService.swift
//  AgribusinessNewsApp
//
//  Created on 30 November 2025.
//

import Foundation

class NewsService: ObservableObject {
    @Published var articles: [NewsArticleModel] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Direct WordPress API - No backend server needed!
    private let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/posts"
    
    func fetchNews() async throws -> [NewsArticleModel] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let url = URL(string: "\(baseURL)?per_page=20&_embed=true") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            throw URLError(.badURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([WordPressPost].self, from: data)
            
            // Transform WordPress posts to our article model
            let transformedArticles = posts.map { post -> NewsArticleModel in
                // Extract featured image
                var imageURL: String? = nil
                if let embedded = post._embedded,
                   let media = embedded.wpFeaturedmedia?.first {
                    imageURL = media.source_url
                }
                
                // Extract category
                var category = "News"
                if let embedded = post._embedded,
                   let terms = embedded.wpTerm?.first?.first {
                    category = terms.name ?? "News"
                }
                
                // Format date
                let dateString = formatDate(post.date)
                
                return NewsArticleModel(
                    id: post.id,
                    title: cleanHTML(post.title.rendered),
                    link: post.link,
                    excerpt: cleanHTML(post.excerpt.rendered).prefix(150).trimmingCharacters(in: .whitespacesAndNewlines) + "",
                    image: imageURL,
                    category: category,
                    date: dateString,
                    timestamp: post.date,
                    content: cleanHTML(post.content.rendered)
                )
            }
            
            await MainActor.run {
                self.articles = transformedArticles
                self.isLoading = false
            }
            
            return transformedArticles
        } catch {
            await MainActor.run {
                self.error = "Failed to load news: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func cleanHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&#8220;", with: "\"")
            .replacingOccurrences(of: "&#8221;", with: "\"")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Recent" }
        
        let now = Date()
        let hours = Int(now.timeIntervalSince(date) / 3600)
        
        if hours < 1 {
            return "Just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if hours < 48 {
            return "Yesterday"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }
}

// WordPress API models
struct WordPressPost: Codable {
    let id: Int
    let date: String
    let link: String
    let title: WordPressTitle
    let excerpt: WordPressExcerpt
    let content: WordPressContent
    let _embedded: WordPressEmbedded?
    
    enum CodingKeys: String, CodingKey {
        case id, date, link, title, excerpt, content, _embedded
    }
}

struct WordPressTitle: Codable {
    let rendered: String
}

struct WordPressExcerpt: Codable {
    let rendered: String
}

struct WordPressContent: Codable {
    let rendered: String
}

struct WordPressEmbedded: Codable {
    let wpFeaturedmedia: [WordPressMedia]?
    let wpTerm: [[WordPressTerm]]?
    
    enum CodingKeys: String, CodingKey {
        case wpFeaturedmedia = "wp:featuredmedia"
        case wpTerm = "wp:term"
    }
}

struct WordPressMedia: Codable {
    let source_url: String?
}

struct WordPressTerm: Codable {
    let name: String?
}
