#!/bin/bash

cd ~/Desktop/SoulNode || { echo "❌ Папка не найдена"; exit 1; }
echo "🔧 Чиним UI и кнопку Connect..."

# 1. СОЗДАЕМ МЕНЕДЖЕР СОСТОЯНИЯ (ServerStatus)
# Это "мост", который передает текст из Go прямо на экран
mkdir -p Sources/Models
cat << 'EOF' > Sources/Models/ServerStatus.swift
import SwiftUI

class ServerStatus: ObservableObject {
    static let shared = ServerStatus()
    
    @Published var logs: String = "Ready to connect..."
    @Published var isRunning: Bool = false
    @Published var isConnecting: Bool = false
}
EOF

# 2. ОБНОВЛЯЕМ LAUNCHER (Добавляем проверку логов)
# Теперь он не просто запускает сервер, но и опрашивает его каждые 0.5 сек
cat << 'EOF' > Sources/API/SlskdLauncher.swift
import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    var timer: Timer?
    
    func startServer(username: String, password: String) {
        // 1. Меняем статус в UI сразу, чтобы кнопка нажалась
        DispatchQueue.main.async {
            ServerStatus.shared.logs = "Starting engine..."
            ServerStatus.shared.isConnecting = true
        }
        
        // 2. Запускаем Go в фоне
        DispatchQueue.global(qos: .userInitiated).async {
            let cUser = (username as NSString).utf8String
            let cPass = (password as NSString).utf8String
            StartEngine(UnsafeMutablePointer(mutating: cUser), UnsafeMutablePointer(mutating: cPass))
        }
        
        // 3. Запускаем "слушателя" (Health Check)
        startHealthCheck()
    }
    
    func startHealthCheck() {
        // Останавливаем старый таймер если был
        timer?.invalidate()
        
        // Каждые 0.5 секунды спрашиваем у Go: "Как дела?"
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.fetchLogs()
            }
        }
    }
    
    func fetchLogs() {
        guard let url = URL(string: "http://127.0.0.1:5031/api/v0/health") else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1.0)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data, let logText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    ServerStatus.shared.logs = logText
                    
                    // Если в логах есть "ONLINE", переключаем экран
                    if logText.contains("ONLINE") {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                    }
                }
            }
        }.resume()
    }
}
EOF

# 3. ОБНОВЛЯЕМ ЭКРАН ВХОДА (LoginView)
# Привязываем кнопку к новому статусу
cat << 'EOF' > Sources/Views/LoginView.swift
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
EOF

# 4. ОТПРАВЛЯЕМ
echo "🚀 Фиксим кнопку..."
git add .
git commit -m "Fix UI Button and Logs polling"
git push origin main
echo "✅ ГОТОВО! Пересобирай и жми кнопку."
