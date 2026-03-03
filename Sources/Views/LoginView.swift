import SwiftUI

struct LoginView: View {
    @State private var user = ""
    @State private var pass = ""
    @ObservedObject var status = ServerStatus.shared
    @AppStorage("isLogged") var isLogged = false

    var body: some View {
        VStack {
            Text("SoulNode Go").font(.largeTitle).bold().padding(.top)
            
            VStack(spacing: 15) {
                TextField("Username", text: $user)
                    .textFieldStyle(.roundedBorder).autocapitalization(.none)
                SecureField("Password", text: $pass)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: { 
                    SlskdLauncher.shared.startServer(username: user, password: pass) 
                }) {
                    if status.isConnecting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start & Login").bold()
                    }
                }
                .frame(maxWidth: .infinity).padding().background(.blue).foregroundColor(.white).cornerRadius(10)
                .disabled(status.isConnecting || user.isEmpty)
            }.padding()

            ScrollView {
                Text(status.logs)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 150).background(.black).padding()
            
            if status.isRunning {
                Button("Enter App") { isLogged = true }
                    .padding().frame(maxWidth: .infinity).background(.green).foregroundColor(.white).cornerRadius(10).padding()
            }
        }
    }
}
