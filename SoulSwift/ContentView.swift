import SwiftUI
struct ContentView: View {
    @StateObject var engine = EngineWrapper()
    @State private var query = ""
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search...", text: $query).textFieldStyle(.roundedBorder).padding()
                Button("Search") { engine.search(query: query) }
                Text(engine.status).font(.caption).foregroundColor(.gray)
                List(engine.results) { item in
                    VStack(alignment: .leading) {
                        Text(item.filename).bold()
                        Text(item.user).font(.caption).foregroundColor(.blue)
                    }
                }
            }.navigationTitle("SoulNode")
        }.preferredColorScheme(.dark)
        .onAppear { BackgroundService.shared.keepAlive(); engine.startEngine(username: "user", pass: "pass") }
    }
}
