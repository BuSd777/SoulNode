import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    private var childPid: pid_t = 0

    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configPath = docs.appendingPathComponent("slskd.yml").path
        
        let configContent = """
        is_headless: true
        soulseek:
          username: \(username)
          password: \(password)
        directories:
          download: \(docs.appendingPathComponent("Downloads").path)
        flags:
          no_auth: true
        """
        
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "ERROR: Binary not found!\n"
            return
        }

        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [binaryPath, "--config", configPath]
            let cArgs = args.map { strdup($0) } + [nil]
            
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, nil)
            
            if status == 0 {
                self.childPid = pid
                DispatchQueue.main.async {
                    ServerStatus.shared.logs += "Server process spawned (PID \(pid))\n"
                    self.checkPort()
                }
            } else {
                DispatchQueue.main.async {
                    ServerStatus.shared.logs += "Launch failed code: \(status)\n"
                    ServerStatus.shared.isConnecting = false
                }
            }
            
            for ptr in cArgs { if let p = ptr { free(p) } }
        }
    }

    private func checkPort() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Checking port 5030 (Attempt \(attempts))...\n"
            
            let socket = URL(string: "http://127.0.0.1:5030/api/v0/health")!
            let task = URLSession.shared.dataTask(with: socket) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        ServerStatus.shared.logs += "SUCCESS: Server is Online!\n"
                        timer.invalidate()
                    }
                }
            }
            task.resume()
            
            if attempts > 15 {
                ServerStatus.shared.logs += "ERROR: Timeout starting server\n"
                ServerStatus.shared.isConnecting = false
                timer.invalidate()
            }
        }
    }
}
