//
//  Video.swift
//  AgribusinessNewsApp
//
//  Created on 14 February 2026.
//

import Foundation

struct Video: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let youtubeUrl: String
    let thumbnailUrl: String?
    let publishedDate: String
    let webUrl: String
    
    var youtubeVideoId: String? {
        // Extract video ID from various YouTube URL formats
        let patterns = [
            "(?:youtube\\.com/watch\\?v=|youtu\\.be/|youtube\\.com/embed/)([a-zA-Z0-9_-]{11})",
            "youtube\\.com/watch\\?.*v=([a-zA-Z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: youtubeUrl, options: [], range: NSRange(youtubeUrl.startIndex..., in: youtubeUrl)),
               let range = Range(match.range(at: 1), in: youtubeUrl) {
                return String(youtubeUrl[range])
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
