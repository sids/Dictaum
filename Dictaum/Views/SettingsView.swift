//
//  SettingsView.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

enum PreferencesTab: Int, CaseIterable {
    case general = 0
    case model = 1
    case advanced = 2
    case permissions = 3
    case history = 4
}

struct SettingsView: View {
    static let windowTitle = "Dictaum Settings"
    
    @StateObject private var store = SettingsStore.shared
    @StateObject private var launchHelper = LaunchAtLoginHelper()
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            GeneralTab(store: store, launchHelper: launchHelper)
                .navigationTitle(SettingsView.windowTitle)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(PreferencesTab.general)
            
            ModelTab(store: store)
                .navigationTitle(SettingsView.windowTitle)
                .tabItem {
                    Label("Model", systemImage: "brain")
                }
                .tag(PreferencesTab.model)
            
            AdvancedTab(store: store)
                .navigationTitle(SettingsView.windowTitle)
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(PreferencesTab.advanced)
            
            PermissionsTab(permissionManager: permissionManager)
                .navigationTitle(SettingsView.windowTitle)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                .tag(PreferencesTab.permissions)
            
            HistoryTab(store: store)
                .navigationTitle(SettingsView.windowTitle)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(PreferencesTab.history)
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshPermissionStatus()
        }
    }
}

#Preview {
    SettingsView()
}
