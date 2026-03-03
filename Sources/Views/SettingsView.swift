import SwiftUI

struct SettingsView: View {
    @AppStorage("slskUsername") var user = ""
    @AppStorage("slskPassword") var pass = ""
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Network Status")) {
                    Text(status.logs)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(status.isRunning ? .green : .orange)
                        .listRowBackground(Color.black)
                    
                    if status.isRunning {
                        Text("✅ Connected via Direct IP")
                    } else {
                        Text("❌ Offline / Connecting...")
                    }
                }

                Section(header: Text("Control Panel")) {
                    Button(action: {
                        SlskdLauncher.shared.restartServer()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Force Reconnect")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        // Просто сбрасываем статус, реальный стоп через kill app
                        status.logs = "Stopped. Restart App to connect again."
                        status.isRunning = false
                    }) {
                        HStack {
                            Image(systemName: "power")
                            Text("Stop Engine")
                        }
                        .foregroundColor(.red)
                    }
                }

                Section(header: Text("Credentials")) {
                    TextField("Username", text: $user).autocapitalization(.none)
                    SecureField("Password", text: $pass)
                }
            }
            .navigationTitle("SoulNode Config")
        }
    }
}
