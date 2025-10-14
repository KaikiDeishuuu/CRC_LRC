package handler

import (
	"CRC_LRC/config"
	"CRC_LRC/internal/calculator"
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	logrus.WithFields(logrus.Fields{
		"input":           inputStr,
		"input_bytes_hex": response.InputBytesHex,
		"results":         response.Results,
	}).Info("Checksum calculation successful")
}
