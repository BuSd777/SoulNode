import SwiftUI

struct LoginView: View {
    // Привязываем к тем же ключам UserDefaults
    @AppStorage("slskUsername") var user = ""
    @AppStorage("slskPassword") var pass = ""
    @AppStorage("isLogged") var isLogged = false
    @ObservedObject var status = ServerStatus.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network").font(.system(size: 80)).foregroundColor(.cyan)
            Text("SoulNode Network").font(.largeTitle).bold()
            
            VStack(alignment: .leading) {
                Text("Username").font(.caption).foregroundColor(.gray)
                TextField("Soulseek User", text: $user)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                Text("Password").font(.caption).foregroundColor(.gray)
                SecureField("Soulseek Pass", text: $pass)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()

            Button(action: {
                SlskdLauncher.shared.startServer(username: user, password: pass)
            }) {
                HStack {
                    if status.isConnecting { ProgressView().tint(.black) }
                    Text(status.isConnecting ? "Connecting..." : "Connect Engine")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(user.isEmpty ? Color.gray : Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(user.isEmpty || status.isConnecting)
            .padding(.horizontal)

            // Логи
            ScrollView {
                Text(status.logs)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .padding()

            if status.isRunning {
                Button("ENTER SYSTEM") { isLogged = true }
                    .font(.headline)
                    .padding()
                    .foregroundColor(.green)
            }
        }
    }
}
