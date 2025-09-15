//
//  ProcurementAIappApp.swift
//  ProcurementAIapp
//
//  Created by Mr Krabs on 04/09/2025.
//

import SwiftUI
import CloudKit

// MARK: - AppDelegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    static var store: NoticeStore?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ Successfully registered for remote notifications")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification?.subscriptionID == "notice-changes" {
            print("📬 CloudKit push received → refreshing bulletin board")
            AppDelegate.store?.fetchBulletinBoard()
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}

// MARK: - Main App
@main
struct ProcurementAIappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = NoticeStore()

    init() {
        // Pass store into AppDelegate so it can refresh when push arrives
        AppDelegate.store = store
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NoticeTypeSelector(store: store)
                    .tabItem {
                        Label("New Notice", systemImage: "doc.badge.plus")
                    }

                RepositoryView(store: store)
                    .tabItem {
                        Label("Drafts", systemImage: "tray.full")
                    }

                BulletinBoardView(store: store)
                    .tabItem {
                        Label("Bulletin", systemImage: "megaphone")
                    }
            }
            .onAppear {
                // Initial fetch when app launches
                store.fetchBulletinBoard()
                // Register for silent CloudKit pushes
                UIApplication.shared.registerForRemoteNotifications()
            }
            .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                store.fetchBulletinBoard()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                store.fetchBulletinBoard()
            }
        }
    }
}
