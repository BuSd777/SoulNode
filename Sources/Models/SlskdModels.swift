import Foundation

struct SearchRequest: Codable {
    let id: String
    let searchText: String
}

struct SearchResponse: Codable, Identifiable {
    let id: String
    let username: String
    let fileCount: Int
    let files: [SlskdFile]
}

struct SlskdFile: Codable, Identifiable {
    var id: String { filename }
    let filename: String
    let size: Int64
    let bitRate: Int?
}

// Новая модель для статуса сервера
class ServerStatus: ObservableObject {
    static let shared = ServerStatus()
    @Published var isRunning = false
    @Published var logs = "Waiting for start...\n"
    @Published var isConnecting = false
}
