import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @ObservedObject var status = ServerStatus.shared
    @AppStorage("isLogged") var isLogged = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.circle.fill").font(.system(size: 80)).foregroundColor(.green)
            Text("SoulNode").font(.largeTitle).bold()

            if status.isConnecting {
                ProgressView("Starting Engine...")
                Text("Device may get warm").font(.caption).foregroundColor(.gray)
                Button("Skip and Debug") { isLogged = true }.padding().foregroundColor(.blue)
            } else {
                VStack {
                    TextField("Username", text: $username).textFieldStyle(RoundedBorderTextFieldStyle()).autocapitalization(.none)
                    SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
                }.padding()

                Button("Start Local Engine") {
                    SlskdLauncher.shared.startServer(username: username, password: password)
                }.buttonStyle(.borderedProminent).accentColor(.green)
                
                Button("Remote Server Mode") { isLogged = true }.padding().foregroundColor(.gray)
            }
        }
    }
}
