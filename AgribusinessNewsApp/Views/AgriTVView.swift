//
//  AgriTVView.swift
//  AgribusinessNewsApp
//
//  Created on 14 February 2026.
//

import SwiftUI

struct AgriTVView: View {
    @StateObject private var videoService = VideoService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Agri-TV")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Video content")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "play.tv.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Content based on state
                    if videoService.isLoading && videoService.videos.isEmpty {
                        LoadingVideosView()
                    } else if let error = videoService.error {
                        ErrorVideosView(error: error) {
                            Task {
                                try? await videoService.fetchVideos()
                            }
                        }
                    } else if videoService.videos.isEmpty {
                        EmptyVideosView()
                    } else {
                        // Video List
                        LazyVStack(spacing: 16) {
                            ForEach(videoService.videos) { video in
                                NavigationLink(destination: YouTubePlayerView(video: video)) {
                                    VideoCardView(video: video)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                try? await videoService.fetchVideos()
            }
            .task {
                if videoService.videos.isEmpty {
                    try? await videoService.fetchVideos()
                }
            }
        }
    }
}

// MARK: - Video Card View
struct VideoCardView: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                // Background color
                Color.black
                
                // Thumbnail image
                if let thumbnailUrl = video.thumbnailUrl ?? video.youtubeThumbnailUrl,
                   let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            DefaultVideoThumbnail()
                        @unknown default:
                            DefaultVideoThumbnail()
                        }
                    }
                } else {
                    DefaultVideoThumbnail()
                }
                
                // Play button overlay
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .offset(x: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .frame(height: 200)
            .clipped()
            
            // Video Info
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !video.description.isEmpty {
                    Text(video.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.red)
                        Text("Watch Now")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text(formatDate(video.publishedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "Recent" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

// MARK: - Default Video Thumbnail
struct DefaultVideoThumbnail: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.3)
            
            VStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("AGRI-TV")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Loading Videos View
struct LoadingVideosView: View {
    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 150, height: 14)
                    }
                    .padding(12)
                }
                .cornerRadius(12)
            }
        }
        .padding(16)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Error Videos View
struct ErrorVideosView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Load Videos")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 300)
    }
}

// MARK: - Empty Videos View
struct EmptyVideosView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "play.tv")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Videos Available")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Check back soon for new video content")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 300)
    }
}

#Preview {
    AgriTVView()
}
