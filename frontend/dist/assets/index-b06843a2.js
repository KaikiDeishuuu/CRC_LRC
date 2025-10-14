(function(){const r=document.createElement("link").relList;if(r&&r.supports&&r.supports("modulepreload"))return;for(const e of document.querySelectorAll('link[rel="modulepreload"]'))s(e);new MutationObserver(e=>{for(const n of e)if(n.type==="childList")for(const c of n.addedNodes)c.tagName==="LINK"&&c.rel==="modulepreload"&&s(c)}).observe(document,{childList:!0,subtree:!0});function t(e){const n={};return e.integrity&&(n.integrity=e.integrity),e.referrerPolicy&&(n.referrerPolicy=e.referrerPolicy),e.crossOrigin==="use-credentials"?n.credentials="include":e.crossOrigin==="anonymous"?n.credentials="omit":n.credentials="same-origin",n}function s(e){if(e.ep)return;e.ep=!0;const n=t(e);fetch(e.href,n)}})();let d="text",i=new Set(["crc16_modbus"]);document.addEventListener("DOMContentLoaded",()=>{y(),v(),p()});function y(){document.querySelectorAll('input[name="inputMethod"]').forEach(e=>{e.addEventListener("change",n=>{const c=n.target;C(c.value)})}),document.querySelectorAll('input[name="calcType"]').forEach(e=>{e.addEventListener("change",n=>{const c=n.target;c.checked?i.add(c.value):i.delete(c.value)})});const t=document.getElementById("textData");t==null||t.addEventListener("input",p),t==null||t.addEventListener("keydown",e=>{e.ctrlKey&&e.key==="Enter"&&u()});const s=document.getElementById("hexData");s==null||s.addEventListener("keydown",e=>{e.ctrlKey&&e.key==="Enter"&&u()})}function b(o){const r=o.replace(/[^0-9A-Fa-f]/g,"").toUpperCase(),t=[];for(let s=0;s<r.length;s+=2)t.push(r.substr(s,2));return t.join(" ")}function v(){const o=document.getElementById("hexData");o&&o.addEventListener("input",r=>{const t=r.target,s=t.selectionStart,e=t.value,n=b(e);if(n!==e){t.value=n;const c=n.length-e.length,a=s+c;t.setSelectionRange(a,a)}})}function p(){const o=document.getElementById("textData"),r=document.getElementById("textLength");o&&r&&(r.textContent=`字符数：${o.value.length}`)}function C(o){d=o;const r=document.getElementById("textInput"),t=document.getElementById("hexInput");o==="text"?(r==null||r.classList.remove("hidden"),t==null||t.classList.add("hidden")):(r==null||r.classList.add("hidden"),t==null||t.classList.remove("hidden"))}function w(){if(d==="text"){const o=document.getElementById("textData");return(o==null?void 0:o.value)||""}else{const o=document.getElementById("hexData");return(o==null?void 0:o.value.replace(/\s/g,""))||""}}window.clearInput=function(){if(d==="text"){const o=document.getElementById("textData");o&&(o.value="",p())}else{const o=document.getElementById("hexData");o&&(o.value="")}};window.performCalculation=u;let f="";window.copyToClipboard=async function(o,r,t){var n;const s=t||f;let e;if(d==="hex"){const c=s.replace(/\s/g,"");e=`${((n=c.match(/.{1,2}/g))==null?void 0:n.join(" "))||c} ${o}`}else e=`${E(s)} ${o}`;try{if(navigator.clipboard&&window.isSecureContext){await navigator.clipboard.writeText(e),l(`${r} 完整数据已复制！`,"success");return}const c=document.createElement("textarea");c.value=e,c.style.cssText="position:fixed;top:-9999px;left:-9999px;opacity:0",document.body.appendChild(c),c.focus(),c.select();const a=document.execCommand("copy");if(document.body.removeChild(c),a){l(`${r} 完整数据已复制！`,"success");return}m(e,r)}catch(c){console.error("复制失败:",c),m(e,r)}};function E(o){let r="";for(let t=0;t<o.length;t++){const s=o.charCodeAt(t);r+=s.toString(16).toUpperCase().padStart(2,"0")+" "}return r.trim()}function m(o,r){const t=document.createElement("div");t.style.cssText=`
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
  `,t.innerHTML=`
    <h3 style="margin-top:0;color:#1e40af;">📋 ${r} 完整数据</h3>
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
    " onclick="this.focus();document.execCommand('selectAll')">${o}</div>
    <p style="color:#6b7280;font-size:14px;margin:10px 0;">
      ☝️ 点击上方数据自动全选，然后按 <kbd style="background:#e5e7eb;padding:2px 6px;border-radius:4px;">Ctrl+C</kbd> 复制<br>
      <small>包含原始输入数据 + ${r}校验值</small>
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
  `,document.body.appendChild(t);const s=t.querySelector("div[onclick]");s&&setTimeout(()=>{const e=document.createRange();e.selectNodeContents(s);const n=window.getSelection();n==null||n.removeAllRanges(),n==null||n.addRange(e)},100),setTimeout(()=>{const e=n=>{t.contains(n.target)||(t.remove(),document.removeEventListener("click",e))};document.addEventListener("click",e)},200)}function l(o,r="success"){const t={success:"#10b981",error:"#ef4444",warning:"#f59e0b"},s=document.createElement("div");s.style.cssText=`
    position: fixed;
    bottom: 30px;
    right: 30px;
    background: ${t[r]};
    color: white;
    padding: 15px 25px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.2);
    z-index: 99999;
    font-size: 15px;
    font-weight: 500;
    animation: slideIn 0.3s ease;
  `,s.textContent=o,document.body.appendChild(s),setTimeout(()=>{s.style.animation="slideOut 0.3s ease",setTimeout(()=>s.remove(),300)},2500)}const g=document.createElement("style");g.textContent=`
  @keyframes slideIn {
    from { transform: translateX(400px); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
  }
  @keyframes slideOut {
    from { transform: translateX(0); opacity: 1; }
    to { transform: translateX(400px); opacity: 0; }
  }
`;document.head.appendChild(g);async function u(){const o=document.getElementById("calculateBtn"),r=document.getElementById("resultContainer");if(!(!o||!r))try{const t=w();if(!t.trim()){l("请输入要计算的数据","error");return}if(i.size===0){l("请至少选择一种校验算法","error");return}o.disabled=!0,o.innerHTML=`
      <svg class="inline-block w-6 h-6 mr-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
      </svg>
      计算中...
    `;const s=[];if(i.has("crc16_modbus")||i.has("crc16_ccitt")||i.has("crc32")||i.has("sum8"))try{const e=await fetch("http://localhost:8080/api/checksum",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({data:t,method:d})});if(e.ok){const n=await e.json();i.has("crc16_modbus")&&n.crc&&s.push({type:"CRC16 MODBUS",value:n.crc,description:"工业标准MODBUS，多项式0xA001，低字节在前"}),i.has("crc16_ccitt")&&n.crc16_ccitt&&s.push({type:"CRC16 CCITT",value:n.crc16_ccitt,description:"电信标准CCITT，多项式0x1021"}),i.has("crc32")&&n.crc32&&s.push({type:"CRC32 IEEE",value:n.crc32,description:"32位IEEE标准循环冗余校验"}),i.has("sum8")&&n.sum8&&s.push({type:"SUM8",value:n.sum8,description:"8位累加和校验"})}}catch(e){console.error("Checksum API error:",e)}if(i.has("lrc"))try{const e=await fetch("http://localhost:8080/api/lrc",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({data:t,method:d})});if(e.ok){const n=await e.json();n.lrc&&s.push({type:"LRC",value:n.lrc,description:"纵向冗余校验 (Longitudinal Redundancy Check)"})}}catch(e){console.error("LRC API error:",e)}s.length>0?k(s,t):h("没有计算结果，请检查服务器连接")}catch(t){const s=t instanceof Error?t.message:"未知错误";l(s,"error"),h(s)}finally{o.disabled=!1,o.innerHTML=`
      <svg class="inline-block w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
      </svg>
      开始计算
    `}}function k(o,r){const t=document.getElementById("resultContainer");if(!t)return;f=r;const s=new Date().toLocaleString("zh-CN"),e=r.length>100?r.substring(0,100)+"...":r;let n=`
    <div class="bg-white rounded-2xl shadow-lg border border-gray-100 p-6">
      <div class="flex items-center justify-between mb-4 pb-4 border-b border-gray-200">
        <h3 class="text-2xl font-bold text-gray-800 flex items-center">
          <svg class="w-7 h-7 mr-2 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          计算结果
        </h3>
        <span class="text-sm text-gray-500">${s}</span>
      </div>
      
      <div class="mb-4 p-4 bg-gray-50 rounded-lg">
        <p class="text-sm text-gray-600 mb-1">输入数据 (${d==="hex"?"HEX":"TEXT"}):</p>
        <p class="text-base font-mono text-gray-800 break-all">${x(e)}</p>
        <p class="text-xs text-gray-500 mt-2">💡 提示：点击"复制"按钮将复制完整数据（输入 + 校验值）</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  `;o.forEach(c=>{const a=L(c.type);n+=`
      <div class="result-card bg-gradient-to-br from-${a}-50 to-white border-2 border-${a}-200 rounded-xl p-5 shadow-md">
        <div class="flex items-center justify-between mb-3">
          <h4 class="text-lg font-bold text-${a}-800">${c.type}</h4>
          <button onclick="copyToClipboard('${c.value}', '${c.type}')" 
            class="copy-btn px-3 py-1.5 bg-${a}-600 hover:bg-${a}-700 text-white text-sm font-medium rounded-lg shadow-sm">
            <svg class="inline-block w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
            </svg>
            复制
          </button>
        </div>
        <div class="bg-white rounded-lg p-3 mb-2 border border-${a}-200">
          <p class="text-2xl font-mono font-bold text-center text-gray-900">${c.value}</p>
        </div>
        <p class="text-xs text-gray-600">${c.description}</p>
      </div>
    `}),n+=`
      </div>
    </div>
  `,t.innerHTML=n}function L(o){return{"CRC16 MODBUS":"blue","CRC16 CCITT":"indigo","CRC32 IEEE":"purple",LRC:"green",SUM8:"yellow"}[o]||"gray"}function h(o){const r=document.getElementById("resultContainer");if(!r)return;const t=`
    <div class="bg-red-50 border-2 border-red-200 rounded-2xl p-6 shadow-lg">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <svg class="h-8 w-8 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-4">
          <h3 class="text-lg font-bold text-red-800">计算错误</h3>
          <div class="mt-1 text-base text-red-700">${x(o)}</div>
        </div>
      </div>
    </div>
  `;r.innerHTML=t}function x(o){const r={"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"};return o.replace(/[&<>"']/g,t=>r[t])}
//# sourceMappingURL=index-b06843a2.js.map
