package controllers

import (
	"return-app/config"
	"return-app/database"
	"return-app/models"
	"return-app/services"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func Login(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		user, token, err := services.Login(database.DB, req.Username, req.Password)
		if err != nil {
			c.JSON(401, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{
			"token": token,
			"user":  user,
		})
	}
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Name     string `json:"name" binding:"required"`
}

func Register(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RegisterRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		user, err := services.Register(database.DB, req.Username, req.Password, req.Name)
		if err != nil {
			c.JSON(400, gin.H{"error": err.Error()})
			return
		}
		token, _ := services.GenerateToken(user, "")
		c.JSON(200, gin.H{
			"token": token,
			"user":  user,
		})
	}
}

func Me() gin.HandlerFunc {
	return func(c *gin.Context) {
		uid := c.GetUint("user_id")
		var user models.User
		if err := database.DB.First(&user, uid).Error; err != nil {
			c.JSON(404, gin.H{"error": "用户不存在"})
			return
		}
		c.JSON(200, user)
	}
}

func ListUsers() gin.HandlerFunc {
	return func(c *gin.Context) {
		var users []models.User
		if err := database.DB.Select("id, username, name, role, created_at").Find(&users).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, users)
	}
}

// 管理员
func AdminListUsers() gin.HandlerFunc {
	return func(c *gin.Context) {
		var users []models.User
		if err := database.DB.Find(&users).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, users)
	}
}

type AdminCreateUserRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Name     string `json:"name" binding:"required"`
	Role     string `json:"role"`
}

func AdminCreateUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		var req AdminCreateUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		if req.Role == "" {
			req.Role = "user"
		}
		user, err := services.Register(database.DB, req.Username, req.Password, req.Name)
		if err != nil {
			c.JSON(400, gin.H{"error": err.Error()})
			return
		}
		if req.Role == "admin" {
			database.DB.Model(user).Update("role", "admin")
			user.Role = "admin"
		}
		c.JSON(200, user)
	}
}

type AdminUpdateUserRequest struct {
	Name     string `json:"name"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

func AdminUpdateUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var req AdminUpdateUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		updates := map[string]interface{}{}
		if req.Name != "" {
			updates["name"] = req.Name
		}
		if req.Role != "" {
			updates["role"] = req.Role
		}
		if req.Password != "" {
			hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			updates["password"] = string(hash)
		}
		if err := database.DB.Model(&models.User{}).Where("id = ?", id).Updates(updates).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"ok": true})
	}
}

func AdminDeleteUser() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if err := database.DB.Delete(&models.User{}, id).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"ok": true})
	}
}
