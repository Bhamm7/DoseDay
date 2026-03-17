//
//  ContentView.swift
//  DoseDay
//
//  Created by Brett on 2026-03-09.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

private enum AppTab: Hashable {
    case today
    case beta
    case calendar
    case stats
    case protocols
    case settings
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allEvents: [DoseEvent]
    @State private var selectedTab: AppTab = .today

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "checklist")
            }
            .tag(AppTab.today)

            NavigationStack {
                BetaDailyView()
            }
            .tabItem {
                Label("Beta", systemImage: "testtube.2")
            }
            .tag(AppTab.beta)

            NavigationStack {
                GraphHubView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.xyaxis.line")
            }
            .tag(AppTab.stats)

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(AppTab.calendar)

            NavigationStack {
                ProtocolListView()
            }
            .tabItem {
                Label("Protocols", systemImage: "list.bullet.clipboard")
            }
            .tag(AppTab.protocols)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
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

#if canImport(UIKit)
private func configureTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(Color(hex: "#F7F2E4")).withAlphaComponent(0.98)
    appearance.shadowColor = UIColor(Color(hex: "#E3DCC4"))

    let normalColor = UIColor(Color(hex: "#73806F"))
    let selectedColor = UIColor(Color(hex: "#556B50"))
    let stacked = appearance.stackedLayoutAppearance

    stacked.normal.iconColor = normalColor
    stacked.normal.titleTextAttributes = [.foregroundColor: normalColor]
    stacked.selected.iconColor = selectedColor
    stacked.selected.titleTextAttributes = [.foregroundColor: selectedColor]

    appearance.inlineLayoutAppearance = stacked
    appearance.compactInlineLayoutAppearance = stacked

    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    UITabBar.appearance().tintColor = selectedColor
    UITabBar.appearance().unselectedItemTintColor = normalColor
}
#endif

#Preview {
    ContentView()
}
