//
//  NotificationSettingsView.swift
//  AgribusinessNewsApp
//
//  Created on 16 February 2026.
//

import SwiftUI
import FirebaseMessaging

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("notifyNewArticles") private var notifyNewArticles = true
    @AppStorage("notifyNewVideos") private var notifyNewVideos = true
    @AppStorage("notifyNewMagazines") private var notifyNewMagazines = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if notificationManager.isAuthorized {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Notifications Enabled")
                                .foregroundColor(.primary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.orange)
                                Text("Notifications Disabled")
                                    .foregroundColor(.primary)
                            }
                            
                            Text("Enable notifications in Settings to receive updates about new content.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .padding(.top, 4)
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                Section {
                    Toggle(isOn: $notifyNewArticles) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("New Articles")
                                Text("Get notified when new news articles are published")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "newspaper.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .tint(.green)
                    .onChange(of: notifyNewArticles) { _, newValue in
                        updateTopicSubscription(topic: "new_articles", subscribe: newValue)
                    }
                    
                    Toggle(isOn: $notifyNewVideos) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("New Videos")
                                Text("Get notified when new Agri-TV videos are uploaded")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "play.tv.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .tint(.green)
                    .onChange(of: notifyNewVideos) { _, newValue in
                        updateTopicSubscription(topic: "new_videos", subscribe: newValue)
                    }
                    
                    Toggle(isOn: $notifyNewMagazines) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("New Magazines")
                                Text("Get notified when new magazine issues are available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .tint(.green)
                    .onChange(of: notifyNewMagazines) { _, newValue in
                        updateTopicSubscription(topic: "new_magazines", subscribe: newValue)
                    }
                } header: {
                    Text("Notification Types")
                } footer: {
                    Text("Choose which types of content you want to be notified about.")
                }
                
                Section {
                    Button(action: {
                        Task {
                            await notificationManager.checkForNewContent()
                        }
                    }) {
                        Label("Check for New Content Now", systemImage: "arrow.clockwise")
                    }
                } footer: {
                    Text("The app automatically checks for new content in the background. Use this to check manually.")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                notificationManager.checkAuthorizationStatus()
            }
        }
    }
    
    private func updateTopicSubscription(topic: String, subscribe: Bool) {
        if subscribe {
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    print("Error subscribing to \(topic): \(error.localizedDescription)")
                } else {
                    print("Subscribed to \(topic)")
                }
            }
        } else {
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    print("Error unsubscribing from \(topic): \(error.localizedDescription)")
                } else {
                    print("Unsubscribed from \(topic)")
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
