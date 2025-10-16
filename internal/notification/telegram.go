package notification

import (
	"CRC_LRC/config"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/sirupsen/logrus"
)

// TelegramPayload 定义 Telegram API 请求体
type TelegramPayload struct {
	ChatID    string `json:"chat_id"`
	Text      string `json:"text"`
	ParseMode string `json:"parse_mode"`
}

// NotificationData 定义通知所需的数据
type NotificationData struct {
	ToolName  string
	InputData string
	Method    string
	Result    string
	IP        string
	UserAgent string
}

// SendTelegramNotification 异步发送 Telegram 通知
func SendTelegramNotification(data NotificationData) {
	// 检查是否启用了 Telegram 通知
	if !config.Cfg.Telegram.Enabled {
		logrus.Debug("Telegram notification is disabled")
		return
	}

	// 在后台 goroutine 中发送，不阻塞响应
	go func() {
		// 创建带超时的 context
		ctx, cancel := context.WithTimeout(context.Background(), config.Cfg.Telegram.Timeout)
		defer cancel()

		// 构建消息
		message := formatMessage(data)

		// 准备请求
		payload := TelegramPayload{
			ChatID:    config.Cfg.Telegram.ChatId,
			Text:      message,
			ParseMode: "HTML",
		}

		jsonData, err := json.Marshal(payload)
		if err != nil {
			logrus.WithError(err).Error("Failed to marshal Telegram payload")
			return
		}

		// 构建 API URL
		url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", config.Cfg.Telegram.BotToken)

		// 创建请求
		req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
		if err != nil {
			logrus.WithError(err).Error("Failed to create Telegram request")
			return
		}
		req.Header.Set("Content-Type", "application/json")

		// 发送请求
		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			logrus.WithError(err).Warn("Telegram notification request failed")
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			logrus.WithFields(logrus.Fields{
				"tool": data.ToolName,
				"ip":   data.IP,
			}).Info("✅ Telegram notification sent successfully")
		} else {
			logrus.WithFields(logrus.Fields{
				"status_code": resp.StatusCode,
				"tool":        data.ToolName,
			}).Warn("❌ Telegram notification failed")
		}
	}()
}

// formatMessage 格式化 Telegram 消息
func formatMessage(data NotificationData) string {
	// 限制输入数据长度，避免消息过长
	inputData := data.InputData
	if len(inputData) > 100 {
		inputData = inputData[:100] + "..."
	}

	// 限制结果长度
	result := data.Result
	if len(result) > 200 {
		result = result[:200] + "..."
	}

	return fmt.Sprintf(
		"🔧 <b>工具使用通知</b>\n\n"+
			"🛠 <b>工具名称:</b> %s\n"+
			"📊 <b>输入数据:</b> <code>%s</code>\n"+
			"🔢 <b>方法:</b> %s\n"+
			"✅ <b>结果:</b> <code>%s</code>\n\n"+
			"📍 <b>来源信息:</b>\n"+
			"• IP: %s\n"+
			"• User-Agent: %s\n"+
			"• 时间: %s",
		escapeHTML(data.ToolName),
		escapeHTML(inputData),
		escapeHTML(data.Method),
		escapeHTML(result),
		escapeHTML(data.IP),
		escapeHTML(data.UserAgent),
		time.Now().Format("2006-01-02 15:04:05"),
	)
}

// escapeHTML 转义 HTML 特殊字符
func escapeHTML(s string) string {
	s = replaceAll(s, "&", "&amp;")
	s = replaceAll(s, "<", "&lt;")
	s = replaceAll(s, ">", "&gt;")
	return s
}

// replaceAll 替换字符串中的所有匹配项
func replaceAll(s, old, new string) string {
	result := ""
	for i := 0; i < len(s); i++ {
		if i <= len(s)-len(old) && s[i:i+len(old)] == old {
			result += new
			i += len(old) - 1
		} else {
			result += string(s[i])
		}
	}
	return result
}
