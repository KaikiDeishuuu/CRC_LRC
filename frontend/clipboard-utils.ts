// 改进的复制到剪贴板函数 - 包含多种降级方案

/**
 * 方案1: 使用现代Clipboard API (推荐)
 */
async function copyToClipboardModern(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (err) {
    console.warn("Modern clipboard API failed:", err);
    return false;
  }
}

/**
 * 方案2: 使用document.execCommand (兼容旧浏览器)
 */
function copyToClipboardLegacy(text: string): boolean {
  const textArea = document.createElement("textarea");
  textArea.value = text;

  // 使元素不可见但仍可操作
  textArea.style.position = "fixed";
  textArea.style.top = "-9999px";
  textArea.style.left = "-9999px";
  textArea.style.opacity = "0";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);
    return successful;
  } catch (err) {
    console.warn("Legacy clipboard method failed:", err);
    document.body.removeChild(textArea);
    return false;
  }
}

/**
 * 方案3: 手动选择文本 (最终降级方案)
 */
function selectTextForManualCopy(
  text: string,
  containerElement?: HTMLElement
): void {
  if (containerElement) {
    // 如果有容器元素，直接选中它的文本
    const range = document.createRange();
    range.selectNodeContents(containerElement);
    const selection = window.getSelection();
    selection?.removeAllRanges();
    selection?.addRange(range);
  } else {
    // 创建临时元素显示文本供用户手动复制
    const tempDiv = document.createElement("div");
    tempDiv.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: white;
      padding: 20px;
      border: 2px solid #3b82f6;
      border-radius: 8px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      z-index: 10000;
      max-width: 80%;
    `;

    tempDiv.innerHTML = `
      <div style="margin-bottom: 10px; font-weight: bold; color: #1e40af;">
        请手动复制以下内容：
      </div>
      <div style="
        background: #f3f4f6; 
        padding: 12px; 
        border-radius: 4px; 
        font-family: monospace;
        user-select: all;
        word-break: break-all;
      " id="copyText">${text}</div>
      <button id="closeBtn" style="
        margin-top: 10px;
        padding: 8px 16px;
        background: #3b82f6;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
      ">关闭</button>
    `;

    document.body.appendChild(tempDiv);

    // 自动选中文本
    const textElement = document.getElementById("copyText");
    if (textElement) {
      const range = document.createRange();
      range.selectNodeContents(textElement);
      const selection = window.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(range);
    }

    // 关闭按钮
    const closeBtn = document.getElementById("closeBtn");
    closeBtn?.addEventListener("click", () => {
      document.body.removeChild(tempDiv);
    });
  }
}

/**
 * 综合复制函数 - 自动尝试多种方案
 */
export async function copyToClipboard(
  text: string,
  algorithmName?: string
): Promise<void> {
  // 先尝试现代API
  const modernSuccess = await copyToClipboardModern(text);
  if (modernSuccess) {
    showToast(`${algorithmName || "结果"} 已复制到剪贴板！`, "success");
    return;
  }

  // 降级到legacy方法
  const legacySuccess = copyToClipboardLegacy(text);
  if (legacySuccess) {
    showToast(`${algorithmName || "结果"} 已复制到剪贴板！`, "success");
    return;
  }

  // 最终降级：手动复制
  showToast("自动复制失败，请手动复制", "warning");
  selectTextForManualCopy(text);
}

/**
 * 显示提示消息
 */
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
    bottom: 20px;
    right: 20px;
    padding: 12px 24px;
    background: ${colors[type]};
    color: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    animation: slideIn 0.3s ease;
    z-index: 10000;
    font-size: 14px;
  `;
  toast.textContent = message;

  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = "slideOut 0.3s ease";
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// CSS动画
const style = document.createElement("style");
style.textContent = `
  @keyframes slideIn {
    from {
      transform: translateX(400px);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
  
  @keyframes slideOut {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(400px);
      opacity: 0;
    }
  }
`;
document.head.appendChild(style);

/**
 * React Hook 示例
 * 注意：使用此Hook需要先安装React: npm install react
 * 并在文件顶部添加: import { useState } from 'react';
 */
/*
export function useCopyToClipboard() {
  const [isCopied, setIsCopied] = useState(false);

  const copy = async (text: string, name?: string) => {
    await copyToClipboard(text, name);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  return { copy, isCopied };
}
*/

/**
 * 简单的HTML按钮使用示例
 */
/*
<button onclick="copyToClipboard('B448', 'CRC16 MODBUS')">
  复制 CRC16
</button>
*/

/**
 * React组件使用示例
 */
/*
function CopyButton({ text, label }) {
  const { copy, isCopied } = useCopyToClipboard();
  
  return (
    <button 
      onClick={() => copy(text, label)}
      className={isCopied ? 'copied' : ''}
    >
      {isCopied ? '✓ 已复制' : '📋 复制'}
    </button>
  );
}
*/
