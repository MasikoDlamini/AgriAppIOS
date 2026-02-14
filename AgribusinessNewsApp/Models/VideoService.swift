//
//  VideoService.swift
//  AgribusinessNewsApp
//
//  Created on 14 February 2026.
//

import Foundation

class VideoService: ObservableObject {
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // WordPress REST API for custom post type agri-tv
    private let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/agri-tv"
    
    func fetchVideos() async throws -> [Video] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Fetch from WordPress custom post type with embedded data
            guard let url = URL(string: "\(baseURL)?per_page=50&orderby=date&order=desc&_embed=true") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([AgriTVPost].self, from: data)
            
            // Transform posts to videos
            let transformedVideos = posts.compactMap { post -> Video? in
                let youtubeUrl = extractYouTubeUrl(from: post)
                guard !youtubeUrl.isEmpty else { return nil }
                
                // Extract featured image
                var thumbnailUrl: String? = nil
                if let featured = post._embedded?.wpFeaturedmedia?.first {
                    thumbnailUrl = featured.source_url
                }
                
                return Video(
                    id: post.id,
                    title: cleanHTML(post.title.rendered),
                    description: cleanHTML(post.excerpt.rendered),
                    youtubeUrl: youtubeUrl,
                    thumbnailUrl: thumbnailUrl,
                    publishedDate: post.date,
                    webUrl: post.link
                )
            }
            
            await MainActor.run {
                self.videos = transformedVideos
                self.isLoading = false
            }
            
            return transformedVideos
        } catch {
            await MainActor.run {
                self.error = "Failed to load videos: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func extractYouTubeUrl(from post: AgriTVPost) -> String {
        let content = post.content.rendered
        
        // Look for YouTube URLs in various formats
        let patterns = [
            "https?://(?:www\\.)?youtube\\.com/watch\\?v=[a-zA-Z0-9_-]+",
            "https?://(?:www\\.)?youtu\\.be/[a-zA-Z0-9_-]+",
            "https?://(?:www\\.)?youtube\\.com/embed/[a-zA-Z0-9_-]+",
            "src=[\"']?(https?://(?:www\\.)?youtube\\.com/embed/[a-zA-Z0-9_-]+)[\"']?"
        ]
        
        for pattern in patterns {
            if let range = content.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                var url = String(content[range])
                // Clean up if it starts with src=
                if url.hasPrefix("src=") {
                    url = url.replacingOccurrences(of: "src=[\"']?", with: "", options: .regularExpression)
                    url = url.replacingOccurrences(of: "[\"']$", with: "", options: .regularExpression)
                }
                return url
            }
        }
        
        // Also check excerpt
        let excerpt = post.excerpt.rendered
        for pattern in patterns {
            if let range = excerpt.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(excerpt[range])
            }
        }
        
        return ""
    }
    
    private func cleanHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&#8220;", with: "\"")
            .replacingOccurrences(of: "&#8221;", with: "\"")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - WordPress Agri-TV Post Model
struct AgriTVPost: Codable {
    let id: Int
    let date: String
    let link: String
    let title: AgriTVTitle
    let excerpt: AgriTVExcerpt
    let content: AgriTVContent
    let _embedded: AgriTVEmbedded?
    
    enum CodingKeys: String, CodingKey {
        case id, date, link, title, excerpt, content, _embedded
    }
}

struct AgriTVTitle: Codable {
    let rendered: String
}

struct AgriTVExcerpt: Codable {
    let rendered: String
}

struct AgriTVContent: Codable {
    let rendered: String
}

struct AgriTVEmbedded: Codable {
    let wpFeaturedmedia: [AgriTVMedia]?
    
    enum CodingKeys: String, CodingKey {
        case wpFeaturedmedia = "wp:featuredmedia"
    }
}

struct AgriTVMedia: Codable {
    let source_url: String?
}
