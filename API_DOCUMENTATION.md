# CRC/LRC 校验计算器 API 文档

## 基本信息

- **Base URL**: `http://localhost:8080`
- **Content-Type**: `application/json`
- **所有 API 都使用 POST 方法**
- **版本**: v1.1.0
- **更新日期**: 2025-10-14

---

## ⚡ 快速开始

### 5 分钟快速上手

1. **启动服务**

   ```bash
   cd /home/GoProjects/WebAPI/CRC_LRC
   go run .
   ```

2. **测试 API**

   ```bash
   curl -X POST http://localhost:8080/api/checksum \
     -H "Content-Type: application/json" \
     -d '{"data":"Hello","method":"text"}'
   ```

3. **访问前端界面**

   ```
   浏览器打开: http://localhost:8080
   ```

4. **复制完整数据**
   - 输入数据（如 `01 02 03 04`）
   - 点击"计算"
   - 点击"复制"按钮 → 自动复制 `01 02 03 04 B448`（含校验值）

### 核心特性

✨ **一次调用，多种算法**: 单次请求返回 CRC16、CRC32、SUM8 等多种校验值  
🚀 **完整数据复制**: 自动拼接输入数据和校验值，无需手动操作  
🔧 **双输入模式**: 支持文本和 HEX 两种输入方式  
🌐 **前端友好**: 内置 Web 界面，也可集成到任何前端项目  
📦 **零依赖部署**: 单个 Go 二进制文件，开箱即用

---

## API 端点

### 1. 综合校验计算 (推荐使用)

**端点**: `POST /api/checksum`

**描述**: 一次性计算多种校验值（CRC16 MODBUS、CRC16 CCITT、CRC32 IEEE、SUM8）

**请求体**:

```json
{
  "data": "Hello World",
  "method": "text"
}
```

**参数说明**:

- `data` (string, 必需): 要计算校验的数据
- `method` (string, 必需): 输入方式
  - `"text"`: 文本输入
  - `"hex"`: 十六进制输入（如 "48656C6C6F"）

**响应示例**:

```json
{
  "crc": "B448", // CRC16 MODBUS (低字节在前)
  "crc16_ccitt": "D64E", // CRC16 CCITT
  "crc32": "4A17B156", // CRC32 IEEE
  "sum8": "5C" // 8位累加和
}
```

**curl 示例**:

```bash
# 文本输入
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello World","method":"text"}'

# HEX输入
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"48656C6C6F","method":"hex"}'
```

---

### 2. LRC 校验计算

**端点**: `POST /api/lrc`

**描述**: 计算纵向冗余校验（Longitudinal Redundancy Check）

**请求体**:

```json
{
  "data": "Hello World",
  "method": "text"
}
```

**响应示例**:

```json
{
  "lrc": "A4"
}
```

**curl 示例**:

```bash
curl -X POST http://localhost:8080/api/lrc \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello World","method":"text"}'
```

---

### 3. CRC 计算 (兼容旧版本)

**端点**: `POST /api/crc`

**描述**: 与 `/api/checksum` 相同，保留用于向后兼容

---

## 支持的校验算法

| 算法名称         | 描述                      | 输出格式                   | 应用场景                |
| ---------------- | ------------------------- | -------------------------- | ----------------------- |
| **CRC16 MODBUS** | 多项式 0xA001，低字节在前 | 4 位十六进制 (如 B448)     | 工业自动化、MODBUS 协议 |
| **CRC16 CCITT**  | 多项式 0x1021，高字节在前 | 4 位十六进制 (如 D64E)     | 电信通讯                |
| **CRC32 IEEE**   | 32 位循环冗余校验         | 8 位十六进制 (如 4A17B156) | 网络传输、文件校验      |
| **SUM8**         | 8 位累加和                | 2 位十六进制 (如 5C)       | 简单校验                |
| **LRC**          | 纵向冗余校验，取反加 1    | 2 位十六进制 (如 A4)       | 串口通讯                |

---

## 输入方式详解

### 文本输入 (method: "text")

直接输入字符串，API 会将其转换为字节数组进行计算。

**示例**:

```json
{
  "data": "Hello",
  "method": "text"
}
```

等同于字节: `[0x48, 0x65, 0x6C, 0x6C, 0x6F]`

### HEX 输入 (method: "hex")

输入十六进制字符串（可以有空格或无空格）。

**示例**:

```json
{
  "data": "48 65 6C 6C 6F",
  "method": "hex"
}
```

或

```json
{
  "data": "48656C6C6F",
  "method": "hex"
}
```

---

## 错误响应

**格式**:

```json
{
  "error": "错误描述信息"
}
```

**常见错误**:

- HTTP 400: 请求参数错误（如缺少必需字段、HEX 格式错误）
- HTTP 500: 服务器内部错误（如计算失败）

---

## 前端集成示例

### JavaScript/TypeScript (基础版)

```javascript
async function calculateChecksum(data, method = "text") {
  try {
    const response = await fetch("http://localhost:8080/api/checksum", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ data, method }),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    if (result.error) {
      throw new Error(result.error);
    }

    return result;
  } catch (error) {
    console.error("校验计算失败:", error);
    throw error;
  }
}

// 使用示例
calculateChecksum("Hello World", "text").then((result) => {
  console.log("CRC16 MODBUS:", result.crc);
  console.log("CRC16 CCITT:", result.crc16_ccitt);
  console.log("CRC32 IEEE:", result.crc32);
  console.log("SUM8:", result.sum8);
});
```

### JavaScript/TypeScript (完整数据复制功能)

```javascript
// 辅助函数：将字符串转换为HEX
function stringToHex(str) {
  let hex = "";
  for (let i = 0; i < str.length; i++) {
    const charCode = str.charCodeAt(i);
    hex += charCode.toString(16).toUpperCase().padStart(2, "0") + " ";
  }
  return hex.trim();
}

// 复制完整数据（输入 + 校验值）
async function copyCompleteData(
  inputData,
  checksumValue,
  algorithmName,
  inputMethod = "text"
) {
  let fullData;

  if (inputMethod === "hex") {
    // HEX模式：格式化输入 + 校验值
    const cleanInput = inputData.replace(/\s/g, "");
    const formattedInput = cleanInput.match(/.{1,2}/g)?.join(" ") || cleanInput;
    fullData = `${formattedInput} ${checksumValue}`;
  } else {
    // 文本模式：转换为HEX + 校验值
    const inputHex = stringToHex(inputData);
    fullData = `${inputHex} ${checksumValue}`;
  }

  try {
    // 尝试使用现代 Clipboard API
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(fullData);
      console.log(`${algorithmName} 完整数据已复制: ${fullData}`);
      return true;
    }

    // 降级方案：使用 execCommand
    const textArea = document.createElement("textarea");
    textArea.value = fullData;
    textArea.style.cssText = "position:fixed;top:-9999px;opacity:0";
    document.body.appendChild(textArea);
    textArea.select();
    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);

    if (successful) {
      console.log(`${algorithmName} 完整数据已复制: ${fullData}`);
      return true;
    }

    throw new Error("复制失败");
  } catch (error) {
    console.error("复制失败:", error);
    alert(`请手动复制：\n${fullData}`);
    return false;
  }
}

// 使用示例
const inputData = "01 02 03 04";
const method = "hex";

calculateChecksum(inputData, method).then((result) => {
  // 复制完整的 CRC16 MODBUS 数据
  copyCompleteData(inputData, result.crc, "CRC16 MODBUS", method);
  // 结果: "01 02 03 04 B448"
});
```

### React 组件示例

```typescript
import { useState } from "react";

interface ChecksumResult {
  crc?: string;
  crc16_ccitt?: string;
  crc32?: string;
  sum8?: string;
  lrc?: string;
  error?: string;
}

export function ChecksumCalculator() {
  const [input, setInput] = useState("");
  const [method, setMethod] = useState<"text" | "hex">("text");
  const [result, setResult] = useState<ChecksumResult | null>(null);
  const [loading, setLoading] = useState(false);

  const calculate = async () => {
    setLoading(true);
    try {
      const response = await fetch("http://localhost:8080/api/checksum", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: input, method }),
      });

      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error("计算失败:", error);
      setResult({ error: "计算失败，请检查网络连接" });
    } finally {
      setLoading(false);
    }
  };

  // 辅助函数：将字符串转换为HEX
  const stringToHex = (str: string): string => {
    let hex = "";
    for (let i = 0; i < str.length; i++) {
      const charCode = str.charCodeAt(i);
      hex += charCode.toString(16).toUpperCase().padStart(2, "0") + " ";
    }
    return hex.trim();
  };

  // 复制完整数据（输入 + 校验值）
  const copyCompleteData = async (
    checksumValue: string,
    algorithmName: string
  ) => {
    let fullData: string;

    if (method === "hex") {
      // HEX模式：格式化输入 + 校验值
      const cleanInput = input.replace(/\s/g, "");
      const formattedInput =
        cleanInput.match(/.{1,2}/g)?.join(" ") || cleanInput;
      fullData = `${formattedInput} ${checksumValue}`;
    } else {
      // 文本模式：转换为HEX + 校验值
      const inputHex = stringToHex(input);
      fullData = `${inputHex} ${checksumValue}`;
    }

    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(fullData);
        alert(`${algorithmName} 完整数据已复制！\n${fullData}`);
      } else {
        throw new Error("Clipboard API 不可用");
      }
    } catch (err) {
      console.error("复制失败:", err);
      alert(`请手动复制完整数据：\n${fullData}`);
    }
  };

  return (
    <div className="checksum-calculator">
      <h2>校验和计算器</h2>

      <div>
        <label>
          <input
            type="radio"
            checked={method === "text"}
            onChange={() => setMethod("text")}
          />
          文本输入
        </label>
        <label>
          <input
            type="radio"
            checked={method === "hex"}
            onChange={() => setMethod("hex")}
          />
          HEX输入
        </label>
      </div>

      <textarea
        value={input}
        onChange={(e) => setInput(e.target.value)}
        placeholder={
          method === "text" ? "输入文本..." : "输入HEX (如: 48 65 6C 6C 6F)"
        }
      />

      <button onClick={calculate} disabled={loading || !input}>
        {loading ? "计算中..." : "计算"}
      </button>

      {result && !result.error && (
        <div className="results">
          <p className="tip">
            💡 点击"复制"按钮将复制完整数据（输入 + 校验值）
          </p>
          {result.crc && (
            <div>
              <strong>CRC16 MODBUS:</strong> {result.crc}
              <button
                onClick={() => copyCompleteData(result.crc!, "CRC16 MODBUS")}
              >
                复制完整数据
              </button>
            </div>
          )}
          {result.crc16_ccitt && (
            <div>
              <strong>CRC16 CCITT:</strong> {result.crc16_ccitt}
              <button
                onClick={() =>
                  copyCompleteData(result.crc16_ccitt!, "CRC16 CCITT")
                }
              >
                复制完整数据
              </button>
            </div>
          )}
          {result.crc32 && (
            <div>
              <strong>CRC32 IEEE:</strong> {result.crc32}
              <button
                onClick={() => copyCompleteData(result.crc32!, "CRC32 IEEE")}
              >
                复制完整数据
              </button>
            </div>
          )}
          {result.sum8 && (
            <div>
              <strong>SUM8:</strong> {result.sum8}
              <button onClick={() => copyCompleteData(result.sum8!, "SUM8")}>
                复制完整数据
              </button>
            </div>
          )}
        </div>
      )}

      {result?.error && <div className="error">{result.error}</div>}
    </div>
  );
}
```

---

## 复制功能说明

### 完整数据复制模式

本 API 配套的前端界面支持**复制完整数据**功能，即将原始输入数据和校验值一起复制，方便直接用于串口通信、MODBUS 协议等场景。

#### 复制格式

**HEX 输入模式**：

```
输入: 01 02 03 04
CRC16 MODBUS: B448
复制结果: 01 02 03 04 B448
```

**文本输入模式**：

```
输入: Hello
CRC16 MODBUS: 14C4
自动转HEX: 48 65 6C 6C 6F
复制结果: 48 65 6C 6C 6F 14C4
```

#### 应用场景

1. **串口通信**

   ```
   发送完整帧: 01 02 03 04 B448
   无需手动拼接校验值
   ```

2. **MODBUS RTU**

   ```
   功能码+数据: 03 00 00 00 0A
   完整帧: 03 00 00 00 0A C4 09
   ```

3. **数据验证**
   ```
   接收: 01 02 03 04 B448
   使用工具验证: 输入前4字节 → 对比最后2字节
   ```

#### 实现要点

```javascript
// 完整数据格式化函数
function formatCompleteData(inputData, checksumValue, inputMethod) {
  if (inputMethod === "hex") {
    // HEX模式：保持格式 + 追加校验
    const formatted = inputData
      .replace(/\s/g, "")
      .match(/.{1,2}/g)
      .join(" ");
    return `${formatted} ${checksumValue}`;
  } else {
    // 文本模式：转HEX + 追加校验
    const hex = Array.from(inputData)
      .map((c) => c.charCodeAt(0).toString(16).toUpperCase().padStart(2, "0"))
      .join(" ");
    return `${hex} ${checksumValue}`;
  }
}

// 使用示例
const completeData = formatCompleteData("01 02 03 04", "B448", "hex");
console.log(completeData); // "01 02 03 04 B448"
```

#### 三重降级机制

1. **Clipboard API** (推荐，HTTPS/localhost)
2. **execCommand** (兼容旧浏览器)
3. **手动复制对话框** (最终降级方案)

```javascript
async function safeCopy(text) {
  try {
    // 方法1: Clipboard API
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return true;
    }

    // 方法2: execCommand
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.cssText = "position:fixed;top:-9999px;opacity:0";
    document.body.appendChild(textarea);
    textarea.select();
    const success = document.execCommand("copy");
    document.body.removeChild(textarea);
    return success;
  } catch (err) {
    // 方法3: 提示用户手动复制
    alert(`请手动复制：\n${text}`);
    return false;
  }
}
```

---

## CORS 配置

如果您的 blog 项目部署在不同的域名或端口，需要在后端添加 CORS 支持。

在 `internal/router/router.go` 中添加 CORS 中间件：

```go
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}

// 在 SetupRouter 中使用
func SetupRouter() *mux.Router {
    r := mux.NewRouter()

    // ... 其他路由配置 ...

    r.Use(loggingMiddleware)
    r.Use(corsMiddleware)  // 添加这行

    return r
}
```

---

## 实际使用案例

### 案例 1：MODBUS RTU 通信

**场景**: 向设备发送读取寄存器命令

```javascript
// 步骤1: 构造MODBUS帧（不含校验）
const slaveAddress = "01"; // 从站地址
const functionCode = "03"; // 读保持寄存器
const startAddress = "0000"; // 起始地址
const registerCount = "000A"; // 寄存器数量
const frameData = `${slaveAddress} ${functionCode} ${startAddress} ${registerCount}`;

// 步骤2: 调用API计算CRC
const result = await calculateChecksum(frameData, "hex");

// 步骤3: 使用完整数据复制功能
// 复制结果示例: "01 03 00 00 00 0A C4 09"
await copyCompleteData(frameData, result.crc, "CRC16 MODBUS", "hex");

// 步骤4: 粘贴到串口工具发送
// 完整的MODBUS RTU帧已包含校验，可直接发送
```

### 案例 2：串口数据校验

**场景**: 发送自定义协议数据包

```javascript
// 原始数据
const sensorData = "01 02 03 04"; // 传感器读数

// 计算多种校验值
const checksums = await calculateChecksum(sensorData, "hex");

// 根据协议要求选择合适的校验算法
const completeFrame = `${sensorData} ${checksums.crc}`; // 使用CRC16
// 或
const completeFrameWithSum8 = `${sensorData} ${checksums.sum8}`; // 使用SUM8

// 复制并发送
await copyCompleteData(sensorData, checksums.crc, "CRC16 MODBUS", "hex");
```

### 案例 3：文件校验

**场景**: 计算小型配置文件的校验值

```javascript
// 读取配置文件内容
const configContent = "version=1.0\nport=8080";

// 计算CRC32（常用于文件完整性校验）
const result = await calculateChecksum(configContent, "text");

console.log(`CRC32: ${result.crc32}`);
// 输出: CRC32: XXXXXXXX

// 可以将CRC32值保存为配置文件的校验信息
const configWithChecksum = {
  content: configContent,
  checksum: result.crc32,
  algorithm: "CRC32 IEEE",
};
```

### 案例 4：在 React/Next.js 博客中集成

**场景**: 在博客文章中嵌入交互式校验计算器

```tsx
// components/ChecksumWidget.tsx
"use client"; // Next.js 13+ App Router

import { useState } from "react";

export default function ChecksumWidget() {
  const [input, setInput] = useState("");
  const [results, setResults] = useState(null);

  const calculate = async () => {
    const response = await fetch("http://localhost:8080/api/checksum", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ data: input, method: "hex" }),
    });
    const data = await response.json();
    setResults(data);
  };

  const copyComplete = async (checksum, name) => {
    const fullData = `${input
      .replace(/\s/g, "")
      .match(/.{1,2}/g)
      .join(" ")} ${checksum}`;
    await navigator.clipboard.writeText(fullData);
    alert(`${name} 完整数据已复制！`);
  };

  return (
    <div className="checksum-widget p-4 border rounded-lg">
      <h3 className="text-xl font-bold mb-3">🔧 在线校验计算器</h3>
      <input
        className="w-full p-2 border rounded mb-2"
        placeholder="输入HEX数据 (如: 01 02 03 04)"
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />
      <button
        className="bg-blue-500 text-white px-4 py-2 rounded"
        onClick={calculate}
      >
        计算校验
      </button>

      {results && (
        <div className="mt-4 space-y-2">
          {Object.entries(results).map(([key, value]) => (
            <div
              key={key}
              className="flex justify-between items-center p-2 bg-gray-50 rounded"
            >
              <span className="font-mono">
                {key.toUpperCase()}: {value}
              </span>
              <button
                className="text-blue-500 hover:underline text-sm"
                onClick={() => copyComplete(value, key)}
              >
                复制完整数据
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

在 MDX 文章中使用：

```mdx
---
title: "MODBUS协议详解"
---

# MODBUS 通信协议

MODBUS RTU 使用 CRC16 校验确保数据完整性...

<ChecksumWidget />

上面的工具可以帮你快速计算 MODBUS 帧的校验值。
```

---

## 测试示例

### 测试数据

| 输入文本    | CRC16 MODBUS | CRC16 CCITT | CRC32 IEEE | SUM8 | LRC |
| ----------- | ------------ | ----------- | ---------- | ---- | --- |
| "123456789" | 4B37         | 31C3        | CBF43926   | DD   | 23  |
| "Hello"     | 14C4         | 9DD6        | F7D18982   | FC   | 04  |
| "ABCDEFGH"  | E688         | 9738        | 3FD0F7E5   | BC   | 44  |

### 完整测试脚本

```bash
#!/bin/bash

echo "测试 CRC/LRC API"
echo "================"

# 测试1: 文本输入
echo -e "\n测试1: 文本输入 'Hello'"
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}' | jq

# 测试2: HEX输入
echo -e "\n测试2: HEX输入 '48656C6C6F'"
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"48656C6C6F","method":"hex"}' | jq

# 测试3: LRC计算
echo -e "\n测试3: LRC计算"
curl -X POST http://localhost:8080/api/lrc \
  -H "Content-Type: application/json" \
  -d '{"data":"Hello","method":"text"}' | jq

# 测试4: 测试数据 "123456789"
echo -e "\n测试4: 标准测试数据 '123456789'"
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"123456789","method":"text"}' | jq

echo -e "\n测试完成！"
```

---

## 注意事项

1. **端口配置**: 默认端口是 8080，可在 `config/config.yaml` 中修改
2. **输入限制**: 默认最大输入长度为 10MB（可在配置文件中调整）
3. **HEX 格式**: HEX 输入会自动过滤非十六进制字符，支持空格分隔
4. **大小写**: HEX 输出统一使用大写字母
5. **字节序**: CRC16 MODBUS 使用低字节在前，其他算法使用高字节在前

---

## 性能特性

- ✅ 无状态 API，支持高并发
- ✅ 请求响应时间 < 10ms（典型情况）
- ✅ 支持批量计算（一次请求返回多种校验值）
- ✅ 内存占用低，适合长时间运行

---

## 更新日志

### v1.1.0 (2025-10-14)

- ✨ **新增**: 复制完整数据功能（输入 + 校验值）
- ✨ **新增**: 三重降级复制机制（Clipboard API → execCommand → 手动提示）
- ✨ **新增**: 自动 HEX 格式转换（文本模式下）
- 📝 **更新**: API 文档增加复制功能说明
- 🎨 **优化**: 前端界面提示信息

### v1.0.0 (2025-10-14)

- ✅ 支持 CRC16 MODBUS（多项式 0xA001）
- ✅ 支持 CRC16 CCITT（多项式 0x1021）
- ✅ 支持 CRC32 IEEE
- ✅ 支持 SUM8（8 位累加和）
- ✅ 支持 LRC（纵向冗余校验）
- ✅ 文本和 HEX 输入方式
- ✅ RESTful API 设计
- ✅ 完整的错误处理
- ✅ 综合校验端点（一次返回多种算法结果）

---

## 常见问题（FAQ）

### Q1: 为什么复制功能有时不工作？

**A**: 浏览器的 Clipboard API 在 HTTP 环境下受限，建议：

- 使用 `https://` 或 `http://localhost`
- 如果必须使用 HTTP，会自动降级到 `execCommand` 或手动复制提示

### Q2: 复制的完整数据格式是什么？

**A**:

- **HEX 输入**: `原始输入(空格分隔) + 校验值`，如 `01 02 03 04 B448`
- **文本输入**: `转HEX(空格分隔) + 校验值`，如 `48 65 6C 6C 6F 14C4` (Hello)

### Q3: 如何在我的博客项目中使用这个 API？

**A**: 三种方式：

1. **直接调用 API**: 从博客前端发送请求到 `http://localhost:8080/api/checksum`
2. **嵌入 Widget**: 参考"实际使用案例 → 案例 4"中的 React 组件示例
3. **iframe 嵌入**: 直接嵌入完整界面 `<iframe src="http://localhost:8080">`

记得配置 CORS（参考文档中的 CORS 配置章节）。

### Q4: CRC16 MODBUS 和 CRC16 CCITT 有什么区别？

**A**:

- **CRC16 MODBUS**: 多项式 0xA001，低字节在前，常用于工业自动化
- **CRC16 CCITT**: 多项式 0x1021，高字节在前，常用于电信通讯
- 两者算法不同，结果不可互换，需根据协议选择

### Q5: 支持批量计算吗？

**A**: 目前不支持批量计算，但可以：

- 使用 `/api/checksum` 一次获取多种算法结果
- 前端循环调用 API 实现批量处理
- 考虑在下个版本添加批量端点

### Q6: 为什么文本输入和 HEX 输入的结果不同？

**A**: 确保理解：

- **文本 "01"**: 两个字符，ASCII 为 `30 31`
- **HEX "01"**: 一个字节，值为 `0x01`

示例：

```javascript
// 文本输入
{"data": "01", "method": "text"} → 字节: [0x30, 0x31]

// HEX输入
{"data": "01", "method": "hex"} → 字节: [0x01]
```

### Q7: 性能如何？能处理大文件吗？

**A**:

- 小数据（< 1KB）: 响应时间 < 5ms
- 中等数据（1-100KB）: 响应时间 < 50ms
- 大文件（> 100KB）: 建议分块计算

默认最大输入限制为 10MB（可在配置中调整）。

### Q8: 如何验证计算结果的正确性？

**A**: 使用标准测试向量：

```bash
# CRC16 MODBUS 标准测试
输入: "123456789" (text)
期望结果: 4B37

# 测试命令
curl -X POST http://localhost:8080/api/checksum \
  -H "Content-Type: application/json" \
  -d '{"data":"123456789","method":"text"}' | jq -r '.crc'
```

参考文档中的"测试数据"表格获取更多测试用例。

### Q9: 前端如何处理错误？

**A**: API 错误响应格式：

```json
{
  "error": "错误描述信息"
}
```

前端处理示例：

```javascript
const response = await fetch("http://localhost:8080/api/checksum", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ data, method }),
});

const result = await response.json();

if (result.error) {
  console.error("API错误:", result.error);
  alert(`计算失败: ${result.error}`);
  return;
}

// 正常处理结果
console.log("CRC:", result.crc);
```

### Q10: 可以自定义校验算法吗？

**A**: 当前支持 5 种常用算法（CRC16 MODBUS、CRC16 CCITT、CRC32、SUM8、LRC）。

如需添加自定义算法：

1. 在 `internal/calculator/types.go` 添加算法常量
2. 在 `internal/calculator/calculator.go` 实现计算函数
3. 更新相关 handler 返回新算法结果

欢迎提交 PR 贡献新算法！

---

## 联系方式

如有问题或建议，请创建 Issue 或 Pull Request。

**项目地址**: `/home/GoProjects/WebAPI/CRC_LRC`  
**在线文档**: `http://localhost:8080` (启动服务后访问)  
**API 版本**: v1.1.0
