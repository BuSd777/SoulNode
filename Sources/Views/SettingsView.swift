import SwiftUI

struct SettingsView: View {
    // Используем ТЕ ЖЕ ключи, что и на экране входа
    @AppStorage("slskUsername") var user = ""
    @AppStorage("slskPassword") var pass = ""
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Soulseek Credentials")) {
                    TextField("Username", text: $user)
                        .autocapitalization(.none)
                    SecureField("Password", text: $pass)
                }

                Section(header: Text("Storage")) {
                    Text("Downloads location:")
                    Text("Files App -> On My iPhone -> SoulNode")
                        .font(.caption).foregroundColor(.gray)
                }

                Section(header: Text("Engine Status")) {
                    Text(status.logs)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(5)
                    
                    if status.isRunning {
                        Text("🟢 Engine Online").foregroundColor(.green)
                    } else {
                        Text("🔴 Engine Offline").foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
