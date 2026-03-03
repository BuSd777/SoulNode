import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- REAL ENGINE START ---\n"
        
        let fileManager = FileManager.default
        let docsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let execPath = docsPath.appendingPathComponent("engine_bin").path
        
        guard let bundleBin = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "Err: slskd not in bundle\n"
            return
        }

        do {
            // 1. Копируем бинарник в Documents (там можно исполнять)
            if fileManager.fileExists(atPath: execPath) { try fileManager.removeItem(atPath: execPath) }
            try fileManager.copyItem(atPath: bundleBin, toPath: execPath)
            
            // 2. Даем права 755 (rwxr-xr-x)
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try fileManager.setAttributes(attributes, ofItemAtPath: execPath)
            
            ServerStatus.shared.logs += "Binary prepared in Documents\n"
            
            // 3. Запуск
            DispatchQueue.global(qos: .background).async {
                var pid: pid_t = 0
                let args = [execPath, "-user", username, "-pass", password]
                let cArgs = args.map { strdup($0) } + [nil]
                
                let status = posix_spawn(&pid, execPath, nil, nil, cArgs, nil)
                
                DispatchQueue.main.async {
                    if status == 0 {
                        ServerStatus.shared.logs += "ENGINE RUNNING (PID \(pid))\n"
                        self.checkHealth()
                    } else {
                        ServerStatus.shared.logs += "SPAWN ERROR: \(status). Try re-signing.\n"
                        ServerStatus.shared.isConnecting = false
                    }
                }
            }
        } catch {
            ServerStatus.shared.logs += "FS Error: \(error.localizedDescription)\n"
        }
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        ServerStatus.shared.logs += "STATUS: \(str)\n"
                        if str.contains("Online") {
                            ServerStatus.shared.isRunning = true
                            ServerStatus.shared.isConnecting = false
                            timer.invalidate()
                        }
                    }
                }
            }.resume()
            if attempts > 20 { timer.invalidate(); ServerStatus.shared.isConnecting = false }
        }
    }
}
