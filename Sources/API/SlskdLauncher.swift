import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configPath = docs.appendingPathComponent("slskd.yml").path
        
        let configContent = "is_headless: true\nsoulseek:\n  username: \(username)\n  password: \(password)\nflags:\n  no_auth: true"
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "CRITICAL: Binary slskd not found in App Bundle!\n"
            ServerStatus.shared.isConnecting = false
            return
        }

        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [binaryPath, "--config", configPath]
            let cArgs = args.map { strdup($0) } + [nil]
            
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, nil)
            
            DispatchQueue.main.async {
                if status == 0 {
                    ServerStatus.shared.logs += "Process spawned. PID: \(pid). Waiting for port...\n"
                    self.checkPort()
                } else {
                    let errorDesc = String(cString: strerror(status))
                    ServerStatus.shared.logs += "Launch FAILED: \(errorDesc) (Code: \(status))\n"
                    ServerStatus.shared.logs += "Hint: iOS cannot run Linux ELF binaries. Need Mach-O.\n"
                    ServerStatus.shared.isConnecting = false
                }
            }
            for ptr in cArgs { if let p = ptr { free(p) } }
        }
    }

    private func checkPort() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            attempts += 1
            let task = URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { _, res, _ in
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    DispatchQueue.main.async {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        ServerStatus.shared.logs += "SERVER ONLINE!\n"
                        timer.invalidate()
                    }
                }
            }
            task.resume()
            if attempts > 10 {
                DispatchQueue.main.async {
                    ServerStatus.shared.logs += "Port 5030 timeout. Checking if binary crashed...\n"
                    ServerStatus.shared.isConnecting = false
                    timer.invalidate()
                }
            }
        }
    }
}
