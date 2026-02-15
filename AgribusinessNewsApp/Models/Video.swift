//
//  Video.swift
//  AgribusinessNewsApp
//
//  Created on 14 February 2026.
//

import Foundation

struct Video: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let youtubeUrl: String
    let thumbnailUrl: String?
    let publishedDate: String
    let webUrl: String
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }
    
    // Sanitized URL with whitespace removed
    var sanitizedYoutubeUrl: String {
        youtubeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var youtubeVideoId: String? {
        // Extract video ID from various YouTube URL formats
        let url = sanitizedYoutubeUrl
        let patterns = [
            "(?:(?:www\\.)?youtube\\.com/watch\\?v=|youtu\\.be/|(?:www\\.)?youtube\\.com/embed/)([a-zA-Z0-9_-]{11})",
            "(?:www\\.)?youtube\\.com/watch\\?.*v=([a-zA-Z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, options: [], range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return nil
    }
    
    var youtubeThumbnailUrl: String? {
        guard let videoId = youtubeVideoId else { return nil }
        return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }
}

struct VideoResponse: Codable {
    let success: Bool
    let count: Int
    let videos: [Video]
}
