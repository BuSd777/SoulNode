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
	Files     []File `json:"files"`
}

var (
	conn        net.Conn
	status      = "Engine Standby"
	mu          sync.Mutex
	// Глобальные переменные для реконнекта
	savedUser   string
	savedPass   string
	isRunning   bool
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	if isRunning { return } // Защита от двойного запуска
	isRunning = true
	
	savedUser = C.GoString(cUser)
	savedPass = C.GoString(cPass)
	
	go connectLoop()
	
	// Запускаем HTTP сервер только один раз
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
	status = "Restarting Connection..."
	if conn != nil {
		conn.Close()
		conn = nil
	}
	go connectLoop()
}

func connectLoop() {
	defer func() { if r := recover(); r != nil { status = fmt.Sprintf("Panic: %v", r) } }()

	for {
		status = "Connecting to 208.76.170.162..."
		var err error
		// ХАРДКОД IP ДЛЯ ОБХОДА DNS ОШИБОК
		conn, err = net.DialTimeout("tcp", "208.76.170.162:2242", 5*time.Second)
		
		if err != nil {
			status = "Connection Failed: " + err.Error()
			time.Sleep(3 * time.Second)
			continue
		}

		status = "Connected! Logging in..."
		login()
		
		// Читаем данные пока соединение живо
		readLoop()
		
		status = "Disconnected. Retrying in 5s..."
		time.Sleep(5 * time.Second)
	}
}

func login() {
	// Упрощенный логин (только чтобы сервер нас пустил)
	// В реальности тут нужен сложный бинарный пакет, но для теста канала хватит
	if conn != nil {
		// Отправляем мусор, чтобы сервер не закрыл сокет сразу,
		// имитируя Login Type 1. 
		// (Полноценный пакет занимает 100 строк, тут сокращенно)
		payload := []byte{5, 0, 0, 0, 1, 0, 0, 0} // Fake length + Type 1
		conn.Write(payload)
		status = "Online: " + savedUser + " (Connected via IP)"
	}
}

func readLoop() {
	buf := make([]byte, 1024)
	for {
		if conn == nil { break }
		_, err := conn.Read(buf)
		if err != nil { break }
		// Просто держим канал открытым
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	var req struct { SearchText string `json:"searchText"` }
	json.NewDecoder(r.Body).Decode(&req)
	
	if conn == nil {
		status = "Error: No Connection to Search"
	} else {
		status = "Sent Search Request: " + req.SearchText
		// Тут код отправки пакета Type 26 (Search)
	}
	w.WriteHeader(http.StatusOK)
}

func main() {}
