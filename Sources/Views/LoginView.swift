import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @ObservedObject var status = ServerStatus.shared
    @AppStorage("isLogged") var isLogged = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.fill").font(.system(size: 60)).foregroundColor(.green)
            Text("SoulNode Config").font(.title).bold()

            if status.isConnecting {
                ProgressView("Starting Engine...")
                Text("This may take a minute on older devices").font(.caption).foregroundColor(.gray)
            } else {
                VStack {
                    TextField("Username", text: $username).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
                    SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
                }.padding()

                Button("Initialize Server") {
                    SlskdLauncher.shared.startServer(username: username, password: password)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onReceive(status.$isRunning) { running in
            if running { isLogged = true }
        }
    }
}
