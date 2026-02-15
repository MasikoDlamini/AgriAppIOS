//
//  AboutView.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Banner
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 180)
                        
                        VStack(spacing: 8) {
                            Text("AGRIBUSINESS")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                            Text("MEDIA")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(6)
                        }
                        .padding(.bottom, 30)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "About Us", icon: "info.circle.fill")
                        
                        Text(AboutInfo.companyDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Mission & Vision
                    HStack(spacing: 16) {
                        InfoCard(
                            title: "Our Mission",
                            description: AboutInfo.mission,
                            icon: "target",
                            color: .blue
                        )
                        
                        InfoCard(
                            title: "Our Vision",
                            description: AboutInfo.vision,
                            icon: "eye.fill",
                            color: .orange
                        )
                    }
                    .padding(20)
                    .background(Color(.systemGroupedBackground))
                    
                    Divider()
                    
                    // Our Team Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Our Team", icon: "person.3.fill")
                        
                        Text("We are a team of professionals who are passionate about what we do.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(TeamMember.teamMembers) { member in
                                TeamMemberCard(member: member)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Contact Us", icon: "envelope.fill")
                        
                        VStack(spacing: 12) {
                            ContactRow(icon: "globe", text: "agribusinessmedia.com", color: .green)
                            ContactRow(icon: "envelope.fill", text: "info@agribusinessmedia.com", color: .blue)
                            ContactRow(icon: "mappin.circle.fill", text: "Eswatini", color: .red)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("© 2026 Agribusiness Media")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Team Member Card
struct TeamMemberCard: View {
    let member: TeamMember
    
    var body: some View {
        VStack(spacing: 12) {
            // Photo
            if let url = member.imageURL {
                AsyncImage(url: url, scale: 1.0) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        TeamMemberPlaceholder(name: member.name)
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    @unknown default:
                        TeamMemberPlaceholder(name: member.name)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
            } else {
                TeamMemberPlaceholder(name: member.name)
            }
            
            // Name & Role
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(member.role)
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Description
            if !member.description.isEmpty {
                Text(member.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Team Member Placeholder
struct TeamMemberPlaceholder: View {
    let name: String
    
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2))
    }
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.green.opacity(0.6), Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                Text(initials.uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AboutView()
}
