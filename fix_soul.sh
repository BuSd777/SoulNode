#!/bin/bash

# Переходим в папку проекта
cd ~/Desktop/SoulNode || { echo "❌ Не нашел папку SoulNode!"; exit 1; }
echo "📂 Зашел в проект..."

# --- 1. ENGINE.GO ---
echo "🛠 Обновляю engine.go..."
cat << 'EOF' > engine.go
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

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	if isRunning { return }
	isRunning = true
	savedUser = C.GoString(cUser)
	savedPass = C.GoString(cPass)
	
	go connectManager()
	
	go func() {
		http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, getStatus())
		})
		http.HandleFunc("/api/v0/searches", handleSearch)
		http.ListenAndServe("127.0.0.1:5031", nil)
	}()
}

//export RestartEngine
func RestartEngine() {
	if conn != nil { conn.Close() }
	setStatus("Restarting...")
}

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
	
	binary.Write(buf, binary.LittleEndian, uint32(1)) // Login Code
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
	setStatus("Search command received")
	w.WriteHeader(200)
}

func main() {}
EOF

# --- 2. INFO.PLIST ---
echo "🔓 Обновляю Info.plist..."
cat << 'EOF' > Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
	<key>NSLocalNetworkUsageDescription</key>
	<string>SoulNode needs network access.</string>
	<key>UILaunchScreen</key>
	<dict/>
</dict>
</plist>
EOF

# --- 3. SWIFT LAUNCHER ---
echo "📱 Обновляю SlskdLauncher.swift..."
cat << 'EOF' > Sources/API/SlskdLauncher.swift
import Foundation

class SlskdLauncher {
    static let shared = SlskdLauncher()
    
    func startServer(username: String, password: String) {
        print("Launcher: Starting Engine...")
        DispatchQueue.global(qos: .userInitiated).async {
            let cUser = (username as NSString).utf8String
            let cPass = (password as NSString).utf8String
            StartEngine(UnsafeMutablePointer(mutating: cUser), UnsafeMutablePointer(mutating: cPass))
        }
    }
    
    func restartServer() {
        DispatchQueue.global(qos: .utility).async {
            RestartEngine()
        }
    }
}
EOF

# --- 4. GIT ---
echo "🚀 Отправляю на GitHub..."
git add .
git commit -m "Auto-fix from Bash Script"
git push origin main
echo "✅ ВСЁ ГОТОВО!"
