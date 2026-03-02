import SwiftUI

struct ContentView: View {
    @StateObject var engine = EngineWrapper()
    @State private var query = ""
    @State private var user = ""
    @State private var pass = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
                    // Экран логина
                    Form {
                        Section(header: Text("Soulseek Login")) {
                            TextField("Username", text: $user)
                            SecureField("Password", text: $pass)
                            Button("Connect") {
                                engine.startEngine(username: user, pass: pass)
                                isLoggedIn = true
                            }
                        }
                    }
                } else {
                    // Экран поиска
                    HStack {
                        TextField("Search tracks...", text: $query)
                            .textFieldStyle(.roundedBorder)
                        Button("Go") { engine.search(query: query) }
                    }.padding()
                    
                    Text(engine.status).font(.system(size: 10, design: .monospaced)).padding(.horizontal)
                    
                    List(engine.results) { item in
                        VStack(alignment: .leading) {
                            Text(item.filename).font(.subheadline).bold().lineLimit(2)
                            HStack {
                                Text(item.user).foregroundColor(.blue)
                                Spacer()
                                Text("\(item.size / 1024 / 1024) MB").font(.caption).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("SoulNode P2P")
            .preferredColorScheme(.dark)
        }
        .onAppear {
            BackgroundService.shared.keepAlive()
        }
    }
}
