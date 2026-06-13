import SwiftUI

/// The main app interface once the launch flow is complete.
struct MainTabView: View {
    @ObservedObject var haptics: HapticManager

    var body: some View {
        TabView {
            ExploreView(haptics: haptics)
                .tabItem { Label("Explore", systemImage: "photo.on.rectangle.angled") }

            LiveView(haptics: haptics)
                .tabItem { Label("Live", systemImage: "camera.viewfinder") }

            SettingsView(haptics: haptics)
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(Theme.accent)
    }
}
