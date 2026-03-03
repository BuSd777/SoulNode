import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            Text("Transfers")
                .tabItem { Label("Transfers", systemImage: "arrow.up.arrow.down") }
            ServerView()
                .tabItem { Label("Server", systemImage: "server.rack") }
        }
        .accentColor(Color(red: 0.25, green: 0.8, blue: 0.65))
    }
}
