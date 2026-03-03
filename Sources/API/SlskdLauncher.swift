import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        if ServerStatus.shared.isRunning { return }
        
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- IN-PROCESS ENGINE BOOT ---\n"
        
        // Вызываем Go-функцию в фоновом потоке
        DispatchQueue.global(qos: .userInitiated).async {
            ServerStatus.shared.logs += "Calling Go Bridge...\n"
            StartEngine()
        }
        
        // Проверяем, поднялся ли API внутри процесса
        self.checkHealth()
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Internal Ping (\(attempts))...\n"
            
            let url = URL(string: "http://127.0.0.1:5030/api/v0/health")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs += "GO_STATUS: \(str)\n"
                        if str.contains("Connected") || str.contains("Starting") {
                            ServerStatus.shared.isRunning = true
                            ServerStatus.shared.isConnecting = false
                            timer.invalidate()
                        }
                    }
                }
            }.resume()
            
            if attempts > 30 { 
                timer.invalidate()
                ServerStatus.shared.isConnecting = false
                ServerStatus.shared.logs += "Fatal: Internal Bridge Timeout\n"
            }
        }
    }
}
