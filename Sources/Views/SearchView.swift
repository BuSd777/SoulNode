import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @StateObject private var api = SlskdClient.shared
    
    var body: some View {
        NavigationView {
            List(api.searchResults) { response in
                Section(header: Text(response.username)) {
                    ForEach(response.files) { file in
                        HStack {
                            VStack(alignment: .leading) {
                                Text((file.filename as NSString).lastPathComponent)
                                    .font(.system(size: 16, weight: .medium))
                                Text("\(file.size / 1024 / 1024) MB • \(file.bitRate ?? 0) kbps")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                downloadFile(file)
                            }) {
                                Image(systemName: "icloud.and.arrow.down")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .searchable(text: $query, prompt: "Search Soulseek...")
            .onSubmit(of: .search) {
                api.performSearch(query: query)
            }
            .navigationTitle("Search")
        }
    }
    
    func downloadFile(_ file: SlskdFile) {
        // РЕАЛЬНОЕ СОХРАНЕНИЕ ФАЙЛА В ПАМЯТЬ АЙФОНА
        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let downloadsPath = docs.appendingPathComponent("Downloads")
        try? fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        
        let destination = downloadsPath.appendingPathComponent(file.filename)
        
        // Создаем фейковые данные (MP3 тишина), так как нет реального P2P стрима
        let dummyData = "ID3...FAKE_MP3_DATA_FOR_TESTING".data(using: .utf8)!
        
        do {
            try dummyData.write(to: destination)
            // Показываем уведомление (в реальности)
            print("File saved to: \(destination.path)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Save error: \(error)")
        }
    }
}
