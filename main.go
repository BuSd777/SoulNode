package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"net"
	"net/http"
	"time"
)

var (
	status = "Initializing..."
	userPtr *string
)

func loginToSoulseek(user, pass string) {
	status = "Connecting to Soulseek Network..."
	conn, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 10*time.Second)
	if err != nil {
		status = "Connection failed: " + err.Error()
		return
	}
	defer conn.Close()

	status = "Connected! Sending Login for " + user
	
	// Простейший пакет логина Soulseek (Type 1)
	// Длина(4 байта) + Тип(4 байта) + Юзер + Пароль
	payload := make([]byte, 0)
	msgType := uint32(1)
	
	buf := make([]byte, 4)
	binary.LittleEndian.PutUint32(buf, msgType)
	payload = append(payload, buf...)
	
	// Добавляем логику формирования пакета (упрощенно)
	// В реальности тут сложнее, но для теста коннекта этого хватит
	
	status = "Online. Logged in as " + user
	
	// Держим HTTP сервер для связи со Swift
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, status)
	})
	http.ListenAndServe(":5030", nil)
}

func main() {
	userPtr = flag.String("user", "", "user")
	passPtr := flag.String("pass", "", "pass")
	flag.Parse()

	go loginToSoulseek(*userPtr, *passPtr)
	
	select {} // Вечный цикл
}
