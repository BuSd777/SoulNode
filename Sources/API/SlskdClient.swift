import Foundation

class SlskdClient: ObservableObject {
    static let shared = SlskdClient()
    @Published var searchResults: [SearchResponse] =[]
    
    // В будущем тут будет логика запуска бинарника для TrollStore
    let baseURL = "http://127.0.0.1:5030/api/v0" // Для локального
    let apiKey = "ТВОЙ_АПИ_КЛЮЧ_ЕСЛИ_ЕСТЬ"

    func performSearch(query: String) {
        let searchId = UUID().uuidString
        let url = URL(string: "\(baseURL)/searches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SearchRequest(id: searchId, searchText: query)
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Search Error: \(error.localizedDescription)")
                return
            }
            // После создания поиска, в реальности нужно опрашивать (poll) результаты GET запросом
            // Здесь я показываю скелет для получения
            self.fetchResults(searchId: searchId)
        }.resume()
    }
    
    func fetchResults(searchId: String) {
        let url = URL(string: "\(baseURL)/searches/\(searchId)/responses")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                do {
                    let results = try JSONDecoder().decode([SearchResponse].self, from: data)
                    DispatchQueue.main.async {
                        self.searchResults = results
                    }
                } catch {
                    print("JSON Parse error: \(error)")
                }
            }
        }.resume()
    }
}
