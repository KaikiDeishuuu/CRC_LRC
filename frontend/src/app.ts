// CRC/LRC 校验计算器 - 完整功能版本

// ==================== 类型定义 ====================
interface CalculationResult {
  type: string;
  value: string;
  description: string;
}

interface APIResponse {
  crc?: string;
  lrc?: string;
  sum8?: string;
  crc32?: string;
  crc16_ccitt?: string;
  error?: string;
}

// ==================== 全局状态 ====================
let currentInputMethod: "text" | "hex" = "text";
let selectedAlgorithms: Set<string> = new Set(["crc16_modbus"]);

// ==================== 初始化 ====================
document.addEventListener("DOMContentLoaded", () => {
  setupEventListeners();
  setupHexInputFormatting();
  updateCharacterCount();
});

// ==================== 事件监听器设置 ====================
function setupEventListeners(): void {
  // 输入方式切换
  const inputMethodRadios = document.querySelectorAll(
    'input[name="inputMethod"]'
  );
  inputMethodRadios.forEach((radio) => {
    radio.addEventListener("change", (event) => {
      const target = event.target as HTMLInputElement;
      switchInputMethod(target.value as "text" | "hex");
    });
  });

  // 算法选择
  const calcTypeCheckboxes = document.querySelectorAll(
    'input[name="calcType"]'
  );
  calcTypeCheckboxes.forEach((checkbox) => {
    checkbox.addEventListener("change", (event) => {
      const target = event.target as HTMLInputElement;
      if (target.checked) {
        selectedAlgorithms.add(target.value);
      } else {
        selectedAlgorithms.delete(target.value);
      }
    });
  });

  // 字符计数
  const textData = document.getElementById("textData") as HTMLTextAreaElement;
  textData?.addEventListener("input", updateCharacterCount);

  // 快捷键支持
  textData?.addEventListener("keydown", (event) => {
    if (event.ctrlKey && event.key === "Enter") {
      doCalculation();
    }
  });

  const hexData = document.getElementById("hexData") as HTMLTextAreaElement;
  hexData?.addEventListener("keydown", (event) => {
    if (event.ctrlKey && event.key === "Enter") {
      doCalculation();
    }
  });
}

// ==================== HEX 格式化 ====================
function formatHexInput(value: string): string {
  const cleanHex = value.replace(/[^0-9A-Fa-f]/g, "").toUpperCase();
  const pairs: string[] = [];
  for (let i = 0; i < cleanHex.length; i += 2) {
    pairs.push(cleanHex.substr(i, 2));
  }
  return pairs.join(" ");
}

function setupHexInputFormatting(): void {
  const hexData = document.getElementById("hexData") as HTMLTextAreaElement;
  if (!hexData) return;

  hexData.addEventListener("input", (event) => {
    const target = event.target as HTMLTextAreaElement;
    const cursorPosition = target.selectionStart;
    const originalValue = target.value;
    const formattedValue = formatHexInput(originalValue);

    if (formattedValue !== originalValue) {
      target.value = formattedValue;
      const charsAdded = formattedValue.length - originalValue.length;
      const newPosition = cursorPosition + charsAdded;
      target.setSelectionRange(newPosition, newPosition);
    }
  });
}

// ==================== UI 辅助函数 ====================
function updateCharacterCount(): void {
  const textData = document.getElementById("textData") as HTMLTextAreaElement;
  const textLength = document.getElementById("textLength");
  if (textData && textLength) {
    textLength.textContent = `字符数：${textData.value.length}`;
  }
}

function switchInputMethod(method: "text" | "hex"): void {
  currentInputMethod = method;

  const textInput = document.getElementById("textInput");
  const hexInput = document.getElementById("hexInput");

  if (method === "text") {
    textInput?.classList.remove("hidden");
    hexInput?.classList.add("hidden");
  } else {
    textInput?.classList.add("hidden");
    hexInput?.classList.remove("hidden");
  }
}

function getInputData(): string {
  if (currentInputMethod === "text") {
    const textData = document.getElementById("textData") as HTMLTextAreaElement;
    return textData?.value || "";
  } else {
    const hexData = document.getElementById("hexData") as HTMLTextAreaElement;
    return hexData?.value.replace(/\s/g, "") || "";
  }
}

// ==================== 全局函数（供HTML调用） ====================
(window as any).clearInput = function (): void {
  if (currentInputMethod === "text") {
    const textData = document.getElementById("textData") as HTMLTextAreaElement;
    if (textData) {
      textData.value = "";
      updateCharacterCount();
    }
  } else {
    const hexData = document.getElementById("hexData") as HTMLTextAreaElement;
    if (hexData) hexData.value = "";
  }
};

(window as any).performCalculation = doCalculation;

// ==================== 复制功能（改进版 - 复制完整数据）====================
// 存储当前输入数据，用于复制完整内容
let currentInputDataForCopy: string = "";

(window as any).copyToClipboard = async function (
  checksumValue: string,
  algorithmName: string,
  inputData?: string
): Promise<void> {
  // 如果没有传入inputData，使用存储的当前输入
  const originalInput = inputData || currentInputDataForCopy;

  // 根据输入方式构造完整数据
  let fullData: string;
  if (currentInputMethod === "hex") {
    // HEX模式：输入数据 + 校验值（都是HEX格式，空格分隔）
    const cleanInput = originalInput.replace(/\s/g, "");
    const formattedInput = cleanInput.match(/.{1,2}/g)?.join(" ") || cleanInput;
    fullData = `${formattedInput} ${checksumValue}`;
  } else {
    // 文本模式：先转换为HEX，再加上校验值
    const inputHex = stringToHex(originalInput);
    fullData = `${inputHex} ${checksumValue}`;
  }

  try {
    // 方法1: 现代 Clipboard API
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(fullData);
      showToast(`${algorithmName} 完整数据已复制！`, "success");
      return;
    }

    // 方法2: 降级方案 - execCommand
    const textArea = document.createElement("textarea");
    textArea.value = fullData;
    textArea.style.cssText =
      "position:fixed;top:-9999px;left:-9999px;opacity:0";

    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);

    if (successful) {
      showToast(`${algorithmName} 完整数据已复制！`, "success");
      return;
    }

    // 方法3: 手动复制提示
    showManualCopyDialog(fullData, algorithmName);
  } catch (err) {
    console.error("复制失败:", err);
    showManualCopyDialog(fullData, algorithmName);
  }
};

// 辅助函数：将字符串转换为HEX
function stringToHex(str: string): string {
  let hex = "";
  for (let i = 0; i < str.length; i++) {
    const charCode = str.charCodeAt(i);
    hex += charCode.toString(16).toUpperCase().padStart(2, "0") + " ";
  }
  return hex.trim();
}

function showManualCopyDialog(fullData: string, algorithmName: string): void {
  const dialog = document.createElement("div");
  dialog.style.cssText = `
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: white;
    padding: 30px;
    border-radius: 12px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3);
    z-index: 99999;
    max-width: 600px;
    border: 2px solid #3b82f6;
  `;

  dialog.innerHTML = `
    <h3 style="margin-top:0;color:#1e40af;">📋 ${algorithmName} 完整数据</h3>
    <div style="
      background:#f3f4f6;
      padding:15px;
      border-radius:6px;
      font-family:monospace;
      font-size:14px;
      font-weight:bold;
      margin:15px 0;
      user-select:all;
      cursor:text;
      color:#111827;
      max-height:200px;
      overflow-y:auto;
      word-break:break-all;
    " onclick="this.focus();document.execCommand('selectAll')">${fullData}</div>
    <p style="color:#6b7280;font-size:14px;margin:10px 0;">
      ☝️ 点击上方数据自动全选，然后按 <kbd style="background:#e5e7eb;padding:2px 6px;border-radius:4px;">Ctrl+C</kbd> 复制<br>
      <small>包含原始输入数据 + ${algorithmName}校验值</small>
    </p>
    <button onclick="this.parentElement.remove()" style="
      background:#3b82f6;
      color:white;
      border:none;
      padding:10px 20px;
      border-radius:6px;
      cursor:pointer;
      font-size:14px;
      width:100%;
      font-weight:600;
    ">关闭</button>
  `;

  document.body.appendChild(dialog);

  // 自动选中文本
  const textBox = dialog.querySelector("div[onclick]");
  if (textBox) {
    setTimeout(() => {
      const range = document.createRange();
      range.selectNodeContents(textBox);
      const selection = window.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(range);
    }, 100);
  }

  // 点击外部关闭
  setTimeout(() => {
    const closeOnOutsideClick = (e: MouseEvent) => {
      if (!dialog.contains(e.target as Node)) {
        dialog.remove();
        document.removeEventListener("click", closeOnOutsideClick);
      }
    };
    document.addEventListener("click", closeOnOutsideClick);
  }, 200);
}

function showToast(
  message: string,
  type: "success" | "error" | "warning" = "success"
): void {
  const colors = {
    success: "#10b981",
    error: "#ef4444",
    warning: "#f59e0b",
  };

  const toast = document.createElement("div");
  toast.style.cssText = `
    position: fixed;
    bottom: 30px;
    right: 30px;
    background: ${colors[type]};
    color: white;
    padding: 15px 25px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    z-index: 99999;
    font-size: 15px;
    font-weight: 500;
    animation: slideIn 0.3s ease;
  `;
  toast.textContent = message;

  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = "slideOut 0.3s ease";
    setTimeout(() => toast.remove(), 300);
  }, 2500);
}

// 添加CSS动画
const style = document.createElement("style");
style.textContent = `
  @keyframes slideIn {
    from { transform: translateX(400px); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
  @keyframes slideOut {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(400px); opacity: 0; }
  }
`;
document.head.appendChild(style);

// ==================== 计算功能 ====================
async function doCalculation(): Promise<void> {
  const calculateBtn = document.getElementById(
    "calculateBtn"
  ) as HTMLButtonElement;
  const resultContainer = document.getElementById("resultContainer");

  if (!calculateBtn || !resultContainer) return;

  try {
    const inputData = getInputData();
    if (!inputData.trim()) {
      showToast("请输入要计算的数据", "error");
      return;
    }

    if (selectedAlgorithms.size === 0) {
      showToast("请至少选择一种校验算法", "error");
      return;
    }

    // 显示加载状态
    calculateBtn.disabled = true;
    calculateBtn.innerHTML = `
      <svg class="inline-block w-6 h-6 mr-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
      </svg>
      计算中...
    `;

    // 调用API计算
    const results: CalculationResult[] = [];

    // CRC/SUM8 计算
    if (
      selectedAlgorithms.has("crc16_modbus") ||
      selectedAlgorithms.has("crc16_ccitt") ||
      selectedAlgorithms.has("crc32") ||
      selectedAlgorithms.has("sum8")
    ) {
      try {
        const response = await fetch("http://localhost:8080/api/checksum", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ data: inputData, method: currentInputMethod }),
        });

        if (response.ok) {
          const data: APIResponse = await response.json();

          if (selectedAlgorithms.has("crc16_modbus") && data.crc) {
            results.push({
              type: "CRC16 MODBUS",
              value: data.crc,
              description: "工业标准MODBUS，多项式0xA001，低字节在前",
            });
          }

          if (selectedAlgorithms.has("crc16_ccitt") && data.crc16_ccitt) {
            results.push({
              type: "CRC16 CCITT",
              value: data.crc16_ccitt,
              description: "电信标准CCITT，多项式0x1021",
            });
          }

          if (selectedAlgorithms.has("crc32") && data.crc32) {
            results.push({
              type: "CRC32 IEEE",
              value: data.crc32,
              description: "32位IEEE标准循环冗余校验",
            });
          }

          if (selectedAlgorithms.has("sum8") && data.sum8) {
            results.push({
              type: "SUM8",
              value: data.sum8,
              description: "8位累加和校验",
            });
          }
        }
      } catch (error) {
        console.error("Checksum API error:", error);
      }
    }

    // LRC 计算
    if (selectedAlgorithms.has("lrc")) {
      try {
        const response = await fetch("http://localhost:8080/api/lrc", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ data: inputData, method: currentInputMethod }),
        });

        if (response.ok) {
          const data: APIResponse = await response.json();
          if (data.lrc) {
            results.push({
              type: "LRC",
              value: data.lrc,
              description: "纵向冗余校验 (Longitudinal Redundancy Check)",
            });
          }
        }
      } catch (error) {
        console.error("LRC API error:", error);
      }
    }

    // 显示结果
    if (results.length > 0) {
      displayResults(results, inputData);
    } else {
      displayError("没有计算结果，请检查服务器连接");
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "未知错误";
    showToast(errorMessage, "error");
    displayError(errorMessage);
  } finally {
    // 重置按钮
    calculateBtn.disabled = false;
    calculateBtn.innerHTML = `
      <svg class="inline-block w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
      </svg>
      开始计算
    `;
  }
}

// ==================== 结果显示 ====================
function displayResults(results: CalculationResult[], inputData: string): void {
  const resultContainer = document.getElementById("resultContainer");
  if (!resultContainer) return;

  // 存储当前输入数据供复制使用
  currentInputDataForCopy = inputData;

  const timestamp = new Date().toLocaleString("zh-CN");
  const displayData =
    inputData.length > 100 ? inputData.substring(0, 100) + "..." : inputData;

  let resultsHTML = `
    <div class="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
      <div class="flex items-center justify-between mb-4 pb-4 border-b border-gray-200">
        <h3 class="text-2xl font-bold text-gray-800 flex items-center">
          <svg class="w-7 h-7 mr-2 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          计算结果
        </h3>
        <span class="text-sm text-gray-500">${timestamp}</span>
      </div>
      
      <div class="mb-4 p-4 bg-gray-50 rounded-lg">
        <p class="text-sm text-gray-600 mb-1">输入数据 (${
          currentInputMethod === "hex" ? "HEX" : "TEXT"
        }):</p>
        <p class="text-base font-mono text-gray-800 break-all">${escapeHtml(
          displayData
        )}</p>
        <p class="text-xs text-gray-500 mt-2">💡 提示：点击"复制"按钮将复制完整数据（输入 + 校验值）</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  `;

  results.forEach((result) => {
    const color = getAlgorithmColor(result.type);
    resultsHTML += `
      <div class="result-card bg-gradient-to-br from-${color}-50 to-white border-2 border-${color}-200 rounded-xl p-5 shadow-md">
        <div class="flex items-center justify-between mb-3">
          <h4 class="text-lg font-bold text-${color}-800">${result.type}</h4>
          <button onclick="copyToClipboard('${result.value}', '${result.type}')" 
            class="copy-btn px-3 py-1.5 bg-${color}-600 hover:bg-${color}-700 text-white text-sm font-medium rounded-lg shadow-sm">
            <svg class="inline-block w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
            </svg>
            复制
          </button>
        </div>
        <div class="bg-white rounded-lg p-3 mb-2 border border-${color}-200">
          <p class="text-2xl font-mono font-bold text-center text-gray-900">${result.value}</p>
        </div>
        <p class="text-xs text-gray-600">${result.description}</p>
      </div>
    `;
  });

  resultsHTML += `
      </div>
    </div>
  `;

  resultContainer.innerHTML = resultsHTML;
}

function getAlgorithmColor(type: string): string {
  const colors: Record<string, string> = {
    "CRC16 MODBUS": "blue",
    "CRC16 CCITT": "indigo",
    "CRC32 IEEE": "purple",
    LRC: "green",
    SUM8: "yellow",
  };
  return colors[type] || "gray";
}

function displayError(error: string): void {
  const resultContainer = document.getElementById("resultContainer");
  if (!resultContainer) return;

  const errorHTML = `
    <div class="bg-red-50 border-2 border-red-200 rounded-2xl p-6 shadow-lg">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <svg class="h-8 w-8 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-4">
          <h3 class="text-lg font-bold text-red-800">计算错误</h3>
          <div class="mt-1 text-base text-red-700">${escapeHtml(error)}</div>
        </div>
      </div>
    </div>
  `;

  resultContainer.innerHTML = errorHTML;
}

function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#039;",
  };
  return text.replace(/[&<>"']/g, (m) => map[m]);
}
