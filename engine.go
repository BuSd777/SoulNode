package main

import "C"
import (
	"bytes"
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
	serverConn net.Conn
	status     = "Engine Standby"
	results    = make(map[string][]Response)
	mu         sync.Mutex
	myIP       uint32
	myPort     = 5030
)

// --- ПОМОЩНИКИ ---
func getLocalIP() uint32 {
	addrs, _ := net.InterfaceAddrs()
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				ip := ipnet.IP.To4()
				return binary.LittleEndian.Uint32(ip)
			}
		}
	}
	return 0
}

func writeString(buf *bytes.Buffer, s string) {
	binary.Write(buf, binary.LittleEndian, uint32(len(s)))
	buf.WriteString(s)
}

// --- ОСНОВНАЯ ЛОГИКА ---

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	defer func() { if r := recover(); r != nil { status = fmt.Sprintf("PANIC: %v", r) } }()

	user := C.GoString(cUser)
	pass := C.GoString(cPass)
	myIP = getLocalIP()

	// 1. ЗАПУСКАЕМ СЛУШАТЕЛЯ (ЧТОБЫ ПРИНИМАТЬ ФАЙЛЫ ОТ ДРУГИХ)
	go startP2PListener()

	// 2. ПОДКЛЮЧАЕМСЯ К СЕРВЕРУ
	go func() {
		status = "Connecting to Server (208.76.170.162)..."
		var err error
		serverConn, err = net.DialTimeout("tcp", "208.76.170.162:2242", 10*time.Second)
		if err != nil {
			status = "Server Down: " + err.Error()
			return
		}

		// Логин (Type 1) - СООБЩАЕМ СВОЙ IP И ПОРТ!
		buf := new(bytes.Buffer)
		binary.Write(buf, binary.LittleEndian, uint32(1)) // Code 1
		writeString(buf, user)
		writeString(buf, pass)
		binary.Write(buf, binary.LittleEndian, uint32(157)) // Version
		writeString(buf, "") // Hash
		binary.Write(buf, binary.LittleEndian, myIP) // <--- ВАЖНО: НАШ IP
		binary.Write(buf, binary.LittleEndian, uint32(myPort)) // <--- ВАЖНО: НАШ ПОРТ
		writeString(buf, "")

		sendPacket(buf.Bytes())
		status = "Sent Login. Listening for Peers..."
		
		handleServerMessages()
	}()

	startHTTPServer()
}

func startP2PListener() {
	ln, err := net.Listen("tcp", fmt.Sprintf(":%d", myPort))
	if err != nil {
		fmt.Printf("Cannot bind port %d: %v\n", myPort, err)
		return
	}
	for {
		conn, err := ln.Accept()
		if err != nil { continue }
		// Сюда приходят другие юзеры отдавать результаты поиска
		go handlePeer(conn)
	}
}

func handlePeer(conn net.Conn) {
	defer conn.Close()
	// Тут должна быть логика разбора P2P протокола (PeerInit, SharedFileList)
	// Это ОЧЕНЬ сложный бинарный протокол.
	// Для диагностики мы просто запишем, что кто-то подключился.
	status = "⚡️ INCOMING PEER CONNECTION! (NAT WORKS)"
}

func sendPacket(data []byte) {
	if serverConn == nil { return }
	fullLen := uint32(len(data))
	header := make([]byte, 4)
	binary.LittleEndian.PutUint32(header, fullLen)
	serverConn.Write(append(header, data...))
}

func handleServerMessages() {
	for {
		header := make([]byte, 4)
		_, err := serverConn.Read(header)
		if err != nil { 
			status = "Disconnected from Server"
			return 
		}
		msgLen := binary.LittleEndian.Uint32(header)
		buf := make([]byte, msgLen)
		_, err = serverConn.Read(buf)
		if err != nil { return }

		code := binary.LittleEndian.Uint32(buf[:4])
		if code == 1 {
			if buf[4] == 1 {
				status = "🟢 ONLINE (Port 5030 Open)"
			} else {
				status = "🔴 Bad Password"
			}
		}
	}
}

func startHTTPServer() {
	// API Поиска
	http.HandleFunc("/api/v0/searches", func(w http.ResponseWriter, r *http.Request) {
		var req struct { SearchText string `json:"searchText"` }
		json.NewDecoder(r.Body).Decode(&req)
		
		// Отправляем поиск (Type 26)
		buf := new(bytes.Buffer)
		binary.Write(buf, binary.LittleEndian, uint32(26)) // Code 26
		binary.Write(buf, binary.LittleEndian, uint32(time.Now().Unix())) // Random Token
		writeString(buf, req.SearchText)
		sendPacket(buf.Bytes())
		
		status = "Searching Network for: " + req.SearchText
		w.WriteHeader(http.StatusOK)
	})

	http.HandleFunc("/api/v0/searches/", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		res := []Response{} // Пока пусто, ждем пиров
		mu.Unlock()
		json.NewEncoder(w).Encode(res)
	})

	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, status)
	})

	http.ListenAndServe("127.0.0.1:5030", nil)
}

func main() {}
