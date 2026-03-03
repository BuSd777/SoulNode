import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- Initialization ---\n"
        
        // Пытаемся найти бинарник во всех папках бандла
        let bundlePath = Bundle.main.bundlePath
        let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) 
            ?? "\(bundlePath)/slskd"
            ?? "\(bundlePath)/Resources/slskd"

        ServerStatus.shared.logs += "Checking binary at: \(binaryPath)\n"
        
        if FileManager.default.fileExists(atPath: binaryPath) {
            ServerStatus.shared.logs += "SUCCESS: Binary found. Spawning...\n"
            launch(path: binaryPath)
        } else {
            ServerStatus.shared.logs += "ERROR: slskd not found in bundle. Listing files:\n"
            let files = (try? FileManager.default.contentsOfDirectory(atPath: bundlePath)) ?? []
            ServerStatus.shared.logs += files.joined(separator: ", ") + "\n"
            ServerStatus.shared.isConnecting = false
        }
    }

    private func launch(path: String) {
        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [path]
            let cArgs = args.map { strdup($0) } + [nil]
            let status = posix_spawn(&pid, path, nil, nil, cArgs, nil)
            
            DispatchQueue.main.async {
                if status == 0 {
                    ServerStatus.shared.logs += "Process running (PID \(pid)). Pinging port 5030...\n"
                    self.checkPort()
                } else {
                    ServerStatus.shared.logs += "FAILED to spawn. Error code: \(status)\n"
                    ServerStatus.shared.isConnecting = false
                }
            }
        }
    }

    private func checkPort() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { _, res, _ in
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    DispatchQueue.main.async {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                        ServerStatus.shared.logs += "SERVER IS ONLINE!\n"
                        timer.invalidate()
                    }
                }
            }.resume()
            if attempts > 10 { 
                timer.invalidate()
                ServerStatus.shared.logs += "Timeout: Server not responding.\n"
                ServerStatus.shared.isConnecting = false 
            }
        }
    }
}
