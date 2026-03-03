import SwiftUI

@main
struct SoulNodeApp: App {
    @AppStorage("isLogged") var isLogged = false
    
    var body: some Scene {
        WindowGroup {
            if isLogged {
                MainTabView()
                    .preferredColorScheme(.dark)
            } else {
                LoginView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
