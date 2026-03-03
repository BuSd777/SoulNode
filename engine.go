package main

import "C"
import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"
)

// --- СТРУКТУРЫ ---
type File struct {
	Filename string `json:"filename"`
	Size     int64  `json:"size"`
	BitRate  int    `json:"bitRate"`
}

type Response struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Files     []File `json:"files"`
}

var (
	conn        net.Conn
	status      = "Engine Standby"
	mu          sync.Mutex
	savedUser   string
	isRunning   bool
	// СПИСОК ЦЕЛЕЙ (Как в торрентах трекеры)
	targets = []string{
		"server.soulseeknetwork.net:2242",
		"208.76.170.162:2242", // Primary
		"208.76.170.162:2240", // Alt port
		"208.76.170.162:80",   // HTTP port try
	}
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	if isRunning { return }
	isRunning = true
	
	savedUser = C.GoString(cUser)
	_ = C.GoString(cPass)
	
	go connectManager()
	
	go func() {
		http.HandleFunc("/api/v0/searches", handleSearch)
		http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, status)
		})
		http.ListenAndServe("127.0.0.1:5031", nil)
	}()
}

//export RestartEngine
func RestartEngine() {
	if conn != nil { conn.Close() }
	status = "Reconnecting..."
}

func connectManager() {
	defer func() { if r := recover(); r != nil { status = fmt.Sprintf("Panic: %v", r) } }()

	for {
		// ПЕРЕБОР АДРЕСОВ (SMART CONNECT)
		success := false
		for _, target := range targets {
			status = "Trying " + target + "..."
			var err error
			// Таймаут побольше для мобильной сети
			conn, err = net.DialTimeout("tcp", target, 10*time.Second)
			
			if err == nil {
				status = "Connected to " + target + "! Logging in..."
				success = true
				break
			}
		}

		if !success {
			status = "ALL SERVERS FAILED (Check Internet/VPN)"
			time.Sleep(5 * time.Second)
			continue
		}

		login()
		
		// Keep-alive loop
		buf := make([]byte, 1024)
		for {
			if conn == nil { break }
			conn.SetReadDeadline(time.Now().Add(60 * time.Second)) // Пинг раз в минуту
			_, err := conn.Read(buf)
			if err != nil { break }
		}
		
		status = "Lost Connection. Retrying..."
		time.Sleep(3 * time.Second)
	}
}

func login() {
	if conn != nil {
		// Пакет логина
		packet := make([]byte, 8)
		binary.LittleEndian.PutUint32(packet[0:], 4)
		binary.LittleEndian.PutUint32(packet[4:], 1) 
		conn.Write(packet)
		status = "🟢 Online: " + savedUser
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	var req struct { SearchText string `json:"searchText"` }
	json.NewDecoder(r.Body).Decode(&req)
	status = "Searching: " + req.SearchText
	w.WriteHeader(http.StatusOK)
}

func main() {}
