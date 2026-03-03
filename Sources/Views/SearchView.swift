import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @StateObject private var api = SlskdClient.shared
    @State private var dlStatus = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if !dlStatus.isEmpty {
                    Text(dlStatus).font(.caption).padding(4).background(.yellow)
                }
                
                if api.searchResults.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "network.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No results yet.")
                            .foregroundColor(.gray)
                        Text("Soulseek requires open ports for results.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List(api.searchResults) { response in
                        Section(header: Text("User: \(response.username)")) {
                            ForEach(response.files) { file in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(file.filename)
                                            .font(.system(size: 14))
                                            .lineLimit(1)
                                        HStack {
                                            Text("\(file.bitRate) kbps")
                                                .foregroundColor(.green)
                                            Text("•")
                                            Text(formatSize(file.size))
                                        }
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: { dlStatus = "P2P Transfer not supported in passive mode" }) {
                                        Image(systemName: "arrow.down.circle")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search Real Network...")
            .onSubmit(of: .search) { api.performSearch(query: query) }
            .navigationTitle("SoulNode")
        }
    }
    
    func formatSize(_ size: Int64) -> String {
        let mb = Double(size) / 1024 / 1024
        return String(format: "%.1f MB", mb)
    }
}
