package main

import (
  "log"
  "fmt"
  "net/http"
  "github.com/PuerkitoBio/goquery"
  "strings"
  "regexp"
)

var httpClient = &http.Client{}

type Message struct {
  Status string `json:"status"`
  Message string `json:"message"`
}

func getFoxholeFandomData(page string) {
  fmt.Printf("Accessing page %s", page)
  url := fmt.Sprintf("https://foxhole.wiki.gg/wiki/%s", page)
  res, err := http.Get(url)
  if err != nil {
    log.Fatalf("Failed to create request for page %s: %v\n", page, err)
  }
  defer res.Body.Close()

  doc, err := goquery.NewDocumentFromReader(res.Body)
  if err != nil {
    log.Fatalf("Failed to parse html %v", err)
  }

  doc.Find("h3 + div").Each(func(i int, s *goquery.Selection) {
    fmt.Printf("Selected: %s\n", regexp.MustCompile(`\s+`).ReplaceAllString(s.Text(), ""))
    tables := s.Find("table");
    if(tables.Length() > 0) {
      fmt.Printf("Found %d tables", tables.Length())
    } else {
      fmt.Printf("No tables \n")
    }
  })
}

func handleHome(w http.ResponseWriter, r *http.Request) {
}

func handleData(w http.ResponseWriter, r *http.Request) {
  page := strings.TrimPrefix(r.URL.Path, "/data/")
  getFoxholeFandomData(page)
}

func httpLoggingMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    fmt.Printf("method=\"%s\" url=\"%s\"\n", r.Method, r.URL)
    next.ServeHTTP(w, r)
  })
}


func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("/", handleHome)
  mux.HandleFunc("/data/", handleData)

  handler := httpLoggingMiddleware(mux)

  server := &http.Server{
    Addr: ":8080",
    Handler: handler,
  }

  log.Println("Starting to listen on port 8080");
  err := server.ListenAndServe()

  if err != nil {
    log.Fatalf("Server failed to start: %v", err)
  }
}
