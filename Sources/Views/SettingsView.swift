import SwiftUI

struct SettingsView: View {
    @AppStorage("slskUsername") var user = ""
    @AppStorage("slskPassword") var pass = ""
    @AppStorage("serverPort") var port = "5030"
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Soulseek Username", text: $user)
                        .autocapitalization(.none)
                    SecureField("Soulseek Password", text: $pass)
                }

                Section(header: Text("Engine Configuration")) {
                    TextField("Internal Port", text: $port)
                        .keyboardType(.numberPad)
                    
                    if status.isRunning {
                        Button("Stop Engine (Restart App)") {
                            // В мобильных ОС проще перезапустить приложение
                        }.foregroundColor(.red)
                    } else {
                        Button("Start Internal Engine") {
                            SlskdLauncher.shared.startServer(username: user, password: pass)
                        }
                        .foregroundColor(.green)
                        .disabled(status.isConnecting)
                    }
                }

                Section(header: Text("Debug Info")) {
                    Text("Status: \(status.isRunning ? "ONLINE" : "OFFLINE")")
                    Text("Architecture: arm64 (iOS)")
                }
                
                Section {
                    Button("Reset All Settings") {
                        user = ""; pass = ""; port = "5030"
                        status.isRunning = false
                        status.logs = "Settings reseted.\n"
                    }.foregroundColor(.red)
                }
            }
            .navigationTitle("Total Settings")
        }
    }
}
