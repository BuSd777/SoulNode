import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    var timer: Timer?
    
    func startServer(username: String, password: String) {
        // 1. Меняем статус в UI сразу, чтобы кнопка нажалась
        DispatchQueue.main.async {
            ServerStatus.shared.logs = "Starting engine..."
            ServerStatus.shared.isConnecting = true
        }
        
        // 2. Запускаем Go в фоне
        DispatchQueue.global(qos: .userInitiated).async {
            let cUser = (username as NSString).utf8String
            let cPass = (password as NSString).utf8String
            StartEngine(UnsafeMutablePointer(mutating: cUser), UnsafeMutablePointer(mutating: cPass))
        }
        
        // 3. Запускаем "слушателя" (Health Check)
        startHealthCheck()
    }
    
    func startHealthCheck() {
        // Останавливаем старый таймер если был
        timer?.invalidate()
        
        // Каждые 0.5 секунды спрашиваем у Go: "Как дела?"
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.fetchLogs()
            }
        }
    }
    
    func fetchLogs() {
        guard let url = URL(string: "http://127.0.0.1:5031/api/v0/health") else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1.0)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data, let logText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    ServerStatus.shared.logs = logText
                    
                    // Если в логах есть "ONLINE", переключаем экран
                    if logText.contains("ONLINE") {
                        ServerStatus.shared.isRunning = true
                        ServerStatus.shared.isConnecting = false
                    }
                }
            }
        }.resume()
    }
}
