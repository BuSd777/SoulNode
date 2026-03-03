import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @AppStorage("isLogged") var isLogged = false
    @AppStorage("slskUsername") var savedUser = ""

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(red: 0.25, green: 0.8, blue: 0.65))
            
            Text("SoulNode Setup")
                .font(.largeTitle).bold()

            VStack(alignment: .leading, spacing: 15) {
                TextField("Soulseek Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Soulseek Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            Button(action: {
                if !username.isEmpty && !password.isEmpty {
                    savedUser = username
                    SlskdLauncher.shared.startServer(username: username, password: password)
                    // Даем серверу пару секунд на запуск перед входом
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLogged = true
                    }
                }
            }) {
                Text("Start Local Server")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.25, green: 0.8, blue: 0.65))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Text("Make sure you are using TrollStore or a Jailbroken device to allow binary execution.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
