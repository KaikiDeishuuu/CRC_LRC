package main

import (
	"CRC_LRC/internal/calculator"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
)

// Result 结构体定义了API返回的JSON格式
type Result struct {
	Input         string `json:"input"`
	InputBytesHex string `json:"inputBytesHex"`
	CRC16Dec      uint16 `json:"crc16Dec"`
	CRC16Hex      string `json:"crc16Hex"`
	CRC32Dec      uint32 `json:"crc32Dec"`
	CRC32Hex      string `json:"crc32Hex"`
	SumDec        uint8  `json:"sumDec"`
	SumHex        string `json:"sumHex"`
	Error         string `json:"error,omitempty"`
}

// ChecksumHandler 处理校验请求
func ChecksumHandler(w http.ResponseWriter, r *http.Request) {
	// 设置响应头为JSON
	w.Header().Set("Content-Type", "application/json")

	// 获取查询参数
	inputStr := r.URL.Query().Get("input")
	if inputStr == "" {
		http.Error(w, `{"error": "Missing 'input' query parameter"}`, http.StatusBadRequest)
		return
	}

	// 尝试将输入字符串转换为字节，支持十六进制字符串和普通字符串
	var inputBytes []byte
	// 假设如果字符串以 "0x" 或 "0X" 开头，我们尝试将其解析为十六进制
	if len(inputStr) > 2 && (inputStr[0:2] == "0x" || inputStr[0:2] == "0X") {
		// 移除前缀并尝试解码
		var err error
		inputBytes, err = hex.DecodeString(inputStr[2:])
		if err != nil {
			http.Error(w, fmt.Sprintf(`{"error": "Invalid hex input: %v"}`, err), http.StatusBadRequest)
			return
		}
	} else {
		// 否则，将其视为普通字符串的UTF-8编码
		inputBytes = []byte(inputStr)
	}

	// 计算CRC16 (使用 MODBUS)
	var crc16Val uint16
	if val, err := calculator.CalculateCRC(calculator.CRC16_MODBUS, inputBytes); err == nil {
		crc16Val = val.(uint16)
	}
	crc16Hex := fmt.Sprintf("0x%02X%02X", byte(crc16Val&0xFF), byte(crc16Val>>8)) // 格式化为16进制字符串

	// 计算CRC32
	var crc32Val uint32
	if val, err := calculator.CalculateCRC(calculator.CRC32_IEEE, inputBytes); err == nil {
		crc32Val = val.(uint32)
	}
	crc32Hex := fmt.Sprintf("0x%08X", crc32Val) // 格式化为16进制字符串

	// 计算累加和
	var sumVal uint8
	if val, err := calculator.CalculateCRC(calculator.SUM8, inputBytes); err == nil {
		sumVal = val.(uint8)
	}
	sumHex := fmt.Sprintf("0x%02X", sumVal) // 格式化为16进制字符串

	// 构造结果
	result := Result{
		Input:         inputStr,
		InputBytesHex: calculator.BytesToHexString(inputBytes),
		CRC16Dec:      crc16Val,
		CRC16Hex:      crc16Hex,
		CRC32Dec:      crc32Val,
		CRC32Hex:      crc32Hex,
		SumDec:        sumVal,
		SumHex:        sumHex,
	}

	// 将结果编码为JSON并发送
	json.NewEncoder(w).Encode(result)
}

// 首页处理器
func HomeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprintf(w, `
	<!DOCTYPE html>
	<html>
	<head>
		<title>CRC/Checksum API</title>
		<style>
			body { font-family: sans-serif; margin: 2em; }
			pre { background-color: #eee; padding: 1em; border-radius: 4px; }
			code { background-color: #f8f8f8; padding: 2px 4px; border-radius: 3px; }
		</style>
	</head>
	<body>
		<h1>CRC / Checksum API Tool</h1>
		<p>Use the <code>/checksum</code> endpoint to calculate CRC16, CRC32, and Sum checksums.</p>
		<h2>Usage:</h2>
		<p><code>GET /checksum?input=YOUR_STRING_OR_HEX</code></p>
		<h3>Examples:</h3>
		<p><strong>String Input:</strong></p>
		<pre><code>/checksum?input=HelloGo</code></pre>
		<p><strong>Hexadecimal Input (prefix with 0x):</strong></p>
		<pre><code>/checksum?input=0x48656C6C6F476F</code></pre>
		<h3>Example Response:</h3>
		<pre><code>{
	"input": "HelloGo",
	"inputBytesHex": "48656c6c6f476f",
	"crc16Dec": 57975,
	"crc16Hex": "0xE277",
	"crc32Dec": 3762696614,
	"crc32Hex": "0xDFF7B826",
	"sumDec": 72,
	"sumHex": "0x48"
}</code></pre>
	</body>
	</html>
	`)
}
