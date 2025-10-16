package handler

import (
	"CRC_LRC/config"
	"CRC_LRC/internal/calculator"
	"CRC_LRC/internal/notification"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/sirupsen/logrus"
)

// APIError 定义统一的API错误响应格式
type APIError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// Result 定义了API返回的JSON格式
type Result struct {
	Input         string                           `json:"input"`
	InputBytesHex string                           `json:"inputBytesHex"`
	Results       map[calculator.CRCType]CRCResult `json:"results"`
}

// CRCResult 为每个CRC类型的结果
type CRCResult struct {
	Decimal uint64 `json:"decimal"`
	Hex     string `json:"hex"`
}

// sendError 辅助函数，发送JSON错误响应
func sendError(w http.ResponseWriter, code int, message string) {
	logrus.WithFields(logrus.Fields{
		"code":    code,
		"message": message,
	}).Error("API Error")

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(APIError{Code: code, Message: message})
}

// ChecksumHandler 处理校验请求
func ChecksumHandler(w http.ResponseWriter, r *http.Request) {
	inputStr := r.URL.Query().Get("input")
	if inputStr == "" {
		sendError(w, http.StatusBadRequest, "Missing 'input' query parameter")
		return
	}

	// 限制输入长度
	if len(inputStr) > config.Cfg.Checksum.MaxInputLengthBytes {
		sendError(w, http.StatusRequestEntityTooLarge, fmt.Sprintf("Input string too long. Max allowed: %d bytes", config.Cfg.Checksum.MaxInputLengthBytes))
		return
	}

	var inputBytes []byte
	// 尝试将输入字符串转换为字节，支持十六进制字符串和普通字符串
	if len(inputStr) > 2 && (strings.HasPrefix(inputStr, "0x") || strings.HasPrefix(inputStr, "0X")) {
		var err error
		inputBytes, err = hex.DecodeString(inputStr[2:])
		if err != nil {
			sendError(w, http.StatusBadRequest, fmt.Sprintf("Invalid hex input: %v", err))
			return
		}
	} else {
		inputBytes = []byte(inputStr)
	}

	results := make(map[calculator.CRCType]CRCResult)

	// CRC16 MODBUS
	if crc16ModbusVal, err := calculator.CalculateCRC(calculator.CRC16_MODBUS, inputBytes); err == nil {
		val := crc16ModbusVal.(uint16)
		// 格式化为低字节在前 (48B4 for B448)
		hexStr := fmt.Sprintf("0x%02X%02X", byte(val&0xFF), byte(val>>8))
		results[calculator.CRC16_MODBUS] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating CRC16 MODBUS: %v", err)
	}

	// CRC16 CCITT
	if crc16CcittVal, err := calculator.CalculateCRC(calculator.CRC16_CCITT, inputBytes); err == nil {
		val := crc16CcittVal.(uint16)
		hexStr := fmt.Sprintf("0x%04X", val) // 默认高字节在前
		results[calculator.CRC16_CCITT] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating CRC16 CCITT: %v", err)
	}

	// CRC32 IEEE
	if crc32IeeeVal, err := calculator.CalculateCRC(calculator.CRC32_IEEE, inputBytes); err == nil {
		val := crc32IeeeVal.(uint32)
		hexStr := fmt.Sprintf("0x%08X", val)
		results[calculator.CRC32_IEEE] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating CRC32 IEEE: %v", err)
	}

	// SUM8
	if sum8Val, err := calculator.CalculateCRC(calculator.SUM8, inputBytes); err == nil {
		val := sum8Val.(uint8)
		hexStr := fmt.Sprintf("0x%02X", val)
		results[calculator.SUM8] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating SUM8: %v", err)
	}

	response := Result{
		Input:         inputStr,
		InputBytesHex: calculator.BytesToHexString(inputBytes),
		Results:       results,
	}

	// 🔥 异步发送 Telegram 通知
	go sendChecksumNotification(r, inputStr, response)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	logrus.WithFields(logrus.Fields{
		"input":           inputStr,
		"input_bytes_hex": response.InputBytesHex,
		"results":         response.Results,
	}).Info("Checksum calculation successful")
}

// sendChecksumNotification 发送校验和计算的通知
func sendChecksumNotification(r *http.Request, input string, result Result) {
	// 获取客户端 IP
	ip := getClientIP(r)

	// 获取 User-Agent
	userAgent := r.Header.Get("User-Agent")
	if userAgent == "" {
		userAgent = "Unknown"
	}

	// 格式化结果信息
	resultStr := formatResults(result.Results)

	// 发送通知
	notification.SendTelegramNotification(notification.NotificationData{
		ToolName:  "CRC/LRC Calculator",
		InputData: input,
		Method:    "API Query",
		Result:    resultStr,
		IP:        ip,
		UserAgent: userAgent,
	})
}

// getClientIP 获取客户端真实 IP
func getClientIP(r *http.Request) string {
	// 优先从 X-Real-IP 获取
	ip := r.Header.Get("X-Real-IP")
	if ip != "" {
		return ip
	}

	// 其次从 X-Forwarded-For 获取
	ip = r.Header.Get("X-Forwarded-For")
	if ip != "" {
		// X-Forwarded-For 可能包含多个 IP，取第一个
		if idx := strings.Index(ip, ","); idx > 0 {
			ip = ip[:idx]
		}
		return strings.TrimSpace(ip)
	}

	// 最后使用 RemoteAddr
	ip = r.RemoteAddr
	// 去除端口号
	if idx := strings.LastIndex(ip, ":"); idx > 0 {
		ip = ip[:idx]
	}
	return ip
}

// formatResults 格式化多个校验和结果
func formatResults(results map[calculator.CRCType]CRCResult) string {
	var parts []string
	
	if crc, ok := results[calculator.CRC16_MODBUS]; ok {
		parts = append(parts, fmt.Sprintf("CRC16-MODBUS: %s", crc.Hex))
	}
	if crc, ok := results[calculator.CRC16_CCITT]; ok {
		parts = append(parts, fmt.Sprintf("CRC16-CCITT: %s", crc.Hex))
	}
	if crc, ok := results[calculator.CRC32_IEEE]; ok {
		parts = append(parts, fmt.Sprintf("CRC32-IEEE: %s", crc.Hex))
	}
	if sum, ok := results[calculator.SUM8]; ok {
		parts = append(parts, fmt.Sprintf("SUM8: %s", sum.Hex))
	}
	
	return strings.Join(parts, ", ")
}
