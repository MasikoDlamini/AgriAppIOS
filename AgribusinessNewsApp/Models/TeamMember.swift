//
//  TeamMember.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import Foundation

struct TeamMember: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let description: String
    let imageUrl: String?
    
    /// Returns a properly encoded URL for the image
    var imageURL: URL? {
        guard let urlString = imageUrl else { return nil }
        // First try direct URL creation
        if let url = URL(string: urlString) {
            return url
        }
        // If that fails, try percent encoding
        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            return url
        }
        return nil
    }
    
    static let teamMembers: [TeamMember] = [
        TeamMember(
            name: "Sibusiso Mngadi",
            role: "Publisher / Editor-in-Chief",
            description: "Mngadi is a successful media visionary leader who inspires and motivates his team.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2025/01/resize_0001_Mr-Hilton-Dlamini-Non-Executive-Member-min-Recovered.jpg_0000_Sibusiso-Mngadi-1345x1536-1.webp"
        ),
        TeamMember(
            name: "Zwelithini Sikhakhane",
            role: "Video Producer",
            description: "Sikhakhane is the creative behind all our successful video products.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2025/10/Zweli-Sikhakhane-2.webp"
        ),
        TeamMember(
            name: "Phesheya Kunene",
            role: "Editorial Team Lead",
            description: "Phesheya is the editorial team lead across all our platforms and channels.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2025/10/Phesheya-Kunene.webp"
        ),
        TeamMember(
            name: "Lungile Gumbi-Simelane",
            role: "Advertising Sales Coordinator",
            description: "Lungile is responsible for coordinating advertising sales across all our platforms.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2026/01/Lungile-Gumbi-2.jpeg"
        ),
        TeamMember(
            name: "Mukelo Dlongolo",
            role: "Chief Photographer",
            description: "Mukelo is responsible for professional photography across all our platforms and channels.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2026/01/IMG_9867-2-e1768741784513.jpg"
        ),
        TeamMember(
            name: "Sibusisiwe Ndzimandze",
            role: "Journalist & Content Creator",
            description: "Sibu is a journalist and content creator passionate about telling agriculture stories that inspire others.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2025/10/sibu-ndzimandze.webp"
        ),
        TeamMember(
            name: "Sikhona Sibandze",
            role: "Journalist & Content Creator",
            description: "Sikhona is a journalist and content creator passionate about telling agriculture stories that inspire others.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2025/10/sikhona-sibandze-e1768746163200.webp"
        ),
        TeamMember(
            name: "Cyril Mbhamali",
            role: "Creative Lead",
            description: "Cyril is our graphic designer and multimedia creative for digital marketing, publishing and branding.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2026/01/Cyril-Mbhamali-e1768746827142.webp"
        ),
        TeamMember(
            name: "Joseph Mudu",
            role: "Graphic Design & Branding Specialist",
            description: "Joseph is our graphic designer and multimedia creative for digital marketing, publishing and branding.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2026/01/Joseph-Mudu-e1768747993561.jpg"
        ),
        TeamMember(
            name: "Masiko Dlamini",
            role: "Digital Platforms & Web Specialist",
            description: "Masiko is our digital platforms and web specialist, responsible for apps, websites, and all engagement channels.",
            imageUrl: "https://agribusinessmedia.com/wp-content/uploads/2026/02/IMG_1466-scaled.jpeg"
        )
    ]
}

struct AboutInfo {
    static let companyDescription = """
Agribusiness Media is Eswatini's premier digital platform dedicated to empowering the agricultural sector. Built on innovation, sustainability, and community, we aim to revolutionize how farmers, agribusinesses, and agricultural professionals access vital information, discover opportunities, and thrive in an ever-evolving digital landscape.
"""
    
    static let mission = """
To be the leading voice in agricultural media across Eswatini and the region, connecting farmers with knowledge, markets, and opportunities.
"""
    
    static let vision = """
Empowering Africa's agricultural future through innovative media solutions.
"""
}
