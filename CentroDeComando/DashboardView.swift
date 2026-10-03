import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var reloadToken = 0
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = settings.url {
                WebView(url: url, reloadToken: reloadToken, loadError: $loadError)
            }

            if let err = loadError {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark").font(.system(size: 40))
                    Text("Não foi possível ligar ao servidor").font(.headline)
                    Text(err).font(.footnote).multilineTextAlignment(.center).foregroundColor(.gray)
                    Text("Confirma que o app.py está a correr e que o iPhone está na mesma rede (ou no Tailscale).")
                        .font(.footnote).multilineTextAlignment(.center).foregroundColor(.gray)
                    HStack {
                        Button("Tentar de novo") { loadError = nil; reloadToken += 1 }
                            .buttonStyle(.borderedProminent)
                        Button("Alterar servidor") { settings.editing = true }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(24)
                .background(Color.black)
            }

            VStack {
                Spacer()
                HStack(spacing: 10) {
                    controlButton("arrow.clockwise") { loadError = nil; reloadToken += 1 }
                    controlButton("gearshape") { settings.editing = true }
                    Spacer()
                }
            }
            .padding(10)
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = settings.keepAwake }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func controlButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.55))
                .clipShape(Circle())
        }
        .opacity(0.4)
    }
}
