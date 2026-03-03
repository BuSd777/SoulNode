import Foundation

class SlskdClient: ObservableObject {
    static let shared = SlskdClient()
    @Published var searchResults: [SearchResponse] = []
    
    let baseURL = "http://127.0.0.1:5030/api/v0"

    func performSearch(query: String) {
        guard let url = URL(string: "\(baseURL)/searches") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["searchText": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }
}
