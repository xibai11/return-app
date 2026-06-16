package services

import (
	"errors"
	"time"

	"return-app/config"
	"return-app/models"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Claims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// 初始化管理员账号
func InitAdmin(db *gorm.DB, username, password string) error {
	var count int64
	if err := db.Model(&models.User{}).Where("username = ?", username).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	user := models.User{
		Username: username,
		Password: string(hash),
		Name:     "管理员",
		Role:     "admin",
	}
	return db.Create(&user).Error
}

// 注册
func Register(db *gorm.DB, username, password, name string) (*models.User, error) {
	if len(username) < 3 || len(password) < 6 {
		return nil, errors.New("用户名至少 3 位，密码至少 6 位")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	user := &models.User{
		Username: username,
		Password: string(hash),
		Name:     name,
		Role:     "user",
	}
	if err := db.Create(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

// 登录
func Login(db *gorm.DB, username, password string) (*models.User, string, error) {
	var user models.User
	if err := db.Where("username = ?", username).First(&user).Error; err != nil {
		return nil, "", errors.New("用户名或密码错误")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, "", errors.New("用户名或密码错误")
	}
	token, err := GenerateToken(&user, "")
	if err != nil {
		return nil, "", err
	}
	return &user, token, nil
}

// 生成 token
func GenerateToken(user *models.User, secret string) (string, error) {
	if secret == "" {
		secret = config.Load().JWTSecret
	}
	claims := Claims{
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * 7 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(secret))
}

func ParseToken(tokenStr, secret string) (*Claims, error) {
	if secret == "" {
		secret = config.Load().JWTSecret
	}
	t, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	if claims, ok := t.Claims.(*Claims); ok && t.Valid {
		return claims, nil
	}
	return nil, errors.New("invalid token")
}
