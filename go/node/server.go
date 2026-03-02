package node

import (
	"context"
	"fmt"
	"github.com/crow-misia/slsk-go"
	"github.com/crow-misia/slsk-go/packet"
	"time"
)

type Delegate interface {
	OnStatusChange(status string)
	OnSearchResult(filename string, size int64, username string)
}

type SoulEngine struct {
	delegate Delegate
	client   *slsk.Client
}

func NewEngine(d Delegate) *SoulEngine {
	return &SoulEngine{delegate: d}
}

func (e *SoulEngine) StartNode(username, password, docPath string) error {
	e.delegate.OnStatusChange("Connecting to Soulseek...")
	
	// Настройка клиента
	client, err := slsk.Connect(context.Background(), "server.slsknet.org:2242")
	if err != nil {
		return err
	}
	e.client = client

	// Логин
	resp, err := client.Login(username, password)
	if err != nil {
		return err
	}
	
	if !resp.Success {
		e.delegate.OnStatusChange("Login failed: " + resp.Reason)
		return fmt.Errorf("login failed")
	}

	e.delegate.OnStatusChange("Logged in as " + username)
	
	// Слушаем ответы от сети в отдельном потоке
	go e.listen()
	
	return nil
}

func (e *SoulEngine) listen() {
	for {
		p, err := e.client.ReadPacket()
		if err != nil {
			return
		}
		
		switch pkt := p.(type) {
		case *packet.FileSearchResponse:
			for _, file := range pkt.Files {
				// Передаем каждый найденный файл в UI Swift
				e.delegate.OnSearchResult(file.Filename, file.Size, pkt.Username)
			}
		}
	}
}

func (e *SoulEngine) Search(query string) {
	if e.client == nil { return }
	e.delegate.OnStatusChange("Searching for: " + query)
	
	// Отправляем поисковый запрос в сеть
	ticket := uint32(time.Now().Unix())
	_ = e.client.WritePacket(&packet.FileSearchRequest{
		Ticket: ticket,
		Query:  query,
	})
}
