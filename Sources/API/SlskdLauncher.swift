import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        let port = UserDefaults.standard.string(forKey: "serverPort") ?? "5030"
        
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs += "--- MANUAL BOOT INITIATED ---\n"
        ServerStatus.shared.logs += "Target Port: \(port)\n"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let portPtr = strdup(port)
            StartEngine(portPtr)
        }
        
        self.checkHealth(port: port)
    }

    private func checkHealth(port: String) {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Ping localhost:\(port) (Attempt \(attempts))\n"
            
            let url = URL(string: "http://127.0.0.1:\(port)/api/v0/health")!
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs += "GOT RESPONSE: \(str)\n"
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        timer.invalidate()
                    }
                }
            }.resume()
            
            if attempts > 25 { 
                timer.invalidate()
                ServerStatus.shared.isConnecting = false
                ServerStatus.shared.logs += "TIMEOUT: Engine not responding on port \(port)\n"
            }
        }
    }
}
