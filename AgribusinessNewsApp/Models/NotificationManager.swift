//
//  NotificationManager.swift
//  AgribusinessNewsApp
//
//  Created on 16 February 2026.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // Keys for UserDefaults to track last seen content
    private let lastArticleIdKey = "lastSeenArticleId"
    private let lastVideoIdKey = "lastSeenVideoId"
    private let lastMagazineIdKey = "lastSeenMagazineId"
    private let lastCheckDateKey = "lastNotificationCheckDate"
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Handling
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.registerForRemoteNotifications()
                }
            }
            
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Content Tracking
    
    func getLastSeenArticleId() -> Int {
        UserDefaults.standard.integer(forKey: lastArticleIdKey)
    }
    
    func setLastSeenArticleId(_ id: Int) {
        UserDefaults.standard.set(id, forKey: lastArticleIdKey)
    }
    
    func getLastSeenVideoId() -> String {
        UserDefaults.standard.string(forKey: lastVideoIdKey) ?? ""
    }
    
    func setLastSeenVideoId(_ id: String) {
        UserDefaults.standard.set(id, forKey: lastVideoIdKey)
    }
    
    func getLastSeenMagazineId() -> Int {
        UserDefaults.standard.integer(forKey: lastMagazineIdKey)
    }
    
    func setLastSeenMagazineId(_ id: Int) {
        UserDefaults.standard.set(id, forKey: lastMagazineIdKey)
    }
    
    // MARK: - Local Notifications
    
    func scheduleNewArticleNotification(title: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = "📰 New Article"
        content.body = title
        content.subtitle = category
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "article"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling article notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNewVideoNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "📺 New Video on Agri-TV"
        content.body = title
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "video"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling video notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNewMagazineNotification(issueNumber: String, monthYear: String) {
        let content = UNMutableNotificationContent()
        content.title = "📖 New Magazine Available"
        content.body = "\(issueNumber) - \(monthYear) is now available!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "magazine"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling magazine notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Content Check
    
    func checkForNewContent() async {
        guard isAuthorized else { return }
        
        // Check user preferences
        let notifyArticles = UserDefaults.standard.object(forKey: "notifyNewArticles") as? Bool ?? true
        let notifyVideos = UserDefaults.standard.object(forKey: "notifyNewVideos") as? Bool ?? true
        let notifyMagazines = UserDefaults.standard.object(forKey: "notifyNewMagazines") as? Bool ?? true
        
        // Check for new articles
        if notifyArticles {
            await checkForNewArticles()
        }
        
        // Check for new videos
        if notifyVideos {
            await checkForNewVideos()
        }
        
        // Check for new magazines
        if notifyMagazines {
            await checkForNewMagazines()
        }
        
        // Update last check date
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
    }
    
    private func checkForNewArticles() async {
        guard let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/posts?per_page=1&_embed=true") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let posts = try JSONDecoder().decode([WordPressPost].self, from: data)
            
            if let latestPost = posts.first {
                let lastSeenId = getLastSeenArticleId()
                
                // Only notify if we have a previous ID and the new one is different
                if lastSeenId > 0 && latestPost.id > lastSeenId {
                    let title = cleanHTML(latestPost.title.rendered)
                    var category = "News"
                    if let embedded = latestPost._embedded,
                       let terms = embedded.wpTerm?.first?.first {
                        category = terms.name ?? "News"
                    }
                    scheduleNewArticleNotification(title: title, category: category)
                }
                
                // Always update the last seen ID
                setLastSeenArticleId(latestPost.id)
            }
        } catch {
            print("Error checking for new articles: \(error.localizedDescription)")
        }
    }
    
    private func checkForNewVideos() async {
        // YouTube API check - using RSS feed or API
        let channelId = "UCyourChannelId" // Replace with actual channel ID
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(channelId)&maxResults=1&order=date&type=video&key=YOUR_API_KEY") else { return }
        
        // For now, we'll check videos through the app's video service
        // This is a placeholder - in production, you'd use YouTube Data API or RSS
    }
    
    private func checkForNewMagazines() async {
        guard let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/media?media_type=application&per_page=1&orderby=date&order=desc") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let mediaItems = try JSONDecoder().decode([WordPressMediaItem].self, from: data)
            
            if let latestMedia = mediaItems.first {
                // Check if it's a magazine (has ISSUE in title)
                let title = latestMedia.title.rendered.uppercased()
                guard title.contains("ISSUE") else { return }
                
                let lastSeenId = getLastSeenMagazineId()
                
                if lastSeenId > 0 && latestMedia.id > lastSeenId {
                    // Extract issue info
                    let (issueNumber, monthYear) = extractIssueInfo(from: latestMedia.title.rendered, url: latestMedia.source_url)
                    scheduleNewMagazineNotification(issueNumber: issueNumber, monthYear: monthYear)
                }
                
                setLastSeenMagazineId(latestMedia.id)
            }
        } catch {
            print("Error checking for new magazines: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func cleanHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractIssueInfo(from title: String, url: String) -> (issueNumber: String, monthYear: String) {
        let combined = "\(title) \(url)".uppercased()
        
        var issueNumber = "New Issue"
        if let issueRange = combined.range(of: "ISSUE[\\s-]*\\d+", options: .regularExpression) {
            let issueText = String(combined[issueRange])
            if let numberRange = issueText.range(of: "\\d+", options: .regularExpression) {
                let number = String(issueText[numberRange])
                issueNumber = "Issue \(number)"
            }
        }
        
        var monthYear = ""
        let months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                     "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
        
        for month in months {
            if combined.contains(month) {
                if let yearRange = combined.range(of: "20\\d{2}", options: .regularExpression) {
                    let year = String(combined[yearRange])
                    monthYear = "\(month.capitalized) \(year)"
                    break
                }
            }
        }
        
        return (issueNumber, monthYear)
    }
    
    // MARK: - Badge Management
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            // Handle notification tap based on type
            NotificationCenter.default.post(
                name: NSNotification.Name("NotificationTapped"),
                object: nil,
                userInfo: ["type": type]
            )
        }
        
        completionHandler()
    }
}
