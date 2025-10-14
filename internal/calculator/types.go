package calculator

// CRCType 定义CRC算法的类型
type CRCType string

const (
	CRC16_MODBUS CRCType = "CRC16_MODBUS" // 多项式 0xA001, 初始值 0xFFFF, 翻转输入/输出
	CRC16_CCITT  CRCType = "CRC16_CCITT"  // 多项式 0x1021, 初始值 0xFFFF, 无翻转
	CRC32_IEEE   CRCType = "CRC32_IEEE"   // 标准库实现
	SUM8         CRCType = "SUM8"         // 8位累加和
	LRC          CRCType = "LRC"          // 纵向冗余校验 (Longitudinal Redundancy Check)
)

// CRCConfig 存储不同CRC算法的配置
type CRCConfig struct {
	Polynomial   uint16 // CRC多项式 (仅CRC16/CRC8有效)
	InitialValue uint16 // 初始值 (仅CRC16/CRC8有效)
	XOROut       uint16 // 异或输出值 (仅CRC16/CRC8有效)
	ReflectIn    bool   // 反射输入字节
	ReflectOut   bool   // 反射输出字节
}

var crc16Configs = map[CRCType]CRCConfig{
	CRC16_MODBUS: {
		Polynomial:   0xA001, // 0x8005 反转
		InitialValue: 0xFFFF,
		XOROut:       0x0000,
		ReflectIn:    true,
		ReflectOut:   true,
	},
	CRC16_CCITT: {
		Polynomial:   0x1021,
		InitialValue: 0xFFFF,
		XOROut:       0x0000,
		ReflectIn:    false,
		ReflectOut:   false,
	},
	// 可以添加更多CRC16标准
}
