import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs += "--- Starting Local Initialization ---\n"
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configPath = docs.appendingPathComponent("slskd.yml").path
        
        ServerStatus.shared.logs += "Creating config at: \(configPath)\n"
        let configContent = "is_headless: true\nsoulseek:\n  username: \(username)\n  password: \(password)\nflags:\n  no_auth: true"
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        // Ищем бинарник более тщательно
        ServerStatus.shared.logs += "Searching for slskd binary...\n"
        if let bPath = Bundle.main.path(forResource: "slskd", ofType: nil) {
             ServerStatus.shared.logs += "FOUND: \(bPath)\n"
             launch(binaryPath: bPath, configPath: configPath)
        } else {
             ServerStatus.shared.logs += "CRITICAL ERROR: Binary 'slskd' not found in App Bundle. Check project.yml\n"
             ServerStatus.shared.isConnecting = false
        }
    }

    private func launch(binaryPath: String, configPath: String) {
        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [binaryPath, "--config", configPath]
            let cArgs = args.map { strdup($0) } + [nil]
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, nil)
            
            DispatchQueue.main.async {
                if status == 0 {
                    ServerStatus.shared.logs += "Spawned! PID: \(pid). Checking health...\n"
                    self.checkHealth()
                } else {
                    ServerStatus.shared.logs += "Spawn FAILED. Code: \(status)\n"
                    ServerStatus.shared.isConnecting = false
                }
            }
            for ptr in cArgs { if let p = ptr { free(p) } }
        }
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Ping 127.0.0.1:5030... (\(attempts))\n"
            URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { _, res, _ in
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    DispatchQueue.main.async {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        ServerStatus.shared.logs += "DONE: Server is Online!\n"
                        timer.invalidate()
                    }
                }
            }.resume()
            if attempts > 8 { timer.invalidate(); ServerStatus.shared.isConnecting = false }
        }
    }
}
