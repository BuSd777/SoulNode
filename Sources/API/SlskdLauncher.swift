import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- Booting SoulNode Go ---\n"
        ServerStatus.shared.logs += "User: \(username)\n"
        
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "CRITICAL: Binary 'slskd' missing!\n"
            ServerStatus.shared.isConnecting = false
            return
        }

        ServerStatus.shared.logs += "Binary found. Launching...\n"
        
        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            // Передаем аргументы в Go-движок (пока он их просто игнорит, но связь есть)
            let args = [binaryPath, "-user", username, "-pass", password]
            let cArgs = args.map { strdup($0) } + [nil]
            
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, nil)
            
            DispatchQueue.main.async {
                if status == 0 {
                    ServerStatus.shared.logs += "Process started. PID: \(pid)\n"
                    self.checkHealth()
                } else {
                    ServerStatus.shared.logs += "Spawn failed: \(status)\n"
                    ServerStatus.shared.isConnecting = false
                }
            }
            for ptr in cArgs { if let p = ptr { free(p) } }
        }
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Ping engine... (\(attempts))\n"
            
            let url = URL(string: "http://127.0.0.1:5030/api/v0/health")!
            URLSession.shared.dataTask(with: url) { _, res, _ in
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    DispatchQueue.main.async {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        ServerStatus.shared.logs += "--- ENGINE ONLINE ---\n"
                        timer.invalidate()
                    }
                }
            }.resume()
            
            if attempts > 15 { 
                timer.invalidate()
                ServerStatus.shared.logs += "Timeout: No response from 5030.\n"
                ServerStatus.shared.isConnecting = false
            }
        }
    }
}
