import SwiftUI

class ServerStatus: ObservableObject {
    static let shared = ServerStatus()
    
    @Published var logs: String = "Ready to connect..."
    @Published var isRunning: Bool = false
    @Published var isConnecting: Bool = false
}
