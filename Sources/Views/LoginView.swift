import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    
    // Подключаемся к нашему "Мосту" данных
    @ObservedObject var status = ServerStatus.shared
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("SoulNode Network")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer().frame(height: 30)
                
                // Поля ввода
                VStack(alignment: .leading) {
                    Text("Username").foregroundColor(.gray)
                    TextField("", text: $username)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .autocapitalization(.none)
                    
                    Text("Password").foregroundColor(.gray)
                    SecureField("", text: $password)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                }
                .padding(.horizontal)
                
                // КНОПКА
                Button(action: {
                    // Скрываем клавиатуру
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    // ЗАПУСК
                    SlskdLauncher.shared.startServer(username: username, password: password)
                }) {
                    HStack {
                        if status.isConnecting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Connecting...")
                        } else {
                            Text("Connect Engine")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(status.isConnecting) // Блокируем, чтобы не нажимали 100 раз
                
                // ЛОГИ (КОНСОЛЬ)
                ScrollView {
                    Text(status.logs)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 150)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}
