//
//  BookmarkManager.swift
//  AgribusinessNewsApp
//
//  Created on 1 December 2025.
//

import Foundation

class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    
    @Published var bookmarkedArticles: [NewsArticleModel] = []
    
    private let bookmarksKey = "SavedBookmarks"
    
    init() {
        loadBookmarks()
    }
    
    func isBookmarked(_ article: NewsArticleModel) -> Bool {
        bookmarkedArticles.contains(where: { $0.id == article.id })
    }
    
    func toggleBookmark(_ article: NewsArticleModel) {
        if let index = bookmarkedArticles.firstIndex(where: { $0.id == article.id }) {
            bookmarkedArticles.remove(at: index)
        } else {
            bookmarkedArticles.insert(article, at: 0)
        }
        saveBookmarks()
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarkedArticles) {
            UserDefaults.standard.set(encoded, forKey: bookmarksKey)
        }
    }
    
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let decoded = try? JSONDecoder().decode([NewsArticleModel].self, from: data) {
            bookmarkedArticles = decoded
        }
    }
    
    func removeBookmark(_ article: NewsArticleModel) {
        if let index = bookmarkedArticles.firstIndex(where: { $0.id == article.id }) {
            bookmarkedArticles.remove(at: index)
            saveBookmarks()
        }
    }
    
    func clearAllBookmarks() {
        bookmarkedArticles.removeAll()
        saveBookmarks()
    }
}
