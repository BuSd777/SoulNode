import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        if ServerStatus.shared.isRunning { return }
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- Monolith Boot v3 ---\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            ServerStatus.shared.logs += "Waking up Go Engine...\n"
            // Конвертируем Swift строки в C-строки для Go
            let userPtr = strdup(username)
            let passPtr = strdup(password)
            StartEngine(userPtr, passPtr)
        }
        
        self.checkHealth()
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            attempts += 1
            let url = URL(string: "http://127.0.0.1:5030/api/v0/health")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs += "SERVER: \(str)\n"
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        timer.invalidate()
                    }
                }
            }.resume()
            if attempts > 20 { 
                timer.invalidate()
                ServerStatus.shared.isConnecting = false
            }
        }
    }
}
