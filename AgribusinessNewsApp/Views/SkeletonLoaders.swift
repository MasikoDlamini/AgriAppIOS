//
//  SkeletonLoaders.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import SwiftUI

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shape
struct SkeletonShape: View {
    var height: CGFloat = 20
    var width: CGFloat? = nil
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - News Article Skeleton
struct NewsArticleSkeletonCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail skeleton
            SkeletonShape(height: 90, cornerRadius: 8)
                .frame(width: 90)
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(height: 16)
                SkeletonShape(height: 16)
                SkeletonShape(height: 16, width: 120)
                Spacer()
                HStack {
                    SkeletonShape(height: 12, width: 60)
                    Spacer()
                    SkeletonShape(height: 12, width: 80)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - News Loading Skeleton
struct NewsLoadingSkeleton: View {
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                NewsArticleSkeletonCard()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Featured Article Skeleton
struct FeaturedArticleSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                SkeletonShape(height: 200, cornerRadius: 0)
                
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonShape(height: 24, width: 80, cornerRadius: 4)
                    Spacer()
                    SkeletonShape(height: 20)
                    SkeletonShape(height: 14, width: 200)
                }
                .padding(20)
            }
            .frame(height: 200)
            
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Magazine Skeleton Card
struct MagazineSkeletonCard: View {
    var body: some View {
        VStack(spacing: 0) {
            SkeletonShape(height: 240, cornerRadius: 0)
            
            VStack(spacing: 8) {
                SkeletonShape(height: 14, width: 80)
                SkeletonShape(height: 12, width: 100)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Magazine Loading Skeleton
struct MagazineLoadingSkeleton: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 20) {
            ForEach(0..<4, id: \.self) { _ in
                MagazineSkeletonCard()
            }
        }
        .padding(20)
    }
}

// MARK: - Video Skeleton Card
struct VideoSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail skeleton
            ZStack {
                SkeletonShape(height: 200, cornerRadius: 0)
                
                // Play button placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(height: 18)
                SkeletonShape(height: 14, width: 150)
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Video Loading Skeleton
struct VideoLoadingSkeleton: View {
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VideoSkeletonCard()
            }
        }
        .padding(16)
    }
}

// MARK: - Horizontal Video Skeleton
struct HorizontalVideoSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonShape(height: 112, cornerRadius: 8)
                            .frame(width: 200)
                        SkeletonShape(height: 14, width: 180)
                        SkeletonShape(height: 12, width: 100)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Magazine Highlight Skeleton
struct MagazineHighlightSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonShape(height: 24, width: 150)
                Spacer()
                SkeletonShape(height: 16, width: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack(spacing: 16) {
                SkeletonShape(height: 160, width: 120, cornerRadius: 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonShape(height: 20, width: 80)
                    SkeletonShape(height: 18, width: 120)
                    SkeletonShape(height: 14)
                    Spacer()
                    SkeletonShape(height: 40, width: 110, cornerRadius: 8)
                }
                .padding(.vertical, 8)
                
                Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Home Loading Skeleton
struct HomeLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Featured skeleton
            FeaturedArticleSkeleton()
            
            // Categories skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(height: 20, width: 120)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonShape(height: 90, width: 100, cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 12)
            
            // Magazine highlight skeleton
            MagazineHighlightSkeleton()
            
            // Videos skeleton
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SkeletonShape(height: 20, width: 100)
                    Spacer()
                    SkeletonShape(height: 16, width: 70)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HorizontalVideoSkeleton()
            }
            .padding(.bottom, 8)
            
            // Latest news skeleton
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SkeletonShape(height: 20, width: 120)
                    Spacer()
                    SkeletonShape(height: 16, width: 70)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                ForEach(0..<3, id: \.self) { _ in
                    NewsArticleSkeletonCard()
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        HomeLoadingSkeleton()
    }
    .background(Color(.systemGroupedBackground))
}
