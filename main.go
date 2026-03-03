package main
import (
	"flag"
	"fmt"
	"net/http"
)
func main() {
	user := flag.String("user", "", "Soulseek username")
	pass := flag.String("pass", "", "Soulseek password")
	flag.Parse()
	fmt.Printf("Engine starting for user: %s\n", *user)
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "OK")
	})
	http.ListenAndServe(":5030", nil)
}
