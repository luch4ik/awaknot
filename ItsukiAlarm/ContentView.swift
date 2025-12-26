//
//  ContentView.swift
//  ItsukiAlarm
//
//  Created by Itsuki on 2025/06/15.
//

import SwiftUI
import AlarmKit


struct ContentView: View {
    @State private var alarmManager: ItsukiAlarmManager = .shared

    var body: some View {
        AlarmListView()
            .environment(self.alarmManager)
            .fullScreenCover(item: $alarmManager.triggeringAlarm) { alarm in
                TriggerView(alarm: alarm) {
                    // Schedule wake-up check if enabled
                    alarmManager.scheduleWakeUpCheck(for: alarm)
                    // Dismiss action
                    alarmManager.triggeringAlarm = nil
                }
            }
            .onOpenURL { url in
                print("open open url: \(url)")
                let path = url.path(percentEncoded: false)
                if let alarmId = UUID(uuidString: path), let alarm = alarmManager.runningAlarms.first(where: {$0.id == alarmId}) {
                    // Handle opening specific alarm
                    print("Opening alarm: \(alarm.id)")
                }
            }
            .alert("Oops!", isPresented: $alarmManager.showError, actions: {
                Button(action: {
                    alarmManager.showError = false
                }, label: {
                    Text("OK")
                })
            }, message: {
                Text("\(alarmManager.error?.message ?? "Unknown Error")")
            })
    }
}
