import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @AppStorage("serverAddr") var serverAddr = "127.0.0.1"
    @AppStorage("isLogged") var isLogged = false
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        Form {
            Section("Local Server (Internal)") {
                TextField("Username", text: $username).autocapitalization(.none)
                SecureField("Password", text: $password)
                Button("Start & Login") {
                    SlskdLauncher.shared.startServer(username: username, password: password)
                }
                .disabled(status.isConnecting)
                if status.isConnecting { ProgressView() }
            }

            Section("Existing Server (External)") {
                TextField("Server IP / Domain", text: $serverAddr)
                Button("Connect to this server") {
                    isLogged = true
                }
            }
            
            Section {
                NavigationLink("View detailed logs", destination: ServerView())
            }
        }
        .navigationTitle("SoulNode Setup")
        .onReceive(status.$isRunning) { running in if running { isLogged = true } }
    }
}
