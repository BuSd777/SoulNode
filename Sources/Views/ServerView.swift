import SwiftUI

struct ServerView: View {
    @ObservedObject var status = ServerStatus.shared
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Circle()
                        .fill(status.isRunning ? Color.green : Color.red)
                        .frame(width: 15, height: 15)
                    Text(status.isRunning ? "Online" : "Offline")
                        .bold()
                    Spacer()
                }
                .padding()

                ScrollView {
                    Text(status.logs)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Button("Clear Logs") {
                    status.logs = "Logs cleared.\n"
                }
                .padding()
            }
            .navigationTitle("Internal Server")
        }
    }
}
