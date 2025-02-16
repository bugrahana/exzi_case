package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/redis/go-redis/v9"
)

type URLShortener struct {
	DB    *sql.DB
	Cache *redis.Client
}

type ShortenRequest struct {
	URL string `json:"url"`
}

type ShortenResponse struct {
	ShortURL string `json:"short_url"`
}

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

func generateShortID(n int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func (s *URLShortener) shortenURL(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ShortenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	shortID := generateShortID(8)

	// Store in MySQL
	_, err := s.DB.Exec("INSERT INTO urls (short_id, original_url) VALUES (?, ?)", shortID, req.URL)
	if err != nil {
		http.Error(w, "Failed to save URL", http.StatusInternalServerError)
		log.Println("MySQL Error:", err)
		return
	}

	// Cache in Redis
	err = s.Cache.Set(r.Context(), shortID, req.URL, 24*time.Hour).Err()
	if err != nil {
		log.Println("Redis Error:", err)
	}

	res := ShortenResponse{ShortURL: fmt.Sprintf("http://%s/%s", r.Host, shortID)}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(res)
}

func (s *URLShortener) getURL(w http.ResponseWriter, r *http.Request) {
	shortID := r.URL.Path[1:]
	if shortID == "" {
		http.Error(w, "Short ID is required", http.StatusBadRequest)
		return
	}

	// Try to get from Redis cache
	originalURL, err := s.Cache.Get(r.Context(), shortID).Result()
	if err == redis.Nil {
		// Fallback to MySQL
		row := s.DB.QueryRow("SELECT original_url FROM urls WHERE short_id = ?", shortID)
		if err := row.Scan(&originalURL); err != nil {
			if err == sql.ErrNoRows {
				http.Error(w, "URL not found", http.StatusNotFound)
			} else {
				http.Error(w, "Failed to retrieve URL", http.StatusInternalServerError)
			}
			return
		}

		// Cache the URL in Redis
		s.Cache.Set(r.Context(), shortID, originalURL, 24*time.Hour)
	} else if err != nil {
		http.Error(w, "Failed to retrieve URL", http.StatusInternalServerError)
		log.Println("Redis Error:", err)
		return
	}

	http.Redirect(w, r, originalURL, http.StatusFound)
}

func ensureDatabaseAndTable(db *sql.DB) error {
	// Check if the database exists
	_, err := db.Exec("USE url_shortener")
	if err != nil {
		// Create the database if it does not exist
		_, err = db.Exec("CREATE DATABASE url_shortener")
		if err != nil {
			return fmt.Errorf("failed to create database: %v", err)
		}
		_, err = db.Exec("USE url_shortener")
		if err != nil {
			return fmt.Errorf("failed to select database: %v", err)
		}
	}

	// Create the table if it does not exist
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS urls (
		short_id VARCHAR(8) PRIMARY KEY,
		original_url TEXT NOT NULL
	)`)
	if err != nil {
		return fmt.Errorf("failed to create table: %v", err)
	}

	return nil
}

func main() {
	mysqlDSN := os.Getenv("MYSQL_DSN")
	redisAddr := os.Getenv("REDIS_ADDR")
	redisPassword := os.Getenv("REDIS_PASSWORD")

	db, err := sql.Open("mysql", mysqlDSN)
	if err != nil {
		log.Fatal("Failed to connect to MySQL:", err)
	}
	defer db.Close()

	if err := ensureDatabaseAndTable(db); err != nil {
		log.Fatal("Database setup error:", err)
	}

	cache := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
		DB:       0,
	})

	// Check connection
	_, err = cache.Ping(context.Background()).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	s := &URLShortener{DB: db, Cache: cache}

	http.HandleFunc("/", s.getURL)
	http.HandleFunc("/shorten", s.shortenURL)

	log.Println("Starting server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// export MYSQL_DSN="root:123456@tcp(127.0.0.1:3306)/"
// export REDIS_ADDR="127.0.0.1:6379"
// export REDIS_PASSWORD="123456"
