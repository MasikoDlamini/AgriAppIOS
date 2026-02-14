//
//  YouTubePlayerView.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import SwiftUI
import SafariServices

struct YouTubePlayerView: View {
    let video: Video
    
    var youtubeURL: URL? {
        if let videoId = video.youtubeVideoId {
            return URL(string: "https://www.youtube.com/watch?v=\(videoId)")
        }
        return URL(string: video.youtubeUrl)
    }
    
    var body: some View {
        if let url = youtubeURL {
            SafariView(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Agri-TV")
                .edgesIgnoringSafeArea(.bottom)
        } else {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Video unavailable")
                    .font(.headline)
            }
        }
    }
}
