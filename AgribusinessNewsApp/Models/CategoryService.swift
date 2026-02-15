//
//  CategoryService.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import Foundation

struct ArticleCategory: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let count: Int
    let slug: String
    
    var displayName: String {
        name.replacingOccurrences(of: "&amp;", with: "&")
    }
    
    var icon: String {
        switch slug.lowercased() {
        case "agribusiness": return "building.2.fill"
        case "livestock": return "hare.fill"
        case "crops": return "leaf.fill"
        case "business": return "briefcase.fill"
        case "beef": return "fork.knife"
        case "poultry": return "bird.fill"
        case "dairy": return "drop.fill"
        case "beans": return "circle.grid.3x3.fill"
        case "grains": return "circle.hexagongrid.fill"
        case "horticulture": return "camera.macro"
        case "fruits": return "apple.logo"
        case "goat": return "pawprint.fill"
        case "pork": return "fork.knife"
        case "fish": return "fish.fill"
        case "forestry": return "tree.fill"
        case "sugar": return "cube.fill"
        case "cotton": return "cloud.fill"
        case "flowers": return "camera.macro"
        case "events": return "calendar"
        case "education-training": return "graduationcap.fill"
        case "technology-and-innovation": return "cpu.fill"
        case "news": return "newspaper.fill"
        case "eswatini-news": return "map.fill"
        case "africa": return "globe.africa.fill"
        case "world": return "globe"
        case "media": return "play.rectangle.fill"
        case "sponsored": return "star.fill"
        default: return "doc.text.fill"
        }
    }
}

class CategoryService: ObservableObject {
    @Published var categories: [ArticleCategory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/categories"
    
    func fetchCategories() async throws -> [ArticleCategory] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let url = URL(string: "\(baseURL)?per_page=50&orderby=count&order=desc") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            throw URLError(.badURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedCategories = try JSONDecoder().decode([ArticleCategory].self, from: data)
            
            // Filter out categories with no articles
            let filteredCategories = decodedCategories.filter { $0.count > 0 }
            
            await MainActor.run {
                self.categories = filteredCategories
                self.isLoading = false
            }
            
            return filteredCategories
        } catch {
            await MainActor.run {
                self.error = "Failed to load categories: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
}
