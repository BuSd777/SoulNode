package main
import (
	"fmt"
	"net/http"
)
func main() {
	fmt.Println("SoulNode Go-Engine starting...")
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})
	http.ListenAndServe(":5030", nil)
}
