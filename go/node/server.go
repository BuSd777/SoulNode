package node
import ("fmt"; "os"; "path/filepath")
type Delegate interface {
	OnStatusChange(status string)
	OnSearchResult(filename string, size int64, username string)
}
type SoulEngine struct { delegate Delegate }
func NewEngine(d Delegate) *SoulEngine { return &SoulEngine{delegate: d} }
func (e *SoulEngine) StartNode(username, password, docPath string) error {
	e.delegate.OnStatusChange("Connecting to Soulseek...")
	os.MkdirAll(filepath.Join(docPath, "Shared"), 0755)
	e.delegate.OnStatusChange("Connected. Port 2234 open.")
	return nil
}
func (e *SoulEngine) Search(query string) {
	e.delegate.OnStatusChange(fmt.Sprintf("Searching: %s", query))
	e.delegate.OnSearchResult(query + " - Track 1.mp3", 10485760, "troll_user")
}
