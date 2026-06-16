package controllers

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"return-app/database"
	"return-app/models"

	"github.com/gin-gonic/gin"
	"github.com/xuri/excelize/v2"
)

type RecordRequest struct {
	OrderNo       string  `json:"order_no" binding:"required"`
	CustomerName  string  `json:"customer_name"`
	CustomerPhone string  `json:"customer_phone"`
	ProductName   string  `json:"product_name"`
	Quantity      int     `json:"quantity"`
	RefundAmount  float64 `json:"refund_amount"`
	RefundReason  string  `json:"refund_reason"`
	ReasonType    string  `json:"reason_type"`
	Remark        string  `json:"remark"`
	ReturnDate    string  `json:"return_date"`
	Address       string  `json:"address"`
	TrackingNo    string  `json:"tracking_no"`
	IsImportant   bool    `json:"is_important"`
	Status        string  `json:"status"`
}

func logAction(recordID uint, userID uint, userName, action, remark string) {
	database.DB.Create(&models.ActionLog{
		RecordID:  recordID,
		UserID:    userID,
		UserName:  userName,
		Action:    action,
		Remark:    remark,
		CreatedAt: time.Now(),
	})
}

func ListRecords() gin.HandlerFunc {
	return func(c *gin.Context) {
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
		if page < 1 {
			page = 1
		}
		if pageSize < 1 || pageSize > 500 {
			pageSize = 50
		}
		status := c.Query("status")
		important := c.Query("important")
		search := c.Query("search")

		tx := database.DB.Model(&models.Record{})
		if status != "" && status != "all" {
			tx = tx.Where("status = ?", status)
		}
		if important == "1" || important == "true" {
			tx = tx.Where("is_important = ?", true)
		}
		if search != "" {
			like := "%" + search + "%"
			tx = tx.Where("order_no LIKE ? OR customer_name LIKE ? OR tracking_no LIKE ? OR product_name LIKE ? OR creator_name LIKE ?", like, like, like, like, like)
		}
		var total int64
		tx.Count(&total)

		var records []models.Record
		offset := (page - 1) * pageSize
		if err := tx.Order("is_important DESC, created_at DESC").Offset(offset).Limit(pageSize).Find(&records).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{
			"list":      records,
			"total":     total,
			"page":      page,
			"page_size": pageSize,
		})
	}
}

func GetRecord() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var record models.Record
		if err := database.DB.First(&record, id).Error; err != nil {
			c.JSON(404, gin.H{"error": "记录不存在"})
			return
		}
		c.JSON(200, record)
	}
}

func CreateRecord() gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RecordRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误: " + err.Error()})
			return
		}
		uid := c.GetUint("user_id")
		uname := c.GetString("username")
		name := c.GetString("username")

		if req.Status == "" {
			req.Status = "pending"
		}
		record := models.Record{
			OrderNo:       req.OrderNo,
			CustomerName:  req.CustomerName,
			CustomerPhone: req.CustomerPhone,
			ProductName:   req.ProductName,
			Quantity:      req.Quantity,
			RefundAmount:  req.RefundAmount,
			RefundReason:  req.RefundReason,
			ReasonType:    req.ReasonType,
			Remark:        req.Remark,
			ReturnDate:    req.ReturnDate,
			Address:       req.Address,
			TrackingNo:    req.TrackingNo,
			IsImportant:   req.IsImportant,
			Status:        req.Status,
			CreatedByID:   uid,
			CreatorName:   name,
		}
		if err := database.DB.Create(&record).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		logAction(record.ID, uid, uname, "create", "创建记录 #"+req.OrderNo)
		c.JSON(200, record)
	}
}

func UpdateRecord() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var req RecordRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		uid := c.GetUint("user_id")
		uname := c.GetString("username")

		var record models.Record
		if err := database.DB.First(&record, id).Error; err != nil {
			c.JSON(404, gin.H{"error": "记录不存在"})
			return
		}
		updates := map[string]interface{}{
			"order_no":       req.OrderNo,
			"customer_name":  req.CustomerName,
			"customer_phone": req.CustomerPhone,
			"product_name":   req.ProductName,
			"quantity":       req.Quantity,
			"refund_amount":  req.RefundAmount,
			"refund_reason":  req.RefundReason,
			"reason_type":    req.ReasonType,
			"remark":         req.Remark,
			"return_date":    req.ReturnDate,
			"address":        req.Address,
			"tracking_no":    req.TrackingNo,
			"is_important":   req.IsImportant,
			"status":         req.Status,
		}
		// handler tracking
		if req.Status == "completed" || req.Status == "processing" {
			updates["handler_id"] = uid
			updates["handler_name"] = uname
			updates["handler_time"] = time.Now().Format("2006-01-02 15:04:05")
		}
		if err := database.DB.Model(&record).Updates(updates).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		logAction(record.ID, uid, uname, "update", "更新记录 #"+req.OrderNo)
		c.JSON(200, record)
	}
}

type ToggleRequest struct {
	Status string `json:"status" binding:"required"`
}

func ToggleStatus() gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var req ToggleRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": "参数错误"})
			return
		}
		if req.Status != "pending" && req.Status != "processing" && req.Status != "completed" {
			c.JSON(400, gin.H{"error": "状态值无效"})
			return
		}
		uid := c.GetUint("user_id")
		uname := c.GetString("username")

		var record models.Record
		if err := database.DB.First(&record, id).Error; err != nil {
			c.JSON(404, gin.H{"error": "记录不存在"})
			return
		}

		updates := map[string]interface{}{"status": req.Status}
		action := "uncomplete"
		if req.Status == "completed" {
			now := time.Now()
			updates["completed_at"] = &now
			updates["completed_by_id"] = uid
			updates["completed_by_name"] = uname
			updates["handler_id"] = uid
			updates["handler_name"] = uname
			updates["handler_time"] = now.Format("2006-01-02 15:04:05")
			action = "complete"
		} else if req.Status == "processing" {
			now := time.Now()
			updates["handler_id"] = uid
			updates["handler_name"] = uname
			updates["handler_time"] = now.Format("2006-01-02 15:04:05")
			action = "processing"
		} else {
			updates["completed_at"] = nil
			updates["completed_by_id"] = nil
			updates["completed_by_name"] = ""
		}

		if err := database.DB.Model(&record).Updates(updates).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		logAction(record.ID, uid, uname, action, "状态切换为 "+req.Status)
		c.JSON(200, record)
	}
}

func DeleteRecord() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := c.Get("role")
		if role != "admin" {
			c.JSON(403, gin.H{"error": "需要管理员权限"})
			return
		}
		id := c.Param("id")
		uid := c.GetUint("user_id")
		uname := c.GetString("username")
		var record models.Record
		if err := database.DB.First(&record, id).Error; err != nil {
			c.JSON(404, gin.H{"error": "记录不存在"})
			return
		}
		if err := database.DB.Delete(&record).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		logAction(record.ID, uid, uname, "delete", "删除记录 #"+record.OrderNo)
		c.JSON(200, gin.H{"ok": true})
	}
}

func ExportRecords() gin.HandlerFunc {
	return func(c *gin.Context) {
		status := c.Query("status")
		important := c.Query("important")
		search := c.Query("search")

		tx := database.DB.Model(&models.Record{})
		if status != "" && status != "all" {
			tx = tx.Where("status = ?", status)
		}
		if important == "1" || important == "true" {
			tx = tx.Where("is_important = ?", true)
		}
		if search != "" {
			like := "%" + search + "%"
			tx = tx.Where("order_no LIKE ? OR customer_name LIKE ? OR tracking_no LIKE ? OR product_name LIKE ? OR creator_name LIKE ?", like, like, like, like, like)
		}
		var records []models.Record
		if err := tx.Order("is_important DESC, created_at DESC").Find(&records).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

		f := excelize.NewFile()
		sheet := "退货记录"
		f.SetSheetName("Sheet1", sheet)
		headers := []string{"ID", "订单号", "客户姓名", "联系电话", "商品名称", "数量", "退款金额", "原因类型", "详细原因", "备注", "退货日期", "物流单号", "是否重点", "状态", "录入人", "处理人", "创建时间"}
		for i, h := range headers {
			cell, _ := excelize.CoordinatesToCellName(i+1, 1)
			f.SetCellValue(sheet, cell, h)
		}
		headerStyle, _ := f.NewStyle(&excelize.Style{
			Font:      &excelize.Font{Bold: true, Color: "FFFFFF"},
			Fill:      excelize.Fill{Type: "pattern", Color: []string{"#2563EB"}, Pattern: 1},
			Alignment: &excelize.Alignment{Horizontal: "center", Vertical: "center"},
		})
		f.SetRowStyle(sheet, 1, 1, headerStyle)
		for i, r := range records {
			row := i + 2
			imp := "否"
			if r.IsImportant {
				imp = "是"
			}
			st := "待处理"
			if r.Status == "completed" {
				st = "已完成"
			} else if r.Status == "processing" {
				st = "处理中"
			}
			values := []interface{}{
				r.ID, r.OrderNo, r.CustomerName, r.CustomerPhone, r.ProductName,
				r.Quantity, r.RefundAmount, r.ReasonType, r.RefundReason,
				r.Remark, r.ReturnDate, r.TrackingNo, imp, st, r.CreatorName,
				r.HandlerName, r.CreatedAt.Format("2006-01-02 15:04:05"),
			}
			for j, v := range values {
				cell, _ := excelize.CoordinatesToCellName(j+1, row)
				f.SetCellValue(sheet, cell, v)
			}
		}
		colWidths := map[string]float64{"A": 6, "B": 20, "C": 15, "D": 15, "E": 20, "F": 8, "G": 12, "H": 12, "I": 30, "J": 25, "K": 14, "L": 20, "M": 10, "N": 10, "O": 12, "P": 12, "Q": 18}
		for col, w := range colWidths {
			f.SetColWidth(sheet, col, col, w)
		}

		filename := fmt.Sprintf("退货记录_%s.xlsx", time.Now().Format("20060102_150405"))
		c.Header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
		c.Header("Content-Disposition", "attachment; filename="+filename)
		f.WriteTo(c.Writer)
	}
}

func ListLogs() gin.HandlerFunc {
	return func(c *gin.Context) {
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
		if page < 1 {
			page = 1
		}
		if pageSize < 1 || pageSize > 200 {
			pageSize = 50
		}
		var total int64
		database.DB.Model(&models.ActionLog{}).Count(&total)
		var logs []models.ActionLog
		offset := (page - 1) * pageSize
		if err := database.DB.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&logs).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, gin.H{"list": logs, "total": total, "page": page, "page_size": pageSize})
	}
}

// 仪表盘统计
func DashboardStats() gin.HandlerFunc {
	return func(c *gin.Context) {
		var (
			total      int64
			pending    int64
			completed  int64
			importantP int64
			todayNew   int64
			todayDone  int64
		)
		database.DB.Model(&models.Record{}).Count(&total)
		database.DB.Model(&models.Record{}).Where("status = ?", "pending").Count(&pending)
		database.DB.Model(&models.Record{}).Where("status = ?", "completed").Count(&completed)
		database.DB.Model(&models.Record{}).Where("is_important = ? AND status = ?", true, "pending").Count(&importantP)

		now := time.Now()
		startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		database.DB.Model(&models.Record{}).Where("created_at >= ?", startOfDay).Count(&todayNew)
		database.DB.Model(&models.Record{}).Where("completed_at >= ?", startOfDay).Count(&todayDone)

		// 近 7 天趋势
		type DayStat struct {
			Date      string `json:"date"`
			NewCount  int64  `json:"new_count"`
			DoneCount int64  `json:"done_count"`
		}
		var trend []DayStat
		for i := 6; i >= 0; i-- {
			d := startOfDay.AddDate(0, 0, -i)
			d2 := d.AddDate(0, 0, 1)
			var n, dn int64
			database.DB.Model(&models.Record{}).Where("created_at >= ? AND created_at < ?", d, d2).Count(&n)
			database.DB.Model(&models.Record{}).Where("completed_at >= ? AND completed_at < ?", d, d2).Count(&dn)
			trend = append(trend, DayStat{
				Date:      d.Format("01-02"),
				NewCount:  n,
				DoneCount: dn,
			})
		}

		// 录入人统计 (近 7 天)
		type UserStat struct {
			UserName string `json:"user_name"`
			Count    int64  `json:"count"`
		}
		var userStats []UserStat
		database.DB.Model(&models.Record{}).
			Select("created_by_name as user_name, COUNT(*) as count").
			Where("created_at >= ?", startOfDay.AddDate(0, 0, -6)).
			Group("created_by_name").
			Order("count DESC").
			Limit(10).
			Scan(&userStats)

		// 退款原因 TOP（优先用 reason_type，否则用 refund_reason）
		type ReasonStat struct {
			Reason string `json:"reason"`
			Count  int64  `json:"count"`
		}
		var reasonStats []ReasonStat
		database.DB.Model(&models.Record{}).
			Select("COALESCE(NULLIF(reason_type, ''), refund_reason) as reason, COUNT(*) as count").
			Where("created_at >= ?", startOfDay.AddDate(0, 0, -30)).
			Group("reason").
			Order("count DESC").
			Limit(10).
			Scan(&reasonStats)

		c.JSON(200, gin.H{
			"total":            total,
			"pending":          pending,
			"completed":        completed,
			"important_pending": importantP,
			"today_new":        todayNew,
			"today_done":       todayDone,
			"trend":            trend,
			"user_stats":       userStats,
			"reason_stats":     reasonStats,
		})
	}
}

func RecentActions() gin.HandlerFunc {
	return func(c *gin.Context) {
		var logs []models.ActionLog
		if err := database.DB.Order("created_at DESC").Limit(20).Find(&logs).Error; err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		c.JSON(200, logs)
	}
}

// helper
func ContainsString(s, substr string) bool {
	return strings.Contains(s, substr)
}
