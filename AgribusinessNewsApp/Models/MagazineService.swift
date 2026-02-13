//
//  MagazineService.swift
//  AgribusinessNewsApp
//
//  Created on 1 December 2025.
//

import Foundation

class MagazineService: ObservableObject {
    @Published var magazines: [Magazine] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // WordPress Media API for PDFs
    private let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/media"
    
    func fetchMagazines() async throws -> [Magazine] {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // Fetch PDF files from WordPress media library
        guard let url = URL(string: "\(baseURL)?media_type=application&per_page=50&orderby=date&order=desc") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            throw URLError(.badURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let mediaItems = try JSONDecoder().decode([WordPressMediaItem].self, from: data)
            
            // Filter for magazine PDFs only and transform
            let transformedMagazines = mediaItems.compactMap { item -> Magazine? in
                let title = item.title.rendered.uppercased()
                let sourceUrl = item.source_url.uppercased()
                
                // Only include PDFs with "ISSUE" followed by a number (e.g., ISSUE 29, ISSUE-29)
                guard sourceUrl.contains(".PDF"),
                      let _ = title.range(of: "ISSUE\\s*-?\\s*\\d+", options: .regularExpression) else {
                    return nil
                }
                
                // Skip if it contains unwanted keywords
                let skipKeywords = ["FLYER", "BUDGET", "SPEECH", "BANNER", "ADVERT", "AD-"]
                if skipKeywords.contains(where: { title.contains($0) || sourceUrl.contains($0) }) {
                    return nil
                }
                
                // Extract issue number and date from title
                let cleanTitle = cleanHTML(item.title.rendered)
                let (issueNumber, monthYear) = extractIssueInfo(from: cleanTitle, url: item.source_url)
                
                return Magazine(
                    id: item.id,
                    title: cleanTitle,
                    issueNumber: issueNumber,
                    monthYear: monthYear,
                    pdfUrl: item.source_url,
                    coverImageUrl: nil,
                    publishedDate: item.date
                )
            }
            
            // Sort by date (newest first)
            let sortedMagazines = transformedMagazines.sorted { mag1, mag2 in
                mag1.publishedDate > mag2.publishedDate
            }
            
            await MainActor.run {
                self.magazines = sortedMagazines
                self.isLoading = false
            }
            
            return sortedMagazines
        } catch {
            await MainActor.run {
                self.error = "Failed to load magazines: \(error.localizedDescription)"
                self.isLoading = false
            }
            throw error
        }
    }
    
    private func cleanHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractIssueInfo(from title: String, url: String) -> (issueNumber: String, monthYear: String) {
        let combined = "\(title) \(url)".uppercased()
        
        // Extract issue number (e.g., "ISSUE 30", "ISSUE-30")
        var issueNumber = "Latest Issue"
        if let issueRange = combined.range(of: "ISSUE[\\s-]*\\d+", options: .regularExpression) {
            let issueText = String(combined[issueRange])
            if let numberRange = issueText.range(of: "\\d+", options: .regularExpression) {
                let number = String(issueText[numberRange])
                issueNumber = "Issue \(number)"
            }
        }
        
        // Extract month and year
        var monthYear = "Recent"
        let months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                     "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
                     "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        
        for month in months {
            if combined.contains(month) {
                // Try to find year (20XX or just XX)
                if let yearRange = combined.range(of: "20\\d{2}|\\b\\d{2}\\b", options: .regularExpression) {
                    var year = String(combined[yearRange])
                    if year.count == 2 {
                        year = "20\(year)"
                    }
                    
                    // Get full month name
                    let fullMonth: String
                    switch month {
                    case "JAN", "JANUARY": fullMonth = "January"
                    case "FEB", "FEBRUARY": fullMonth = "February"
                    case "MAR", "MARCH": fullMonth = "March"
                    case "APR", "APRIL": fullMonth = "April"
                    case "MAY": fullMonth = "May"
                    case "JUN", "JUNE": fullMonth = "June"
                    case "JUL", "JULY": fullMonth = "July"
                    case "AUG", "AUGUST": fullMonth = "August"
                    case "SEP", "SEPTEMBER": fullMonth = "September"
                    case "OCT", "OCTOBER": fullMonth = "October"
                    case "NOV", "NOVEMBER": fullMonth = "November"
                    case "DEC", "DECEMBER": fullMonth = "December"
                    default: fullMonth = month.capitalized
                    }
                    
                    monthYear = "\(fullMonth) \(year)"
                    break
                }
            }
        }
        
        return (issueNumber, monthYear)
    }
}
