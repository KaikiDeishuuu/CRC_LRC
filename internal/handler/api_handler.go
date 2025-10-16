package handler

import (
	"CRC_LRC/internal/calculator"
	"CRC_LRC/internal/notification"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/sirupsen/logrus"
)

// APIRequest 定义前端发送的请求格式
type APIRequest struct {
	Data      string `json:"data"`
	Method    string `json:"method"`    // "text" 或 "hex"
	Algorithm string `json:"algorithm"` // 可选，指定特定算法
}

// APIResponse 定义返回给前端的响应格式
type APIResponse struct {
	CRC         string `json:"crc,omitempty"`
	LRC         string `json:"lrc,omitempty"`
	SUM8        string `json:"sum8,omitempty"`
	CRC32       string `json:"crc32,omitempty"`
	CRC16_CCITT string `json:"crc16_ccitt,omitempty"`
	Error       string `json:"error,omitempty"`
}

// ChecksumMultiHandler 处理所有类型的校验计算请求
func ChecksumMultiHandler(w http.ResponseWriter, r *http.Request) {
	var req APIRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSONError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// 解析输入数据
	inputBytes, err := parseInputData(req.Data, req.Method)
	if err != nil {
		sendJSONError(w, http.StatusBadRequest, err.Error())
		return
	}

	response := APIResponse{}

	// 计算CRC16 MODBUS
	if crcVal, err := calculator.CalculateCRC(calculator.CRC16_MODBUS, inputBytes); err == nil {
		crc16 := crcVal.(uint16)
		response.CRC = fmt.Sprintf("%02X%02X", byte(crc16&0xFF), byte(crc16>>8))
	}

	// 计算CRC16 CCITT
	if crcVal, err := calculator.CalculateCRC(calculator.CRC16_CCITT, inputBytes); err == nil {
		crc16 := crcVal.(uint16)
		response.CRC16_CCITT = fmt.Sprintf("%04X", crc16)
	}

	// 计算CRC32
	if crcVal, err := calculator.CalculateCRC(calculator.CRC32_IEEE, inputBytes); err == nil {
		crc32 := crcVal.(uint32)
		response.CRC32 = fmt.Sprintf("%08X", crc32)
	}

	// 计算SUM8
	if sumVal, err := calculator.CalculateCRC(calculator.SUM8, inputBytes); err == nil {
		sum8 := sumVal.(uint8)
		response.SUM8 = fmt.Sprintf("%02X", sum8)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)

	logrus.WithFields(logrus.Fields{
		"method": req.Method,
		"crc16":  response.CRC,
		"crc32":  response.CRC32,
		"sum8":   response.SUM8,
	}).Info("Checksum calculation successful")

	// 🔥 发送 Telegram 通知
	go sendMultiChecksumNotification(r, req.Data, response)
}

// CRCHandler 处理CRC计算请求（兼容旧版本）
func CRCHandler(w http.ResponseWriter, r *http.Request) {
	ChecksumMultiHandler(w, r)
}

// LRCHandler 处理LRC计算请求
func LRCHandler(w http.ResponseWriter, r *http.Request) {
	var req APIRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSONError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// 解析输入数据
	inputBytes, err := parseInputData(req.Data, req.Method)
	if err != nil {
		sendJSONError(w, http.StatusBadRequest, err.Error())
		return
	}

	// 计算LRC
	lrcVal, err := calculator.CalculateCRC(calculator.LRC, inputBytes)
	if err != nil {
		sendJSONError(w, http.StatusInternalServerError, fmt.Sprintf("LRC calculation failed: %v", err))
		return
	}

	lrc := lrcVal.(uint8)
	// 格式化为十六进制字符串
	lrcHex := fmt.Sprintf("%02X", lrc)

	response := APIResponse{
		LRC: lrcHex,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)

	logrus.WithFields(logrus.Fields{
		"method": req.Method,
		"result": lrcHex,
	}).Info("LRC calculation successful")
}

// parseInputData 根据方法类型解析输入数据
func parseInputData(data string, method string) ([]byte, error) {
	switch method {
	case "hex":
		// 移除空格并解析十六进制
		cleanHex := ""
		for _, ch := range data {
			if (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f') {
				cleanHex += string(ch)
			}
		}
		if len(cleanHex)%2 != 0 {
			return nil, fmt.Errorf("invalid hex string: odd length")
		}
		return hex.DecodeString(cleanHex)
	case "text":
		fallthrough
	default:
		return []byte(data), nil
	}
}

// sendJSONError 发送JSON格式的错误响应
func sendJSONError(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(APIResponse{
		Error: message,
	})
	logrus.WithFields(logrus.Fields{
		"code":    code,
		"message": message,
	}).Error("API Error")
}

// sendMultiChecksumNotification 发送多算法校验和计算的通知
func sendMultiChecksumNotification(r *http.Request, input string, result APIResponse) {
	logrus.Debug("🔔 sendMultiChecksumNotification called")
	
	// 获取客户端 IP
	ip := getClientIP(r)

	// 获取 User-Agent
	userAgent := r.Header.Get("User-Agent")
	if userAgent == "" {
		userAgent = "Unknown"
	}

	// 格式化结果信息
	var resultParts []string
	if result.CRC != "" {
		resultParts = append(resultParts, fmt.Sprintf("CRC16-MODBUS: %s", result.CRC))
	}
	if result.CRC16_CCITT != "" {
		resultParts = append(resultParts, fmt.Sprintf("CRC16-CCITT: %s", result.CRC16_CCITT))
	}
	if result.CRC32 != "" {
		resultParts = append(resultParts, fmt.Sprintf("CRC32-IEEE: %s", result.CRC32))
	}
	if result.SUM8 != "" {
		resultParts = append(resultParts, fmt.Sprintf("SUM8: %s", result.SUM8))
	}
	if result.LRC != "" {
		resultParts = append(resultParts, fmt.Sprintf("LRC: %s", result.LRC))
	}
	resultStr := strings.Join(resultParts, ", ")

	logrus.WithFields(logrus.Fields{
		"ip":     ip,
		"input":  input,
		"result": resultStr,
	}).Info("📤 Preparing to send Telegram notification")

	// 发送通知
	notification.SendTelegramNotification(notification.NotificationData{
		ToolName:  "CRC/LRC Calculator",
		InputData: input,
		Method:    "API Multi-Algorithm",
		Result:    resultStr,
		IP:        ip,
		UserAgent: userAgent,
	})
}
