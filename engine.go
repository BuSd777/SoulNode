package main

import "C"
import (
	"fmt"
	"net/http"
)

var status = "Engine Standby"

//export StartEngine
func StartEngine(cUser *C.char, cPass *C.char) {
	user := C.GoString(cUser)
	status = "Engine running for: " + user
	
	http.HandleFunc("/api/v0/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, status)
	})

	// Запускаем на локалхосте внутри приложения
	http.ListenAndServe("127.0.0.1:5030", nil)
}

func main() {}
