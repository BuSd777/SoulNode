import Foundation

struct SearchRequest: Codable {
    let id: String
    let searchText: String
}

struct SearchResponse: Codable, Identifiable {
    let id: String
    let username: String
    let locked: Bool
    let fileCount: Int
    let files:[SlskdFile]
}

struct SlskdFile: Codable, Identifiable {
    var id: String { filename }
    let filename: String
    let size: Int64
    let bitRate: Int?
}
