package main

import "C"
import (
	"fmt"
	"net"
	"net/http"
	"time"
)

var status = "Engine Standby"

//export StartEngine
func StartEngine() {
	status = "Engine Starting..."
	
	// Попытка реального коннекта к Soulseek
	go func() {
		for {
			conn, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 10*time.Second)
			if err != nil {
				status = "Soulseek Connection Error: " + err.Error()
			} else {
				status = "Connected to Soulseek! (Wait for Auth)"
				// Тут в следующих шагах добавим логику обмена пакетами
				conn.Close()
			}
			time.Sleep(20 * time.Second)
		}
	}()

	// HTTP API для Swift (внутри того же приложения)
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, status)
	})

	fmt.Println("Go Bridge active on :5030")
	http.ListenAndServe("127.0.0.1:5030", nil)
}

func main() {}
