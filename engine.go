package main

import "C"
import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
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
	conn    net.Conn
	status  = "Engine Standby"
	results = make(map[string][]Response)
	mu      sync.Mutex
)

func writeSlskString(s string) []byte {
	b := make([]byte, 4+len(s))
	binary.LittleEndian.PutUint32(b[:4], uint32(len(s)))
	copy(b[4:], s)
	return b
}

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	username := C.GoString(cUser)
	password := C.GoString(cPass)

	go func() {
		for {
			status = "Connecting to Soulseek..."
			c, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 10*time.Second)
			if err != nil {
				status = "Connection Error: " + err.Error()
				time.Sleep(5 * time.Second)
				continue
			}
			conn = c

			// Формируем пакет логина (Type 1)
			userBuf := writeSlskString(username)
			passBuf := writeSlskString(password)
			
			msgLen := uint32(len(userBuf) + len(passBuf) + 8)
			pkg := make([]byte, 4)
			binary.LittleEndian.PutUint32(pkg, msgLen)
			
			binary.LittleEndian.PutUint32(pkg, 1) // Type 1
			pkg = append(pkg, userBuf...)
			pkg = append(pkg, passBuf...)
			
			// Версия протокола
			ver := make([]byte, 4)
			binary.LittleEndian.PutUint32(ver, 160)
			pkg = append(pkg, ver...)

			conn.Write(pkg)
			status = "Logged in as " + username

			// Читаем ответы
			readLoop()
		}
	}()

	http.HandleFunc("/api/v0/searches", handleSearch)
	http.HandleFunc("/api/v0/searches/", handleGetResults)
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, status) })
	http.ListenAndServe("127.0.0.1:5030", nil)
}

func readLoop() {
	for {
		header := make([]byte, 8)
		if _, err := io.ReadFull(conn, header); err != nil {
			break
		}
		
		length := binary.LittleEndian.Uint32(header[:4])
		code := binary.LittleEndian.Uint32(header[4:])
		
		// Читаем тело сообщения, чтобы не забивать сокет
		body := make([]byte, length-4)
		io.ReadFull(conn, body)
		
		fmt.Printf("Received message code: %d\n", code)
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	var req struct { ID string `json:"id"`; SearchText string `json:"searchText"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return
	}
	
	if conn != nil {
		searchPkg := writeSlskString(req.SearchText)
		header := make([]byte, 12)
		binary.LittleEndian.PutUint32(header[:4], uint32(len(searchPkg)+8))
		binary.LittleEndian.PutUint32(header[4:], 14) // Type 14
		binary.LittleEndian.PutUint32(header[8:], 1)  // Ticket
		
		conn.Write(append(header, searchPkg...))
		status = "Search sent: " + req.SearchText
	}
}

func handleGetResults(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	res := []Response{} // Пока возвращаем пустой массив, чтобы Swift не падал
	mu.Unlock()
	json.NewEncoder(w).Encode(res)
}

func main() {}
