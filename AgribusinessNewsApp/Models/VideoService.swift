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
            // Fetch from WordPress custom post type
            guard let url = URL(string: "\(baseURL)?per_page=50&orderby=date&order=desc") else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([AgriTVPost].self, from: data)
            
            // Transform posts to videos
            let transformedVideos = posts.compactMap { post -> Video? in
                // Get YouTube URL from ACF field
                guard let youtubeUrl = post.acf?.youtube_url, !youtubeUrl.isEmpty else {
                    return nil
                }
                
                // Get description from ACF field
                let description = post.acf?.description ?? ""
                
                return Video(
                    id: post.id,
                    title: cleanHTML(post.title.rendered),
                    description: cleanHTML(description),
                    youtubeUrl: youtubeUrl,
                    thumbnailUrl: nil,
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
    let content: AgriTVContent
    let acf: AgriTVACF?
}

struct AgriTVTitle: Codable {
    let rendered: String
}

struct AgriTVContent: Codable {
    let rendered: String
}

struct AgriTVACF: Codable {
    let youtube_url: String?
    let description: String?
}
