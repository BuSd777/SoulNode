import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        ServerStatus.shared.isConnecting = true
        ServerStatus.shared.logs = "--- BOOT V2 (TrollStore Optimized) ---\n"
        
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let execPath = docs.appendingPathComponent("slskd_engine").path
        
        guard let bundleBin = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            ServerStatus.shared.logs += "ERR: slskd missing in bundle\n"
            return
        }

        do {
            // Очищаем старое и копируем свежее
            if fileManager.fileExists(atPath: execPath) { try fileManager.removeItem(atPath: execPath) }
            try fileManager.copyItem(atPath: bundleBin, toPath: execPath)
            
            // Ставим права на исполнение
            var attributes = [FileAttributeKey: Any]()
            attributes[.posixPermissions] = 0o755
            try fileManager.setAttributes(attributes, ofItemAtPath: execPath)
            
            ServerStatus.shared.logs += "Binary ready at Documents\n"
            
            DispatchQueue.global(qos: .userInitiated).async {
                var pid: pid_t = 0
                let args = [execPath] // Для начала без аргументов, чтобы исключить ошибки парсинга
                let cArgs = args.map { strdup($0) } + [nil]
                
                // Используем пустой массив окружения
                let env = [UnsafeMutablePointer<CChar>?](arrayLiteral: nil)
                
                let status = posix_spawn(&pid, execPath, nil, nil, UnsafeMutablePointer(mutating: cArgs), UnsafeMutablePointer(mutating: env))
                
                DispatchQueue.main.async {
                    if status == 0 {
                        ServerStatus.shared.logs += "SUCCESS! PID: \(pid)\n"
                        self.checkHealth()
                    } else {
                        let err = String(cString: strerror(status))
                        ServerStatus.shared.logs += "SPAWN ERROR: \(status) (\(err))\n"
                        ServerStatus.shared.isConnecting = false
                    }
                }
                for ptr in cArgs { if let p = ptr { free(p) } }
            }
        } catch {
            ServerStatus.shared.logs += "FS Error: \(error)\n"
            ServerStatus.shared.isConnecting = false
        }
    }

    private func checkHealth() {
        var attempts = 0
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            attempts += 1
            ServerStatus.shared.logs += "Ping Engine (\(attempts))...\n"
            
            URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:5030/api/v0/health")!) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8), str.contains("Engine") {
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
                ServerStatus.shared.logs += "Timeout: Process died or port blocked.\n"
                ServerStatus.shared.isConnecting = false
            }
        }
    }
}
