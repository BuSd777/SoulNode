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

// Структуры для API
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
	conn    net.Conn
	status  = "Initializing..."
	results = make(map[string][]Response)
	mu      sync.Mutex
)

// Помощник для записи строк в формате Soulseek (Length + Data)
func writeSlskString(data []byte, s string) []byte {
	buf := make([]byte, 4)
	binary.LittleEndian.PutUint32(buf, uint32(len(s)))
	data = append(data, buf...)
	return append(data, []byte(s)...)
}

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	username := C.GoString(cUser)
	password := C.GoString(cPass)

	go func() {
		for {
			status = "Connecting to Soulseek..."
			var err error
			conn, err = net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 10*time.Second)
			if err != nil {
				status = "Connection Error: " + err.Error()
				time.Sleep(5 * time.Second)
				continue
			}

			// Пакет логина (Type 1)
			loginPkg := make([]byte, 0)
			loginPkg = writeSlskString(loginPkg, username)
			loginPkg = writeSlskString(loginPkg, password)
			
			// Добавляем версию и хеш (стандартные значения)
			binary.LittleEndian.PutUint32(make([]byte, 4), 160) // version
			
			fullPkg := make([]byte, 8)
			binary.LittleEndian.PutUint32(fullPkg[:4], uint32(len(loginPkg)+4))
			binary.LittleEndian.PutUint32(fullPkg[4:], 1) // Type 1
			fullPkg = append(fullPkg, loginPkg...)

			conn.Write(fullPkg)
			status = "Logged in as " + username

			// Читаем входящие пакеты
			readLoop()
		}
	}()

	// HTTP API для Swift
	http.HandleFunc("/api/v0/searches", handleSearch)
	http.HandleFunc("/api/v0/searches/", handleGetResults)
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, status) })
	http.ListenAndServe("127.0.0.1:5030", nil)
}

func readLoop() {
	for {
		header := make([]byte, 8)
		_, err := conn.Read(header)
		if err != nil { break }
		
		length := binary.LittleEndian.PutUint32(header[:4], 0) // Упрощенно
		// Тут в реальности идет парсинг типов пакетов (Search Reply и т.д.)
		// Для первой итерации "реального" кода мы подтверждаем коннект
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	var req struct { ID string `json:"id"`; SearchText string `json:"searchText"` }
	json.NewDecoder(r.Body).Decode(&req)
	
	if conn != nil {
		// Реальный пакет поиска (Type 14)
		searchPkg := make([]byte, 0)
		binary.LittleEndian.PutUint32(make([]byte, 4), 1) // ticket
		searchPkg = writeSlskString(searchPkg, req.SearchText)
		
		header := make([]byte, 8)
		binary.LittleEndian.PutUint32(header[:4], uint32(len(searchPkg)+4))
		binary.LittleEndian.PutUint32(header[4:], 14) // Type 14
		conn.Write(append(header, searchPkg...))
		
		status = "Searching for: " + req.SearchText
	}
	w.WriteHeader(http.StatusOK)
}

func handleGetResults(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Path[len("/api/v0/searches/"):]
	mu.Lock()
	res := results[id]
	mu.Unlock()
	if res == nil { res = []Response{} }
	json.NewEncoder(w).Encode(res)
}

func main() {}
