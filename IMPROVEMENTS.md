# CRC/LRC 校验工具改进说明

## 🎉 新增功能

### 1. 输入格式选择器
- **位置**：在线测试表单中
- **功能**：
  - 下拉框选择输入格式（文本字符串 / 十六进制）
  - 选择 HEX 格式时，自动移除 `0x` 前缀要求
  - 支持带空格的十六进制输入（如：`33 01 13 00`）
  - 自动过滤非法字符（十六进制模式下只允许 0-9, A-F）

### 2. 十六进制显示优化
- **格式**：两个数字一组，空格分隔
- **示例**：`33 01 13 00 FF AB CD EF`
- **实现**：
  - 输入时支持任意空格分隔
  - 输出时统一格式化为 `XX XX XX` 格式
  - 大写显示，更易读

### 3. 文档优化

#### API 文档改进
- ✅ 清晰的分段结构（使用 emoji 图标）
- ✅ 详细的输入格式说明
- ✅ 文件上传要求详细列表
- ✅ 支持的文件格式明确说明
- ✅ 校验算法对照表

#### 文件上传文档
详细说明：
- **Content-Type**: `multipart/form-data`
- **字段名**: `file`
- **支持格式**: .bin, .hex, .txt, .dat 等任意格式
- **文件大小限制**: 最大 10 MB

#### 校验算法对照表
| 算法 | 说明 | 应用场景 |
|------|------|----------|
| CRC16_MODBUS | 多项式 0xA001，初始值 0xFFFF | Modbus 协议、工业通信 |
| CRC16_CCITT | 多项式 0x1021，初始值 0xFFFF | X.25 协议、蓝牙通信 |
| CRC32_IEEE | 标准 CRC32（IEEE 802.3） | 以太网、ZIP、PNG、MPEG-2 |
| SUM8 | 8位累加和校验 | 简单校验、NMEA 协议 |

## 🔧 使用示例

### 文本输入示例
1. 选择格式：**文本字符串 (Text)**
2. 输入：`HelloGo`
3. 点击"计算校验和"

### 十六进制输入示例
1. 选择格式：**十六进制 (HEX)**
2. 输入：`33 01 13 00` 或 `33011300`
3. 无需添加 `0x` 前缀
4. 点击"计算校验和"

### 文件上传示例
1. 点击"选择文件"
2. 选择任意二进制文件（.bin, .hex, .txt 等）
3. 点击"上传并计算"
4. 查看文件的校验和结果

## 📊 输出格式

### 标准响应
```json
{
  "input": "33011300",
  "inputBytesHex": "33011300",
  "inputBytesHexFormatted": "33 01 13 00",  // 新增：格式化显示
  "results": {
    "CRC16_MODBUS": {
      "decimal": 4508,
      "hex": "0x9C11"
    },
    "CRC16_CCITT": {
      "decimal": 57321,
      "hex": "0xDFE9"
    },
    "CRC32_IEEE": {
      "decimal": 3908787782,
      "hex": "0xE8FB5E46"
    },
    "SUM8": {
      "decimal": 71,
      "hex": "0x47"
    }
  }
}
```

## 🎨 界面改进
- ✅ 中文提示信息
- ✅ 实时输入格式切换
- ✅ 智能占位符提示
- ✅ 输入示例显示
- ✅ 美观的表格样式
- ✅ emoji 图标增强可读性

## 🚀 技术实现

### 前端 JavaScript 功能
```javascript
// 十六进制格式化函数
function formatHexString(hexStr) {
    hexStr = hexStr.replace(/\s+/g, '').replace(/^0x/i, '');
    return hexStr.match(/.{1,2}/g)?.join(' ').toUpperCase() || hexStr;
}

// 输入格式切换
inputFormatSelect.addEventListener('change', function() {
    // 动态更新占位符和提示
});

// 自动字符过滤（HEX 模式）
inputStringField.addEventListener('input', function() {
    if (inputFormatSelect.value === 'hex') {
        const cleanValue = oldValue.replace(/[^0-9a-fA-F\s]/g, '');
        this.value = cleanValue;
    }
});
```

## 📝 注意事项

1. **十六进制输入**：
   - 可以使用空格分隔（`33 01 13 00`）
   - 也可以连续输入（`33011300`）
   - 不需要 `0x` 前缀（系统自动添加）

2. **文件上传**：
   - 最大文件大小可在 `config/config.yaml` 中修改
   - 大文件的十六进制显示会被截断（仅显示前100字节）

3. **响应格式**：
   - 所有响应包含原始和格式化的十六进制显示
   - 格式化版本便于人类阅读

## 🔄 版本历史

### v1.1.0 (当前版本)
- ✅ 添加输入格式选择器
- ✅ 优化十六进制显示格式
- ✅ 完善 API 文档
- ✅ 改进用户界面
- ✅ 中文本地化

### v1.0.0
- ✅ 基础 CRC/校验和计算功能
- ✅ 文件上传支持
- ✅ RESTful API
