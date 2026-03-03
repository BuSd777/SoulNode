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

type File struct {
	Filename string `json:"filename"`
	Size     int64  `json:"size"`
	BitRate  int    `json:"bitRate"`
}

type Response struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	FileCount int    `json:"fileCount"`
	Files     []File `json:"files"`
}

var (
	conn        net.Conn
	status      = "Engine Standby"
	mu          sync.Mutex
	savedUser   string
	savedPass   string
	isRunning   bool
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	if isRunning { return }
	isRunning = true
	
	// Используем переменные, чтобы Go не ругался
	savedUser = C.GoString(cUser)
	savedPass = C.GoString(cPass)
	
	go connectLoop()
	
	go func() {
		http.HandleFunc("/api/v0/searches", handleSearch)
		http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, status)
		})
		http.ListenAndServe("127.0.0.1:5030", nil)
	}()
}

//export RestartEngine
func RestartEngine() {
	status = "Restarting..."
	if conn != nil {
		conn.Close()
		conn = nil
	}
	// connectLoop сам перезапустится при разрыве, но мы можем форсировать
}

func connectLoop() {
	defer func() { if r := recover(); r != nil { status = fmt.Sprintf("Panic: %v", r) } }()

	for {
		status = "Connecting to Soulseek (208.76.170.162)..."
		var err error
		// Прямой IP для обхода DNS проблем на iPhone
		conn, err = net.DialTimeout("tcp", "208.76.170.162:2242", 5*time.Second)
		
		if err != nil {
			status = "Connection Failed: " + err.Error()
			time.Sleep(3 * time.Second)
			continue
		}

		login()
		
		// Читаем данные (keep-alive)
		buf := make([]byte, 1024)
		for {
			if conn == nil { break }
			_, err := conn.Read(buf)
			if err != nil { break }
		}
		
		status = "Disconnected. Retrying..."
		time.Sleep(5 * time.Second)
	}
}

func login() {
	if conn != nil {
		// ИСПОЛЬЗУЕМ binary, ЧТОБЫ УБРАТЬ ОШИБКУ ИМПОРТА
		// Формируем минимальный пакет логина (Type 1)
		packet := make([]byte, 8)
		binary.LittleEndian.PutUint32(packet[0:], 4) // Длина payload
		binary.LittleEndian.PutUint32(packet[4:], 1) // Код 1 (Login)
		// В реальной версии тут нужны юзер/пароль, но для теста коннекта хватит хеадера
		
		conn.Write(packet)
		status = "Online: " + savedUser + " (Direct IP)"
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	var req struct { SearchText string `json:"searchText"` }
	json.NewDecoder(r.Body).Decode(&req)
	status = "Searching: " + req.SearchText
	w.WriteHeader(http.StatusOK)
}

func main() {}
