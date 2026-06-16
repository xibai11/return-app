package main

import (
	"log"
	"os"
	"return-app/config"
	"return-app/database"
	"return-app/models"
	"return-app/routes"
	"return-app/services"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg := config.Load()

	// 初始化数据库
	if err := database.Init(cfg); err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}

	// 自动迁移
	if err := database.DB.AutoMigrate(&models.User{}, &models.Record{}, &models.ActionLog{}); err != nil {
		log.Fatalf("数据库迁移失败: %v", err)
	}

	// 初始化管理员
	if err := services.InitAdmin(database.DB, cfg.DefaultAdminUser, cfg.DefaultAdminPass); err != nil {
		log.Printf("初始化管理员失败: %v", err)
	}

	// 初始化 Gin
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()

	// CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
		MaxAge:           12 * 3600,
	}))

	// 注册路由
	routes.Register(r, cfg)

	// 启动服务
	addr := ":" + cfg.Port
	log.Printf("服务启动于 %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("服务启动失败: %v", err)
		os.Exit(1)
	}
}
