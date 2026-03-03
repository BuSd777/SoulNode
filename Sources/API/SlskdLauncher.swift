import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    private var childPid: pid_t = 0

    func startServer(username: String, password: String) {
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
          incomplete: \(docs.appendingPathComponent("Incomplete").path)
        flags:
          no_auth: true
        """
        
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        try? fileManager.createDirectory(at: docs.appendingPathComponent("Downloads"), withIntermediateDirectories: true)
        
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            print("Binary slskd not found in bundle")
            return
        }

        // Используем posix_spawn вместо Process для совместимости с iOS
        DispatchQueue.global(qos: .background).async {
            var pid: pid_t = 0
            let args = [binaryPath, "--config", configPath]
            
            // Подготовка аргументов для C-функции
            let cArgs = args.map { strdup($0) } + [nil]
            let environ = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
            environ[0] = nil
            
            let status = posix_spawn(&pid, binaryPath, nil, nil, cArgs, environ)
            
            if status == 0 {
                self.childPid = pid
                print("slskd successfully started with PID: \(pid)")
            } else {
                print("posix_spawn failed with status: \(status)")
            }
            
            // Очистка памяти
            for ptr in cArgs { if let p = ptr { free(p) } }
            environ.deallocate()
        }
    }
}
