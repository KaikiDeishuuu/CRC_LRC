# 复制功能改进方案

## 问题说明

"复制失败，请手动复制结果" 通常是由于以下原因：

1. **浏览器安全限制** - 需要 HTTPS 或 localhost
2. **权限未授予** - 用户拒绝了剪贴板访问
3. **浏览器兼容性** - 旧浏览器不支持 Clipboard API

## 解决方案 1：纯 JavaScript（推荐用于您的 blog 项目）

```javascript
// 复制到剪贴板 - 多重降级方案
function copyToClipboard(text, showSuccessMessage = true) {
  // 方法1: 现代 Clipboard API
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard
      .writeText(text)
      .then(() => {
        if (showSuccessMessage) {
          alert("✓ 已复制到剪贴板！");
          // 或使用自定义提示：showMessage('已复制！', 'success');
        }
      })
      .catch(() => {
        // 失败则尝试方法2
        copyFallback(text, showSuccessMessage);
      });
  } else {
    // 直接使用降级方案
    copyFallback(text, showSuccessMessage);
  }
}

// 方法2: 降级方案 - execCommand
function copyFallback(text, showSuccessMessage) {
  const textArea = document.createElement("textarea");
  textArea.value = text;
  textArea.style.cssText = "position:fixed;top:-9999px;left:-9999px;opacity:0";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    const successful = document.execCommand("copy");
    document.body.removeChild(textArea);

    if (successful && showSuccessMessage) {
      alert("✓ 已复制到剪贴板！");
    } else if (!successful) {
      // 方法3: 手动复制
      showManualCopyDialog(text);
    }
  } catch (err) {
    document.body.removeChild(textArea);
    showManualCopyDialog(text);
  }
}

// 方法3: 显示对话框让用户手动复制
function showManualCopyDialog(text) {
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
    max-width: 500px;
    border: 2px solid #3b82f6;
  `;

  dialog.innerHTML = `
    <h3 style="margin-top:0;color:#1e40af;">📋 请手动复制</h3>
    <div style="
      background:#f3f4f6;
      padding:15px;
      border-radius:6px;
      font-family:monospace;
      font-size:16px;
      word-break:break-all;
      margin:15px 0;
      user-select:all;
      cursor:text;
    " onclick="this.focus();document.execCommand('selectAll')">${text}</div>
    <p style="color:#6b7280;font-size:14px;margin:10px 0;">
      点击上方文本框自动全选，然后按 Ctrl+C (或 Cmd+C) 复制
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
    ">关闭</button>
  `;

  document.body.appendChild(dialog);

  // 自动选中文本
  const textBox = dialog.querySelector("div[onclick]");
  if (textBox) {
    textBox.focus();
    const range = document.createRange();
    range.selectNodeContents(textBox);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  }

  // 点击外部关闭
  setTimeout(() => {
    const closeOnOutsideClick = (e) => {
      if (!dialog.contains(e.target)) {
        dialog.remove();
        document.removeEventListener("click", closeOnOutsideClick);
      }
    };
    document.addEventListener("click", closeOnOutsideClick);
  }, 100);
}

// 可选：美化的提示消息
function showMessage(message, type = "success") {
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
if (!document.getElementById("toast-animations")) {
  const style = document.createElement("style");
  style.id = "toast-animations";
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
}
```

## 解决方案 2：React/Next.js 组件

```jsx
import { useState } from "react";

export function CopyButton({ text, label = "复制" }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      // 尝试现代API
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
        return;
      }

      // 降级方案
      const textArea = document.createElement("textarea");
      textArea.value = text;
      textArea.style.cssText = "position:fixed;top:-9999px;opacity:0";
      document.body.appendChild(textArea);
      textArea.select();

      const success = document.execCommand("copy");
      document.body.removeChild(textArea);

      if (success) {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      } else {
        // 显示手动复制提示
        alert(`请手动复制：\n${text}`);
      }
    } catch (err) {
      alert(`请手动复制：\n${text}`);
    }
  };

  return (
    <button
      onClick={handleCopy}
      className={`
        px-3 py-1.5 rounded-lg font-medium text-sm
        transition-all duration-200
        ${
          copied
            ? "bg-green-600 text-white"
            : "bg-blue-600 hover:bg-blue-700 text-white"
        }
      `}
    >
      {copied ? "✓ 已复制" : `📋 ${label}`}
    </button>
  );
}

// 使用示例
function ChecksumResult({ result }) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span>CRC16 MODBUS: {result.crc}</span>
        <CopyButton text={result.crc} label="复制" />
      </div>
      <div className="flex items-center justify-between">
        <span>CRC32: {result.crc32}</span>
        <CopyButton text={result.crc32} label="复制" />
      </div>
    </div>
  );
}
```

## 解决方案 3：使用自定义 Hook（React）

```typescript
import { useState, useCallback } from "react";

interface CopyOptions {
  timeout?: number;
  showAlert?: boolean;
}

export function useCopyToClipboard(options: CopyOptions = {}) {
  const { timeout = 2000, showAlert = false } = options;
  const [isCopied, setIsCopied] = useState(false);

  const copy = useCallback(
    async (text: string) => {
      try {
        // 方法1: Clipboard API
        if (navigator.clipboard) {
          await navigator.clipboard.writeText(text);
          setIsCopied(true);
          if (showAlert) alert("已复制！");
          setTimeout(() => setIsCopied(false), timeout);
          return true;
        }

        // 方法2: execCommand
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.cssText = "position:fixed;top:-9999px;opacity:0";
        document.body.appendChild(textArea);
        textArea.select();
        const success = document.execCommand("copy");
        document.body.removeChild(textArea);

        if (success) {
          setIsCopied(true);
          if (showAlert) alert("已复制！");
          setTimeout(() => setIsCopied(false), timeout);
          return true;
        }

        // 方法3: 手动提示
        const userConfirmed = confirm(
          `自动复制失败，是否查看要复制的内容？\n\n${text}`
        );
        return false;
      } catch (error) {
        console.error("复制失败:", error);
        alert(`请手动复制：\n${text}`);
        return false;
      }
    },
    [timeout, showAlert]
  );

  return { copy, isCopied };
}

// 使用示例
function MyComponent() {
  const { copy, isCopied } = useCopyToClipboard();

  return (
    <button onClick={() => copy("B448")}>
      {isCopied ? "✓ 已复制" : "📋 复制"}
    </button>
  );
}
```

## 最佳实践建议

### 1. 按钮状态反馈

```jsx
<button onClick={() => copyToClipboard(result.crc)}>
  {copied ? "✓ 已复制" : "📋 复制"}
</button>
```

### 2. 可点击的文本框

```html
<div
  onClick={(e) => {
    e.target.select();
    document.execCommand('copy');
  }}
  style="cursor: pointer; user-select: all;"
  title="点击复制"
>
  B448
</div>
```

### 3. 双击复制

```html
<div
  onDoubleClick={() => copyToClipboard(text)}
  title="双击复制"
>
  结果: B448
</div>
```

## 调试技巧

```javascript
// 检查浏览器支持
console.log("Clipboard API支持:", "clipboard" in navigator);
console.log("安全上下文:", window.isSecureContext);

// 测试复制功能
copyToClipboard("测试文本");
```

## 推荐方案

在您的 blog 项目中，我建议使用 **解决方案 1** 的纯 JavaScript 版本，因为：

✅ 兼容性最好  
✅ 有三重降级方案  
✅ 用户体验友好（手动复制时有清晰提示）  
✅ 不依赖 React 等框架  
✅ 代码简单易维护

只需将上面的 JavaScript 代码复制到您的项目中，然后这样使用：

```javascript
// 简单调用
copyToClipboard("B448");

// 或使用自定义提示
copyToClipboard("B448", true);
```
