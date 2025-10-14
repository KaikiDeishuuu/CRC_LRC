package calculator

import (
	"encoding/hex"
	"fmt"
	"hash/crc32"
)

// BytesToHexString 将字节切片转换为十六进制字符串
func BytesToHexString(data []byte) string {
	return hex.EncodeToString(data)
}

// CalculateCRC 根据指定的CRCType计算校验码
func CalculateCRC(crcType CRCType, data []byte) (interface{}, error) {
	switch crcType {
	case CRC16_MODBUS:
		return calculateCRC16Modbus(data), nil
	case CRC16_CCITT:
		return calculateCRC16CCITT(data), nil
	case CRC32_IEEE:
		return crc32.ChecksumIEEE(data), nil
	case SUM8:
		return calculateSum8(data), nil
	case LRC:
		return calculateLRC(data), nil
	default:
		return nil, fmt.Errorf("unsupported CRC type: %s", crcType)
	}
}

// calculateCRC16Modbus 计算CRC16-MODBUS校验码 (多项式 0xA001)
func calculateCRC16Modbus(data []byte) uint16 {
	var crc uint16 = 0xFFFF // 初始值
	for _, b := range data {
		crc ^= uint16(b)
		for i := 0; i < 8; i++ {
			if crc&0x0001 != 0 {
				crc = (crc >> 1) ^ 0xA001
			} else {
				crc = crc >> 1
			}
		}
	}
	return crc
}

// calculateCRC16CCITT 计算CRC16-CCITT校验码 (多项式 0x1021)
func calculateCRC16CCITT(data []byte) uint16 {
	var crc uint16 = 0xFFFF // 初始值
	for _, b := range data {
		crc ^= (uint16(b) << 8)
		for i := 0; i < 8; i++ {
			if crc&0x8000 != 0 {
				crc = (crc << 1) ^ 0x1021
			} else {
				crc = crc << 1
			}
		}
	}
	return crc
}

// calculateSum8 计算8位累加和校验码
func calculateSum8(data []byte) uint8 {
	var sum uint8 = 0
	for _, b := range data {
		sum += b
	}
	return sum
}

// calculateLRC 计算纵向冗余校验码 (LRC)
// LRC = ((所有字节的和) 取反 + 1) & 0xFF
func calculateLRC(data []byte) uint8 {
	var sum uint8 = 0
	for _, b := range data {
		sum += b
	}
	// 取反加1（二进制补码）
	return (^sum + 1) & 0xFF
}
