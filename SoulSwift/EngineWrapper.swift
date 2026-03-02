import Foundation
import Node
struct SearchItem: Identifiable {
    let id = UUID(); let filename: String; let size: Int64; let user: String
}
class EngineWrapper: NSObject, ObservableObject, NodeDelegateProtocol {
    @Published var status: String = "Disconnected"
    @Published var results: [SearchItem] = []
    private var engine: NodeSoulEngine?
    override init() { super.init(); self.engine = NodeNewEngine(self) }
    func startEngine(username: String, pass: String) {
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        DispatchQueue.global(qos: .background).async { try? self.engine?.startNode(username, password: pass, docPath: docPath) }
    }
    func search(query: String) { self.results.removeAll(); engine?.search(query) }
    func onStatusChange(_ status: String?) { DispatchQueue.main.async { self.status = status ?? "" } }
    func onSearchResult(_ filename: String?, size: Int64, username: String?) {
        DispatchQueue.main.async { self.results.append(SearchItem(filename: filename ?? "", size: size, user: username ?? "")) }
    }
}
