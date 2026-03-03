import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @StateObject private var api = SlskdClient.shared
    @ObservedObject var status = ServerStatus.shared
    
    var body: some View {
        NavigationView {
            VStack {
                if !status.isRunning {
                    VStack {
                        ProgressView()
                        Text("Waiting for Internal Server...")
                            .foregroundColor(.gray)
                            .padding()
                    }
                } else {
                    List(api.searchResults) { response in
                        Section(header: Text(response.username)) {
                            ForEach(response.files) { file in
                                VStack(alignment: .leading) {
                                    Text((file.filename as NSString).lastPathComponent)
                                    Text("\(file.size / 1024 / 1024) MB").font(.caption).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Eminem, etc...")
            .onSubmit(of: .search) {
                if status.isRunning { api.performSearch(query: query) }
            }
            .navigationTitle("Search")
        }
    }
}
