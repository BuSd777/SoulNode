import Foundation

class SlskdClient: ObservableObject {
    static let shared = SlskdClient()
    @Published var searchResults: [SearchResponse] = []
    private var timer: Timer?

    let baseURL = "http://127.0.0.1:5030/api/v0"

    func performSearch(query: String) {
        self.searchResults = [] // Очищаем старое
        let searchId = UUID().uuidString.lowercased()
        guard let url = URL(string: "\(baseURL)/searches") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["id": searchId, "searchText": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Начинаем опрашивать движок на наличие результатов
            DispatchQueue.main.async {
                self.startPolling(id: searchId)
            }
        }.resume()
    }
    
    private func startPolling(id: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let url = URL(string: "\(self.baseURL)/searches/\(id)/responses")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let results = try? JSONDecoder().decode([SearchResponse].self, from: data) {
                    if !results.isEmpty {
                        DispatchQueue.main.async {
                            self.searchResults = results
                            self.timer?.invalidate()
                        }
                    }
                }
            }.resume()
        }
    }
}
