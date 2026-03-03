package main
import (
	"fmt"
	"net/http"
	"os"
)
func main() {
	port := "5030"
	fmt.Printf("SoulNode Go-Engine starting on port %s...\n", port)
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})
	// Тут будет логика коннекта к Soulseek в будущем
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
