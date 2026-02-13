//
//  MagazinesView.swift
//  AgribusinessNewsApp
//
//  Created on 1 December 2025.
//

import SwiftUI

struct MagazinesView: View {
    @StateObject private var magazineService = MagazineService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Magazines")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Digital editions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Content based on state
                    if magazineService.isLoading && magazineService.magazines.isEmpty {
                        LoadingMagazinesView()
                    } else if let error = magazineService.error {
                        ErrorMagazinesView(error: error) {
                            Task {
                                try? await magazineService.fetchMagazines()
                            }
                        }
                    } else if magazineService.magazines.isEmpty {
                        EmptyMagazinesView()
                    } else {
                        // Magazine Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(magazineService.magazines) { magazine in
                                NavigationLink(destination: SafariView(url: URL(string: magazine.pdfUrl)!)) {
                                    MagazineCoverViewDynamic(magazine: magazine)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .refreshable {
                try? await magazineService.fetchMagazines()
            }
            .task {
                if magazineService.magazines.isEmpty {
                    try? await magazineService.fetchMagazines()
                }
            }
        }
    }
}

struct MagazineIssue: Identifiable {
    let id = UUID()
    let title: String
    let issue: String
    let coverColor: Color
    let url: String
}

struct MagazineCoverView: View {
    let magazine: MagazineIssue
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover
            ZStack {
                magazine.coverColor
                    .frame(height: 240)
                
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("AGRIBUSINESS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("MONTHLY")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.white.opacity(0.5))
                            .frame(width: 60)
                        
                        Text(magazine.issue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(magazine.title.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Info
            VStack(spacing: 4) {
                Text(magazine.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text("Read Now")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Dynamic Magazine Cover
struct MagazineCoverViewDynamic: View {
    let magazine: Magazine
    
    // Generate color based on issue number
    var coverColor: Color {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.6, blue: 0.3),  // Green
            Color(red: 0.3, green: 0.5, blue: 0.8),  // Blue
            Color(red: 0.8, green: 0.4, blue: 0.2),  // Orange
            Color(red: 0.6, green: 0.3, blue: 0.7),  // Purple
            Color(red: 0.2, green: 0.7, blue: 0.7),  // Teal
        ]
        
        let index = abs(magazine.id.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover
            ZStack {
                coverColor
                    .frame(height: 240)
                
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("AGRIBUSINESS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("MONTHLY")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Divider()
                            .background(Color.white.opacity(0.5))
                            .frame(width: 60)
                        
                        Text(magazine.issueLabel.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(magazine.displayTitle.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Info
            VStack(spacing: 4) {
                Text(magazine.displayTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text("Read Now")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.green)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Loading State
struct LoadingMagazinesView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading magazines...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}

// MARK: - Error State
struct ErrorMagazinesView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Load Magazines")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Empty State
struct EmptyMagazinesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Magazines Available")
                .font(.headline)
            
            Text("Check back later for new issues")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }
}

#Preview {
    MagazinesView()
}
