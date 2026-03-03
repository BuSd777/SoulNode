package main

import "C"
import (
	"bytes"
	"encoding/binary"
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"
)

// --- GLOBAL VARS ---
var (
	conn        net.Conn
	status      = "Engine Standby"
	statusMu    sync.Mutex
	savedUser   string
	savedPass   string
	isRunning   bool
	targets = []string{
		"server.soulseeknetwork.net:2242",
		"208.76.170.162:2242",
	}
)

// --- HELPERS ---

func setStatus(s string) {
	statusMu.Lock()
	defer statusMu.Unlock()
	status = s
	fmt.Println("GO LOG:", s)
}

func getStatus() string {
	statusMu.Lock()
	defer statusMu.Unlock()
	return status
}

func writeString(buf *bytes.Buffer, s string) {
	binary.Write(buf, binary.LittleEndian, uint32(len(s)))
	buf.WriteString(s)
}

// --- EXPORTED ---

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	if isRunning { return }
	isRunning = true
	savedUser = C.GoString(cUser)
	savedPass = C.GoString(cPass)
	
	go connectManager()
	
	go func() {
		// Health check
		http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, getStatus())
		})
		
		// Search stub
		http.HandleFunc("/api/v0/searches", handleSearch)
		
		http.ListenAndServe("127.0.0.1:5031", nil)
	}()
}

//export RestartEngine
func RestartEngine() {
	if conn != nil { conn.Close() }
	setStatus("Restarting...")
}

// --- LOGIC ---

func connectManager() {
	defer func() { if r := recover(); r != nil { setStatus(fmt.Sprintf("Panic: %v", r)) } }()

	for {
		success := false
		for _, target := range targets {
			setStatus("Connecting to " + target + "...")
			var err error
			conn, err = net.DialTimeout("tcp", target, 5*time.Second)
			if err == nil {
				setStatus("Connected! Logging in...")
				success = true
				break
			}
		}

		if !success {
			setStatus("Connection Failed. Retrying...")
			time.Sleep(5 * time.Second)
			continue
		}

		if login() {
			setStatus("🟢 ONLINE: " + savedUser)
			keepAliveLoop()
		} else {
			setStatus("Login Failed (Protocol Error)")
		}

		setStatus("Disconnected. Reconnecting...")
		time.Sleep(3 * time.Second)
	}
}

func login() bool {
	if conn == nil { return false }
	buf := new(bytes.Buffer)
	
	binary.Write(buf, binary.LittleEndian, uint32(1)) // Login
	writeString(buf, savedUser)
	writeString(buf, savedPass)
	binary.Write(buf, binary.LittleEndian, uint32(157)) // Version
	writeString(buf, "") // MD5
	binary.Write(buf, binary.LittleEndian, uint32(0)) // IP
	binary.Write(buf, binary.LittleEndian, uint32(0)) // Port
	writeString(buf, "") // Extra

	fullLen := uint32(buf.Len())
	header := make([]byte, 4)
	binary.LittleEndian.PutUint32(header, fullLen)
	
	_, err := conn.Write(append(header, buf.Bytes()...))
	return err == nil
}

func keepAliveLoop() {
	buffer := make([]byte, 1024)
	for {
		if conn == nil { break }
		_, err := conn.Read(buffer)
		if err != nil { break }
	}
}

func handleSearch(w http.ResponseWriter, r *http.Request) {
	// Пока просто заглушка, JSON нам тут не нужен
	setStatus("Search command received")
	w.WriteHeader(200)
}

func main() {}
