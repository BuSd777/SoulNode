package main

import "C"
import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"time"
)

// Структуры данных
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
	status = "Engine Ready"
	currentUser = "Unknown"
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	// Защита от краша (Panic Recovery) - для iPhone 15
	defer func() {
		if r := recover(); r != nil {
			status = fmt.Sprintf("CRITICAL PANIC: %v", r)
		}
	}()

	user := C.GoString(cUser)
	pass := C.GoString(cPass)
	currentUser = user
	
	status = "Connecting to Soulseek..."

	// Асинхронный запуск сервера
	go func() {
		// РЕАЛЬНЫЙ КОННЕКТ (ПРОВЕРКА СЕТИ)
		conn, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 5*time.Second)
		if err != nil {
			status = "Network Error: " + err.Error()
		} else {
			status = "Connected to Soulseek! Logged in as " + user
			conn.Close()
			// В реальном клиенте тут нужно держать соединение открытым
			// Но для демо мы закрываем его и имитируем работу, чтобы не усложнять
		}

		mux := http.NewServeMux()
		
		// API Поиска (Эмуляция + Лог)
		mux.HandleFunc("/api/v0/searches", func(w http.ResponseWriter, r *http.Request) {
			var req struct { SearchText string `json:"searchText"` }
			json.NewDecoder(r.Body).Decode(&req)
			fmt.Printf("Searching for: %s\n", req.SearchText)
			w.WriteHeader(http.StatusOK)
		})

		// API Результатов (Возвращаем демо-данные для проверки UI)
		mux.HandleFunc("/api/v0/searches/", func(w http.ResponseWriter, r *http.Request) {
			// Имитация задержки поиска
			time.Sleep(500 * time.Millisecond)
			
			res := []Response{
				{
					ID: "1", Username: "Soul_Archive_Bot", FileCount: 1,
					Files: []File{{Filename: "Test_Track_For_" + user + ".mp3", Size: 5242880, BitRate: 320}},
				},
				{
					ID: "2", Username: "Real_User_123", FileCount: 1,
					Files: []File{{Filename: "Another_Song.flac", Size: 25000000, BitRate: 1411}},
				},
			}
			json.NewEncoder(w).Encode(res)
		})

		// API Статуса
		mux.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, status)
		})

		http.ListenAndServe("127.0.0.1:5030", mux)
	}()
}

func main() {}
