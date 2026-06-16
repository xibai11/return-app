package routes

import (
	"return-app/config"
	"return-app/controllers"
	"return-app/middleware"

	"github.com/gin-gonic/gin"
)

func Register(r *gin.Engine, cfg *config.Config) {
	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// 公开 API
	auth := r.Group("/api/auth")
	{
		auth.POST("/login", controllers.Login(cfg))
		auth.POST("/register", controllers.Register(cfg))
	}

	// 需要登录的 API
	api := r.Group("/api")
	api.Use(middleware.JWTAuth())
	{
		api.GET("/me", controllers.Me())
		api.GET("/users", controllers.ListUsers())

		// 记录
		api.GET("/records", controllers.ListRecords())
		api.GET("/records/:id", controllers.GetRecord())
		api.POST("/records", controllers.CreateRecord())
		api.PUT("/records/:id", controllers.UpdateRecord())
		api.PATCH("/records/:id/status", controllers.ToggleStatus())
		api.DELETE("/records/:id", controllers.DeleteRecord())
		api.GET("/records/export", controllers.ExportRecords())

		// 统计
		api.GET("/stats/dashboard", controllers.DashboardStats())
		api.GET("/stats/recent", controllers.RecentActions())

		// 操作日志
		api.GET("/logs", controllers.ListLogs())
	}

	// 管理员 API
	admin := r.Group("/api/admin")
	admin.Use(middleware.JWTAuth(), middleware.AdminOnly())
	{
		admin.GET("/users", controllers.AdminListUsers())
		admin.POST("/users", controllers.AdminCreateUser())
		admin.PUT("/users/:id", controllers.AdminUpdateUser())
		admin.DELETE("/users/:id", controllers.AdminDeleteUser())
	}
}
