import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @StateObject private var api = SlskdClient.shared
    @State private var lastSaved = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if !lastSaved.isEmpty {
                    Text("Saved: \(lastSaved)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(5)
                        .background(Color.black)
                }
                
                List(api.searchResults) { response in
                    Section(header: Text(response.username)) {
                        ForEach(response.files) { file in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text((file.filename as NSString).lastPathComponent)
                                        .font(.system(size: 16))
                                    Text("\(file.size / 1024 / 1024) MB • \(file.bitRate ?? 0) kbps")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: { downloadFile(file) }) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .searchable(text: $query, prompt: "Search...")
            .onSubmit(of: .search) { api.performSearch(query: query) }
            .navigationTitle("Search")
        }
    }
    
    func downloadFile(_ file: SlskdFile) {
        let fileManager = FileManager.default
        // Путь: On My iPhone / SoulNode / Downloads
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let downloadsDir = docs.appendingPathComponent("Downloads")
        
        try? fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        let fileURL = downloadsDir.appendingPathComponent(file.filename)
        let dummyContent = "SoulNode Download Test: \(file.filename)\nSize: \(file.size)".data(using: .utf8)!
        
        do {
            try dummyContent.write(to: fileURL)
            lastSaved = file.filename
            // Вибрация для подтверждения
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            lastSaved = "Error: \(error.localizedDescription)"
        }
    }
}
