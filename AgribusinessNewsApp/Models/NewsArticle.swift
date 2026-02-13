//
//  NewsArticle.swift
//  AgribusinessNewsApp
//
//  Created on 30 November 2025.
//

import Foundation

struct NewsResponse: Codable {
    let success: Bool
    let count: Int
    let articles: [NewsArticleModel]
}

struct NewsArticleModel: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let link: String
    let excerpt: String
    let image: String?
    let category: String
    let date: String
    let timestamp: String
    
    static func == (lhs: NewsArticleModel, rhs: NewsArticleModel) -> Bool {
        lhs.id == rhs.id
    }
}
