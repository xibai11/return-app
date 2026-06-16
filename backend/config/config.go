package config

import (
	"log"
	"os"
)

type Config struct {
	Port             string
	DBHost           string
	DBPort           string
	DBUser           string
	DBPassword       string
	DBName           string
	JWTSecret        string
	DefaultAdminUser string
	DefaultAdminPass string
}

func Load() *Config {
	cfg := &Config{
		Port:             getEnv("PORT", "9876"),
		DBHost:           getEnv("DB_HOST", "127.0.0.1"),
		DBPort:           getEnv("DB_PORT", "3306"),
		DBUser:           getEnv("DB_USER", "return_user"),
		DBPassword:       getEnv("DB_PASSWORD", "ReturnApp2026"),
		DBName:           getEnv("DB_NAME", "return_app"),
		JWTSecret:        getEnv("JWT_SECRET", "return-app-secret-key-change-me"),
		DefaultAdminUser: getEnv("ADMIN_USER", "admin"),
		DefaultAdminPass: getEnv("ADMIN_PASS", "admin123"),
	}
	log.Printf("配置加载: port=%s, db=%s@%s/%s", cfg.Port, cfg.DBUser, cfg.DBHost, cfg.DBName)
	return cfg
}

func getEnv(key, defaultValue string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return defaultValue
}
