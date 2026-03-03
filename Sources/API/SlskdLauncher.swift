import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    private var process: Process?

    func startServer(username: String, password: String) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let configPath = docs.appendingPathComponent("slskd.yml").path
        
        // Создаем конфиг файл
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
        EOF
        """
        
        try? configContent.write(toFile: configPath, atomically: true, encoding: .utf8)
        try? fileManager.createDirectory(at: docs.appendingPathComponent("Downloads"), withIntermediateDirectories: true)
        
        // Ищем бинарник в бандле приложения
        guard let binaryPath = Bundle.main.path(forResource: "slskd", ofType: nil) else {
            print("Binary not found in bundle")
            return
        }

        // ВАЖНО: На iOS запуск процессов требует привилегий (TrollStore это позволяет)
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: binaryPath)
            task.arguments = ["--config", configPath]
            
            do {
                try task.run()
                self.process = task
                print("slskd server started!")
            } catch {
                print("Failed to launch slskd: \(error)")
            }
        }
    }
}
