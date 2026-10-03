import SwiftUI

struct SetupView: View {
    @EnvironmentObject var settings: ServerSettings
    @State private var input = ""
    @State private var status: String?
    @State private var testing = false

    private var valid: Bool { ServerSettings.normalize(input) != nil }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Servidor"),
                    footer: Text("IP (ou nome Tailscale) do PC/Raspberry onde corre o app.py. Exemplo: 192.168.25.10 — a porta 8765 é assumida. Se ativaste HTTPS no painel, escreve https://IP:8765.")
                ) {
                    TextField("192.168.25.10", text: $input)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: test) {
                        HStack {
                            Text("Testar ligação")
                            if testing { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!valid || testing)

                    if let status = status {
                        Text(status).font(.footnote)
                    }
                }

                Section(footer: Text("Impede o ecrã de bloquear enquanto o painel está aberto.")) {
                    Toggle("Manter ecrã sempre ligado", isOn: $settings.keepAwake)
                }

                Section {
                    Button("Guardar e abrir painel") {
                        settings.address = input.trimmingCharacters(in: .whitespacesAndNewlines)
                        settings.editing = false
                    }
                    .disabled(!valid)
                }
            }
            .navigationTitle("Centro de Comando")
            .toolbar {
                if settings.url != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancelar") { settings.editing = false }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { input = settings.address }
    }

    private func test() {
        guard let base = ServerSettings.normalize(input),
              let url = URL(string: "api/version", relativeTo: base) else { return }
        testing = true
        status = nil
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: cfg, delegate: TrustDelegate(host: base.host ?? ""), delegateQueue: nil)
        Task { @MainActor in
            do {
                let (_, resp) = try await session.data(from: url)
                if let http = resp as? HTTPURLResponse {
                    status = http.statusCode == 200
                        ? "✅ Ligado ao servidor (HTTP 200)"
                        : "⚠️ O servidor respondeu com HTTP \(http.statusCode)"
                }
            } catch {
                status = "❌ Sem ligação: \(error.localizedDescription)"
            }
            testing = false
        }
    }
}

final class TrustDelegate: NSObject, URLSessionDelegate {
    let host: String
    init(host: String) { self.host = host }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let ps = challenge.protectionSpace
        if ps.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           ps.host == host, let trust = ps.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
