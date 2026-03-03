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
                            Image(systemName: "music.note")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text((file.filename as NSString).lastPathComponent)
                                    .font(.body)
                                Text("\(file.size / 1024 / 1024) MB • \(file.bitRate ?? 0) kbps")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                // Логика скачивания будет здесь
                                print("Downloading \(file.filename)")
                            }) {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .searchable(text: $query, prompt: "Artists, albums, songs...")
            .onSubmit(of: .search) {
                api.performSearch(query: query)
            }
            .navigationTitle("Search")
        }
    }
}
