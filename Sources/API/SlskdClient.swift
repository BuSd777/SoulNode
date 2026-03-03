import Foundation

class SlskdClient: ObservableObject {
    static let shared = SlskdClient()
    @Published var searchResults: [SearchResponse] = []
    
    let baseURL = "http://127.0.0.1:5030/api/v0"

    func performSearch(query: String) {
        let searchId = UUID().uuidString
        guard let url = URL(string: "\(baseURL)/searches") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SearchRequest(id: searchId, searchText: query)
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            self.fetchResults(searchId: searchId)
        }.resume()
    }
    
    func fetchResults(searchId: String) {
        guard let url = URL(string: "\(baseURL)/searches/\(searchId)/responses") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    let results = try JSONDecoder().decode([SearchResponse].self, from: data)
                    DispatchQueue.main.async {
                        self.searchResults = results
                    }
                } catch {
                    print("JSON error: \(error)")
                }
            }
        }.resume()
    }
}
