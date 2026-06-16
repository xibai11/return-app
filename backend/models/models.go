package models

import (
	"time"

	"gorm.io/gorm"
)

// 用户
type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Username  string         `gorm:"size:50;uniqueIndex;not null" json:"username"`
	Password  string         `gorm:"size:255;not null" json:"-"`
	Name      string         `gorm:"size:50;not null" json:"name"`
	Role      string         `gorm:"size:20;default:'user'" json:"role"` // admin / user
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// 退货记录
type Record struct {
	ID              uint           `gorm:"primaryKey" json:"id"`
	OrderNo         string         `gorm:"size:100;index;not null" json:"order_no"`
	CustomerName    string         `gorm:"size:100" json:"customer_name"`
	CustomerPhone   string         `gorm:"size:30" json:"customer_phone"`
	ProductName     string         `gorm:"size:200" json:"product_name"`
	Quantity        int            `gorm:"default:1" json:"quantity"`
	RefundAmount    float64        `gorm:"type:decimal(10,2);default:0" json:"refund_amount"`
	RefundReason    string         `gorm:"type:text" json:"refund_reason"`
	ReasonType      string         `gorm:"size:50" json:"reason_type"`
	Remark          string         `gorm:"type:text" json:"remark"`
	ReturnDate      string         `gorm:"size:20" json:"return_date"`
	Address         string         `gorm:"type:text" json:"address"`
	TrackingNo      string         `gorm:"size:100" json:"tracking_no"`
	IsImportant     bool           `gorm:"default:false;index" json:"is_important"`
	Status          string         `gorm:"size:20;default:'pending';index" json:"status"` // pending / processing / completed
	CreatedByID     uint           `gorm:"index" json:"created_by_id"`
	CreatorName     string         `gorm:"size:50" json:"creator_name"`
	HandlerID       *uint          `gorm:"index" json:"handler_id,omitempty"`
	HandlerName     string         `gorm:"size:50" json:"handler_name,omitempty"`
	HandlerTime     string         `gorm:"size:30" json:"handler_time,omitempty"`
	CompletedByID   *uint          `gorm:"index" json:"completed_by_id,omitempty"`
	CompletedByName string         `gorm:"size:50" json:"completed_by_name,omitempty"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	CompletedAt     *time.Time     `json:"completed_at,omitempty"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// 操作日志
type ActionLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	RecordID  uint      `gorm:"index" json:"record_id"`
	UserID    uint      `gorm:"index" json:"user_id"`
	UserName  string    `gorm:"size:50" json:"user_name"`
	Action    string    `gorm:"size:30;index" json:"action"` // create / update / complete / uncomplete / delete
	Remark    string    `gorm:"size:255" json:"remark"`
	CreatedAt time.Time `json:"created_at"`
}
