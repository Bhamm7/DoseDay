//
//  ContentView.swift
//  DoseDay
//
//  Created by Brett on 2026-03-09.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allEvents: [DoseEvent]

    var body: some View {
        TabView {
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationStack {
                GraphHubView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.xyaxis.line")
            }

            NavigationStack {
                ProtocolListView()
            }
            .tabItem {
                Label("Protocols", systemImage: "list.bullet.clipboard")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .task {
            let service = NotificationService()
            await service.requestPermission()
            service.reconcile(events: allEvents)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationService().reconcile(events: allEvents)
            }
        }
    }
}

#Preview {
    ContentView()
}
