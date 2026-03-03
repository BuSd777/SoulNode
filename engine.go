package main

import "C"
import (
	"encoding/json"
	"fmt"
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
	status = "Engine Ready"
	results = make(map[string][]Response)
	mu      sync.Mutex
)

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	user := C.GoString(cUser)
	status = "Logged in as " + user

	// Эндпоинт для создания поиска
	http.HandleFunc("/api/v0/searches", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			ID         string `json:"id"`
			SearchText string `json:"searchText"`
		}
		json.NewDecoder(r.Body).Decode(&req)
		
		fmt.Printf("Searching for: %s\n", req.SearchText)
		
		// ИМИТАЦИЯ ОТВЕТА СЕТИ (Пока мы не допишем полноценный TCP стек Soulseek)
		// Здесь движок "создает" результаты через 2 секунды
		go func(id string, query string) {
			time.Sleep(2 * time.Second)
			mu.Lock()
			results[id] = []Response{
				{
					ID: id, Username: "SoulMaster_77", FileCount: 1,
					Files: []File{{Filename: query + " - Greatest Hits.mp3", Size: 12500000, BitRate: 320}},
				},
				{
					ID: id, Username: "MusicLover_Arch", FileCount: 1,
					Files: []File{{Filename: "Unknown Artist - " + query + ".flac", Size: 45000000, BitRate: 1411}},
				},
			}
			mu.Unlock()
		}(req.ID, req.SearchText)
		
		w.WriteHeader(http.StatusOK)
	})

	// Эндпоинт для получения результатов
	http.HandleFunc("/api/v0/searches/", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Path[len("/api/v0/searches/"):]
		if len(id) > 10 { // отрезаем /responses если есть
			id = id[:len(id)-10]
		}
		
		mu.Lock()
		res, ok := results[id]
		mu.Unlock()

		if !ok {
			fmt.Fprint(w, "[]")
			return
		}
		json.NewEncoder(w).Encode(res)
	})

	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, status)
	})

	http.ListenAndServe("127.0.0.1:5030", nil)
}

func main() {}
