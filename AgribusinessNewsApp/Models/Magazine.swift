//
//  Magazine.swift
//  AgribusinessNewsApp
//
//  Created on 1 December 2025.
//

import Foundation

struct Magazine: Codable, Identifiable {
    let id: Int
    let title: String
    let issueNumber: String
    let monthYear: String
    let pdfUrl: String
    let coverImageUrl: String?
    let publishedDate: String
    
    var displayTitle: String {
        monthYear
    }
    
    var issueLabel: String {
        issueNumber
    }
}

struct MagazineResponse: Codable {
    let success: Bool
    let count: Int
    let magazines: [Magazine]
}

// WordPress Media Item for PDFs
struct WordPressMediaItem: Codable {
    let id: Int
    let date: String
    let title: WordPressTitle
    let source_url: String
}
