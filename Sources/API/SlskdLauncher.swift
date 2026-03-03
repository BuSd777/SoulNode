import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        print("Launcher: Starting Engine...")
        DispatchQueue.global(qos: .userInitiated).async {
            let cUser = (username as NSString).utf8String
            let cPass = (password as NSString).utf8String
            StartEngine(UnsafeMutablePointer(mutating: cUser), UnsafeMutablePointer(mutating: cPass))
        }
    }
    
    func restartServer() {
        DispatchQueue.global(qos: .utility).async {
            RestartEngine()
        }
    }
}
