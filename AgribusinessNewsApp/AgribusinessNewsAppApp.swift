//
//  AgribusinessNewsAppApp.swift
//  AgribusinessNewsApp
//
//  Created on 29 November 2025.
//

import SwiftUI
import UserNotifications
import BackgroundTasks
import FirebaseCore
import FirebaseMessaging

@main
struct AgribusinessNewsAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    notificationManager.clearBadge()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Schedule background content check when app moves to background
                appDelegate.scheduleContentCheckTask()
            case .active:
                // Check for new content when app becomes active
                notificationManager.clearBadge()
                Task {
                    await notificationManager.checkForNewContent()
                }
            default:
                break
            }
        }
    }
    
    private func setupNotifications() {
        // Request notification permission on first launch
        notificationManager.requestAuthorization()
        
        // Schedule the first background content check
        appDelegate.scheduleContentCheckTask()
        
        // Initialize last seen content IDs on first launch
        // This prevents notifications for existing content
        if !UserDefaults.standard.bool(forKey: "hasInitializedNotifications") {
            Task {
                await initializeLastSeenContent()
                UserDefaults.standard.set(true, forKey: "hasInitializedNotifications")
            }
        }
    }
    
    private func initializeLastSeenContent() async {
        // Fetch latest content IDs without sending notifications
        // Articles
        if let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/posts?per_page=1") {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let posts = try? JSONDecoder().decode([WordPressPost].self, from: data),
               let latest = posts.first {
                notificationManager.setLastSeenArticleId(latest.id)
            }
        }
        
        // Magazines
        if let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/media?media_type=application&per_page=1&orderby=date&order=desc") {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let media = try? JSONDecoder().decode([WordPressMediaItem].self, from: data),
               let latest = media.first {
                notificationManager.setLastSeenMagazineId(latest.id)
            }
        }
    }
}

// MARK: - App Delegate for Firebase & Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        // Register background tasks
        registerBackgroundTasks()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Also store for debugging
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Handle incoming remote notifications (including silent pushes with content-available)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification: \(userInfo)")
        
        // Let Firebase handle the message
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Also trigger a local content check to update last seen IDs
        Task {
            await NotificationManager.shared.checkForNewContent()
            completionHandler(.newData)
        }
    }
    
    // MARK: - Firebase Messaging Delegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase FCM Token: \(fcmToken ?? "nil")")
        
        // Store FCM token
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
            
            // Subscribe to topics based on user preferences
            subscribeToTopics()
        }
    }
    
    private func subscribeToTopics() {
        let notifyArticles = UserDefaults.standard.object(forKey: "notifyNewArticles") as? Bool ?? true
        let notifyVideos = UserDefaults.standard.object(forKey: "notifyNewVideos") as? Bool ?? true
        let notifyMagazines = UserDefaults.standard.object(forKey: "notifyNewMagazines") as? Bool ?? true
        
        // Subscribe/unsubscribe based on preferences
        if notifyArticles {
            Messaging.messaging().subscribe(toTopic: "new_articles") { error in
                if let error = error {
                    print("Error subscribing to new_articles: \(error.localizedDescription)")
                } else {
                    print("Subscribed to new_articles topic")
                }
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_articles")
        }
        
        if notifyVideos {
            Messaging.messaging().subscribe(toTopic: "new_videos") { error in
                if let error = error {
                    print("Error subscribing to new_videos: \(error.localizedDescription)")
                } else {
                    print("Subscribed to new_videos topic")
                }
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_videos")
        }
        
        if notifyMagazines {
            Messaging.messaging().subscribe(toTopic: "new_magazines") { error in
                if let error = error {
                    print("Error subscribing to new_magazines: \(error.localizedDescription)")
                } else {
                    print("Subscribed to new_magazines topic")
                }
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_magazines")
        }
        
        // Always subscribe to all_users for important announcements
        Messaging.messaging().subscribe(toTopic: "all_users")
    }
    
    // MARK: - Background Tasks
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.agribusiness.contentcheck", using: nil) { task in
            self.handleContentCheckTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleContentCheckTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.agribusiness.contentcheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Check every 15 minutes minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled")
        } catch {
            print("Could not schedule background task: \(error.localizedDescription)")
        }
    }
    
    private func handleContentCheckTask(task: BGAppRefreshTask) {
        // Schedule the next check
        scheduleContentCheckTask()
        
        // Create a task to check for new content
        let checkTask = Task {
            await NotificationManager.shared.checkForNewContent()
        }
        
        task.expirationHandler = {
            checkTask.cancel()
        }
        
        Task {
            await checkTask.value
            task.setTaskCompleted(success: true)
        }
    }
}

// MARK: - Helper to update topic subscriptions
extension AppDelegate {
    static func updateTopicSubscriptions() {
        let notifyArticles = UserDefaults.standard.object(forKey: "notifyNewArticles") as? Bool ?? true
        let notifyVideos = UserDefaults.standard.object(forKey: "notifyNewVideos") as? Bool ?? true
        let notifyMagazines = UserDefaults.standard.object(forKey: "notifyNewMagazines") as? Bool ?? true
        
        if notifyArticles {
            Messaging.messaging().subscribe(toTopic: "new_articles")
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_articles")
        }
        
        if notifyVideos {
            Messaging.messaging().subscribe(toTopic: "new_videos")
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_videos")
        }
        
        if notifyMagazines {
            Messaging.messaging().subscribe(toTopic: "new_magazines")
        } else {
            Messaging.messaging().unsubscribe(fromTopic: "new_magazines")
        }
    }
}
