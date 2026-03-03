import SwiftUI

struct SettingsView: View {
    @AppStorage("slskUsername") var user = ""
    @AppStorage("slskPassword") var pass = ""
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Server Control")) {
                    Text("Current Status:")
                    Text(status.logs)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(status.isRunning ? .green : .orange)
                        .listRowBackground(Color.black)
                    
                    Button(action: {
                        SlskdLauncher.shared.restartServer()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                            Text("FORCE RECONNECT")
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    
                    Button(action: {
                        // Для полной остановки на iOS проще убить приложение,
                        // но мы можем просто разорвать связь
                        SlskdLauncher.shared.restartServer() 
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("RESTART NETWORK STACK")
                        }
                        .foregroundColor(.red)
                    }
                }

                Section(header: Text("Credentials")) {
                    TextField("Username", text: $user).autocapitalization(.none)
                    SecureField("Password", text: $pass)
                }
            }
            .navigationTitle("System Control")
        }
    }
}
