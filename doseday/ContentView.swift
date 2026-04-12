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
    case schedule
    case reports
    case protocols
    case tools
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allEvents: [DoseEvent]
    @State private var selectedTab: AppTab = .schedule

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar.badge.clock")
            }
            .tag(AppTab.schedule)

            NavigationStack {
                GraphHubView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.xyaxis.line")
            }
            .tag(AppTab.reports)

            NavigationStack {
                ProtocolListView()
            }
            .tabItem {
                Label("Protocols", systemImage: "list.bullet.clipboard")
            }
            .tag(AppTab.protocols)

            NavigationStack {
                ToolsView()
            }
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
            .tag(AppTab.tools)
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
    appearance.backgroundColor = UIColor.white
    appearance.shadowColor = UIColor(DDTheme.cardBorder)

    let normalColor = UIColor(DDTheme.textTertiary)
    let selectedColor = UIColor(DDTheme.accent)
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
