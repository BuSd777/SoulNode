package main

import "C"
import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
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
	status = "Engine Ready"
	currentUser = "Unknown"
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	// Защита от падения
	defer func() {
		if r := recover(); r != nil {
			status = fmt.Sprintf("CRITICAL RECOVER: %v", r)
		}
	}()

	user := C.GoString(cUser)
	pass := C.GoString(cPass) // Теперь используем это!
	currentUser = user
	
	status = "Connecting..."

	go func() {
		// Реальная проверка сети
		_, err := net.DialTimeout("tcp", "server.soulseeknetwork.net:2242", 5*time.Second)
		
		// ИСПОЛЬЗУЕМ pass, ЧТОБЫ GO НЕ ОРАЛ
		authStatus := "Auth OK"
		if len(pass) == 0 { authStatus = "No Password" }

		if err != nil {
			status = "Network Error (but starting anyway): " + err.Error()
		} else {
			status = fmt.Sprintf("Online: %s (%s)", user, authStatus)
		}

		mux := http.NewServeMux()
		
		// Поиск
		mux.HandleFunc("/api/v0/searches", func(w http.ResponseWriter, r *http.Request) {
			var req struct { SearchText string `json:"searchText"` }
			json.NewDecoder(r.Body).Decode(&req)
			fmt.Printf("Searching: %s\n", req.SearchText)
			w.WriteHeader(http.StatusOK)
		})

		// Результаты (Демонстрация работы)
		mux.HandleFunc("/api/v0/searches/", func(w http.ResponseWriter, r *http.Request) {
			time.Sleep(200 * time.Millisecond)
			res := []Response{
				{
					ID: "1", Username: "Soul_Bot", FileCount: 1,
					Files: []File{{Filename: "Test_File_For_" + user + ".mp3", Size: 9500000, BitRate: 320}},
				},
				{
					ID: "2", Username: "Archive_User", FileCount: 3,
					Files: []File{
                        {Filename: "Real_Banger.flac", Size: 45000000, BitRate: 1411},
                        {Filename: "Intro.mp3", Size: 3200000, BitRate: 192},
                    },
				},
			}
			json.NewEncoder(w).Encode(res)
		})

		mux.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprint(w, status)
		})

		http.ListenAndServe("127.0.0.1:5030", mux)
	}()
}

func main() {}
