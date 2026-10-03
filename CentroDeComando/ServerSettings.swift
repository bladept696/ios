import SwiftUI

final class ServerSettings: ObservableObject {
    @Published var address: String {
        didSet { UserDefaults.standard.set(address, forKey: "serverAddress") }
    }
    @Published var keepAwake: Bool {
        didSet { UserDefaults.standard.set(keepAwake, forKey: "keepAwake") }
    }
    @Published var editing: Bool

    init() {
        let saved = UserDefaults.standard.string(forKey: "serverAddress") ?? ""
        address = saved
        keepAwake = UserDefaults.standard.object(forKey: "keepAwake") as? Bool ?? true
        editing = saved.isEmpty
    }

    var url: URL? { Self.normalize(address) }

    /// Aceita "192.168.1.50", "192.168.1.50:8765", "http://x:8765" ou "https://x:8765".
    /// Sem esquema => http:// e porta 8765 (a porta por omissão do app.py).
    static func normalize(_ raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        let hadScheme = s.contains("://")
        if !hadScheme { s = "http://" + s }
        guard var c = URLComponents(string: s), let host = c.host, !host.isEmpty else { return nil }
        if c.port == nil && !hadScheme { c.port = 8765 }
        if c.path.isEmpty { c.path = "/" }
        return c.url
    }
}
