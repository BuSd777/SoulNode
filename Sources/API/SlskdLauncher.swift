import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        if ServerStatus.shared.isRunning { return }
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- REAL P2P MODE ---\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let userPtr = strdup(username)
            let passPtr = strdup(password)
            StartEngine(userPtr, passPtr)
        }
        
        checkHealth()
    }

    private func checkHealth() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs = str
                        if str.contains("ONLINE") || str.contains("Listening") {
                            ServerStatus.shared.isRunning = true
                            ServerStatus.shared.isConnecting = false
                        }
                    }
                }
            }.resume()
        }
    }
}
