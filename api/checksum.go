// api/checksum.go
// Vercel Serverless Function for CRC/LRC calculation
package handler

import (
"encoding/hex"
"encoding/json"
"fmt"
"hash/crc32"
"net/http"
"strings"
)

// APIRequest 定义前端发送的请求格式
type APIRequest struct {
Data   string `json:"data"`
Method string `json:"method"` // "text" 或 "hex"
}

// APIResponse 定义返回给前端的响应格式
type APIResponse struct {
CRC         string `json:"crc,omitempty"`
CRC16_CCITT string `json:"crc16_ccitt,omitempty"`
CRC32       string `json:"crc32,omitempty"`
SUM8        string `json:"sum8,omitempty"`
LRC         string `json:"lrc,omitempty"`
Error       string `json:"error,omitempty"`
}

// Handler - Vercel Serverless Function 入口
func Handler(w http.ResponseWriter, r *http.Request) {
// CORS 头
w.Header().Set("Access-Control-Allow-Origin", "*")
w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

if r.Method == "OPTIONS" {
w.WriteHeader(http.StatusOK)
return
}

if r.Method != "POST" {
sendJSONError(w, http.StatusMethodNotAllowed, "Only POST method is allowed")
return
}

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

// 计算 CRC16 MODBUS
crc16 := calculateCRC16Modbus(inputBytes)
response.CRC = fmt.Sprintf("%02X%02X", byte(crc16&0xFF), byte(crc16>>8))

// 计算 CRC16 CCITT
crc16ccitt := calculateCRC16CCITT(inputBytes)
response.CRC16_CCITT = fmt.Sprintf("%04X", crc16ccitt)

// 计算 CRC32
crc32val := crc32.ChecksumIEEE(inputBytes)
response.CRC32 = fmt.Sprintf("%08X", crc32val)

// 计算 SUM8
sum8 := calculateSum8(inputBytes)
response.SUM8 = fmt.Sprintf("%02X", sum8)

// 计算 LRC
lrc := calculateLRC(inputBytes)
response.LRC = fmt.Sprintf("%02X", lrc)

w.Header().Set("Content-Type", "application/json")
json.NewEncoder(w).Encode(response)
}

// parseInputData 根据方法类型解析输入数据
func parseInputData(data string, method string) ([]byte, error) {
if method == "hex" {
// 移除空格和常见分隔符
cleanHex := strings.ReplaceAll(data, " ", "")
cleanHex = strings.ReplaceAll(cleanHex, "-", "")
cleanHex = strings.ReplaceAll(cleanHex, ":", "")
cleanHex = strings.ToLower(cleanHex)

// 移除 0x 前缀
cleanHex = strings.TrimPrefix(cleanHex, "0x")

return hex.DecodeString(cleanHex)
}
return []byte(data), nil
}

// sendJSONError 发送JSON格式的错误响应
func sendJSONError(w http.ResponseWriter, code int, message string) {
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(code)
json.NewEncoder(w).Encode(APIResponse{Error: message})
}

// calculateCRC16Modbus 计算CRC16-MODBUS校验码 (多项式 0xA001)
func calculateCRC16Modbus(data []byte) uint16 {
crc := uint16(0xFFFF)
for _, b := range data {
crc ^= uint16(b)
for i := 0; i < 8; i++ {
if crc&1 != 0 {
crc = (crc >> 1) ^ 0xA001
} else {
crc >>= 1
}
}
}
return crc
}

// calculateCRC16CCITT 计算CRC16-CCITT校验码 (多项式 0x1021)
func calculateCRC16CCITT(data []byte) uint16 {
crc := uint16(0xFFFF)
for _, b := range data {
crc ^= uint16(b) << 8
for i := 0; i < 8; i++ {
if crc&0x8000 != 0 {
crc = (crc << 1) ^ 0x1021
} else {
crc <<= 1
}
}
}
return crc
}

// calculateSum8 计算8位累加和校验码
func calculateSum8(data []byte) uint8 {
var sum uint8
for _, b := range data {
sum += b
}
return sum
}

// calculateLRC 计算纵向冗余校验
func calculateLRC(data []byte) uint8 {
var lrc uint8
for _, b := range data {
lrc += b
}
return (^lrc) + 1
}
