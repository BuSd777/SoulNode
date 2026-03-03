package main

import (
	"fmt"
	"net"
	"net/http"
	"time"
)

func main() {
	status := "Engine Started"
	
	// Фоновый коннект к Soulseek
	go func() {
		for {
			conn, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 15*time.Second)
			if err != nil {
				status = "Network Error: " + err.Error()
			} else {
				status = "Connected to Soulseek Network (Waiting for Login Type 1)"
				conn.Close()
			}
			time.Sleep(30 * time.Second) // Пытаемся раз в полминуты, чтобы не банили
		}
	}()

	// API для связи с айфоном
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, status)
	})

	fmt.Println("Server listening on :5030")
	if err := http.ListenAndServe(":5030", nil); err != nil {
		fmt.Printf("Fatal: %v\n", err)
	}
}
