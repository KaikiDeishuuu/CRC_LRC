package handler

import (
	"CRC_LRC/config"
	"CRC_LRC/internal/calculator"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/sirupsen/logrus"
)

// FileChecksumHandler 处理文件上传并计算校验码
func FileChecksumHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, http.StatusMethodNotAllowed, "Only POST method is allowed for file upload")
		return
	}

	// 限制文件大小
	r.ParseMultipartForm(int64(config.Cfg.Checksum.MaxFileUploadSizeMB) << 20) // N MB limit
	file, header, err := r.FormFile("file")
	if err != nil {
		if err == http.ErrMissingFile {
			sendError(w, http.StatusBadRequest, "Missing 'file' in form data")
		} else if err.Error() == "http: request body too large" {
			sendError(w, http.StatusRequestEntityTooLarge, fmt.Sprintf("File size exceeds limit (%d MB)", config.Cfg.Checksum.MaxFileUploadSizeMB))
		} else {
			sendError(w, http.StatusInternalServerError, fmt.Sprintf("Error retrieving file from form: %v", err))
		}
		return
	}
	defer file.Close()

	logrus.WithFields(logrus.Fields{
		"filename": header.Filename,
		"filesize": header.Size,
	}).Info("Received file upload")

	// 读取文件内容
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		sendError(w, http.StatusInternalServerError, fmt.Sprintf("Error reading file content: %v", err))
		return
	}

	results := make(map[calculator.CRCType]CRCResult)

	// CRC16 MODBUS
	if crc16ModbusVal, err := calculator.CalculateCRC(calculator.CRC16_MODBUS, fileBytes); err == nil {
		val := crc16ModbusVal.(uint16)
		hexStr := fmt.Sprintf("0x%02X%02X", byte(val&0xFF), byte(val>>8))
		results[calculator.CRC16_MODBUS] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating file CRC16 MODBUS: %v", err)
	}

	// CRC16 CCITT
	if crc16CcittVal, err := calculator.CalculateCRC(calculator.CRC16_CCITT, fileBytes); err == nil {
		val := crc16CcittVal.(uint16)
		hexStr := fmt.Sprintf("0x%04X", val)
		results[calculator.CRC16_CCITT] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating file CRC16 CCITT: %v", err)
	}

	// CRC32 IEEE
	if crc32IeeeVal, err := calculator.CalculateCRC(calculator.CRC32_IEEE, fileBytes); err == nil {
		val := crc32IeeeVal.(uint32)
		hexStr := fmt.Sprintf("0x%08X", val)
		results[calculator.CRC32_IEEE] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating file CRC32 IEEE: %v", err)
	}

	// SUM8
	if sum8Val, err := calculator.CalculateCRC(calculator.SUM8, fileBytes); err == nil {
		val := sum8Val.(uint8)
		hexStr := fmt.Sprintf("0x%02X", val)
		results[calculator.SUM8] = CRCResult{Decimal: uint64(val), Hex: hexStr}
	} else {
		logrus.Errorf("Error calculating file SUM8: %v", err)
	}

	response := Result{
		Input:         fmt.Sprintf("File: %s (Size: %d bytes)", header.Filename, header.Size),
		InputBytesHex: calculator.BytesToHexString(fileBytes), // 如果文件很大，这里可能不适合展示所有字节
		Results:       results,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
	logrus.WithFields(logrus.Fields{
		"filename": header.Filename,
		"filesize": header.Size,
		"results":  results,
	}).Info("File checksum calculation successful")
}
