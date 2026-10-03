import SwiftUI

@main
struct CentroDeComandoApp: App {
    @StateObject private var settings = ServerSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var settings: ServerSettings

    var body: some View {
        if settings.editing || settings.url == nil {
            SetupView()
        } else {
            DashboardView()
        }
    }
}
