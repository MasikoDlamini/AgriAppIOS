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
    @Published var hasMoreArticles = true
    
    private var currentPage = 1
    private let articlesPerPage = 50
    
    // Direct WordPress API - No backend server needed!
    private let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/posts"
    
    func fetchNews() async throws -> [NewsArticleModel] {
        // Reset pagination when fetching fresh
        currentPage = 1
        hasMoreArticles = true
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let url = URL(string: "\(baseURL)?per_page=\(articlesPerPage)&page=1&_embed=true") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([WordPressPost].self, from: data)
            
            // Check total pages from response headers
            if let httpResponse = response as? HTTPURLResponse,
               let totalPagesStr = httpResponse.value(forHTTPHeaderField: "X-WP-TotalPages"),
               let totalPages = Int(totalPagesStr) {
                await MainActor.run {
                    self.hasMoreArticles = self.currentPage < totalPages
                }
            }
            
            // Transform WordPress posts to our article model
            let transformedArticles = transformPosts(posts)
            
            await MainActor.run {
                self.articles = transformedArticles
                self.isLoading = false
                self.currentPage = 1
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
    
    func loadMoreArticles() async throws {
        guard hasMoreArticles, !isLoading else { return }
        
        let nextPage = currentPage + 1
        
        await MainActor.run {
            isLoading = true
        }
        
        guard let url = URL(string: "\(baseURL)?per_page=\(articlesPerPage)&page=\(nextPage)&_embed=true") else {
            await MainActor.run {
                isLoading = false
            }
            throw URLError(.badURL)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([WordPressPost].self, from: data)
            
            // Check total pages from response headers
            if let httpResponse = response as? HTTPURLResponse,
               let totalPagesStr = httpResponse.value(forHTTPHeaderField: "X-WP-TotalPages"),
               let totalPages = Int(totalPagesStr) {
                await MainActor.run {
                    self.hasMoreArticles = nextPage < totalPages
                }
            }
            
            let newArticles = transformPosts(posts)
            
            await MainActor.run {
                self.articles.append(contentsOf: newArticles)
                self.currentPage = nextPage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                // Don't show error for pagination failures, just stop loading more
                self.hasMoreArticles = false
            }
        }
    }
    
    private func transformPosts(_ posts: [WordPressPost]) -> [NewsArticleModel] {
        return posts.map { post -> NewsArticleModel in
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
    }
    
    func fetchNewsByCategorySlug(_ slug: String, limit: Int = 5) async throws -> [NewsArticleModel] {
        // First fetch the category ID from the slug
        guard let categoryUrl = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/categories?slug=\(slug)") else {
            throw URLError(.badURL)
        }
        
        let (categoryData, _) = try await URLSession.shared.data(from: categoryUrl)
        let categories = try JSONDecoder().decode([ArticleCategory].self, from: categoryData)
        
        guard let category = categories.first else {
            return [] // Category not found
        }
        
        // Use the standalone fetch method that doesn't update @Published properties
        return try await fetchArticlesByCategory(category.id, limit: limit)
    }
    
    // Standalone method that returns articles without updating @Published properties
    // Use this for category sections on the home page
    func fetchArticlesByCategory(_ categoryId: Int, limit: Int = 20) async throws -> [NewsArticleModel] {
        guard let url = URL(string: "\(baseURL)?per_page=\(limit)&categories=\(categoryId)&_embed=true") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let posts = try JSONDecoder().decode([WordPressPost].self, from: data)
        
        return transformPosts(posts)
    }
    
    // Method that updates @Published properties - use for the main News page
    func fetchNewsByCategory(_ categoryId: Int, limit: Int = 20) async throws -> [NewsArticleModel] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let transformedArticles = try await fetchArticlesByCategory(categoryId, limit: limit)
            
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
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
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
