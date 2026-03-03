import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let userPtr = strdup(username)
            let passPtr = strdup(password)
            StartEngine(userPtr, passPtr)
            free(userPtr)
            free(passPtr)
        }
        
        startHealthCheck()
    }
    
    func restartServer() {
        ServerStatus.shared.logs += "Manual Restart Requested...\n"
        DispatchQueue.global(qos: .userInitiated).async {
            RestartEngine()
        }
    }

    private func startHealthCheck() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let url = URL(string: "http://127.0.0.1:5030/api/v0/health")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs = str // Прямой лог из Go
                        ServerStatus.shared.isRunning = str.contains("Online")
                        ServerStatus.shared.isConnecting = !str.contains("Online") && !str.contains("Error")
                    }
                }
            }.resume()
        }
    }
}
