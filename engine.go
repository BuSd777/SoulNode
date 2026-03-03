package main

import "C"
import (
	"fmt"
	"net/http"
)

var (
	engineStatus = "Ready to start"
	currentPort  = "5030"
)

//export StartEngine
func StartEngine(cPort *C.char) {
	currentPort = C.GoString(cPort)
	engineStatus = "Engine running on port " + currentPort

	mux := http.NewServeMux()
	mux.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, engineStatus)
	})

	server := &http.Server{
		Addr:    "127.0.0.1:" + currentPort,
		Handler: mux,
	}

	fmt.Println("Go Server starting...")
	err := server.ListenAndServe()
	if err != nil {
		engineStatus = "Error: " + err.Error()
	}
}

func main() {}
