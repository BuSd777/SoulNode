import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer() {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- Booting SoulNode ---\n"
        
        // Это единственный правильный способ найти ресурс в iOS
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "CRITICAL: Binary 'slskd' still missing in bundle!\n"
            let path = Bundle.main.bundlePath
            let content = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
            ServerStatus.shared.logs += "Files found: \(content.joined(separator: ", "))\n"
            ServerStatus.shared.isConnecting = false
            return
        }

        ServerStatus.shared.logs += "Binary found at: \(binaryPath)\n"
        
        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [binaryPath]
            let cArgs = args.map { strdup($0) } + [nil]
            
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, nil)
            
            DispatchQueue.main.async {
                if status == 0 {
                    ServerStatus.shared.logs += "Engine started (PID \(pid))\n"
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
            URLSession.shared.dataTask(with: url) { data, res, _ in
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
                ServerStatus.shared.logs += "Timeout: Engine not responding.\n"
                ServerStatus.shared.isConnecting = false
            }
        }
    }
}
