//
//  ItsukiAlarmApp.swift
//  ItsukiAlarm
//
//  Created by Itsuki on 2025/06/16.
//

import SwiftUI

@main
struct ItsukiAlarmApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .colorScheme(.dark)  // Changed to dark for OLED theme
                .task {
                    // Request notification permissions for wake-up checks
                    await ItsukiAlarmManager.shared.requestNotificationPermissions()
                }
        }
    }
}
