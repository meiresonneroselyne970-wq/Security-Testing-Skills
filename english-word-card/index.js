// ================================================================
// ABC 字母启蒙 Card — 交互逻辑
// 从 data.json 读取配置，动态渲染字母和图片，支持点击语音
// ================================================================

/**
 * Web Speech API 语音朗读
 * @param {string} text - 要朗读的英文文本
 * @param {string} lang - 语言代码，默认美式英语
 */
function speak(text, lang = "en-US") {
  if (!window.speechSynthesis) return;        // 浏览器不支持则跳过
  window.speechSynthesis.cancel();            // 取消之前的朗读
  const u = new SpeechSynthesisUtterance(text);
  u.lang = lang;
  u.rate = 0.85;                              // 语速稍慢，适合儿童
  u.pitch = 1.1;                              // 音调稍高
  window.speechSynthesis.speak(u);
}

/**
 * 加载数据：优先 fetch data.json，本地文件时回退到内联 JSON
 * @returns {object|null} 解析后的数据对象
 */
async function loadData() {
  // 非 file:// 协议时尝试 fetch
  if (location.protocol !== "file:") {
    try {
      const r = await fetch("data.test.json");
      if (r.ok) return await r.json();
    } catch (e) { /* 静默失败，回退到内联数据 */ }
  }
  // 回退：读取页面中 <script id="inlineData"> 里的 JSON
  const el = document.getElementById("inlineData");
  if (el?.textContent?.trim()) {
    try { return JSON.parse(el.textContent.trim()); } catch (e) { /* 格式错误 */ }
  }
  return null;  // 无数据可用
}

/**
 * 渲染页面：填充字母、实物图片，绑定点击事件
 * @param {Array} data - 数据对象，包含 title、description 等字段、
*  其中 description 已经解析为字母-单词
 */
function render(data) {
  // 解析 description: "Aa|apple" → letter="Aa", word="apple"
  const [letter, word] = (data.description || "").split("|").map(s => s.trim());
  // 拆分大小写：首字母大写，其余小写
  const upper = letter.charAt(0);           // "A"
  const lower = letter.slice(1);            // "a"

  // ---- 左右布局：左字母 | 右单词+图片 ----
  const abcContent = document.getElementById("abcContent");
  if (abcContent) {
    abcContent.innerHTML = `
      <div class="abc-row">
        <div class="abc-left">
          <div class="big-letter">
            <span class="letter-upper">${escHtml(upper)}</span><span class="letter-lower">${escHtml(lower)}</span>
          </div>
        </div>
        <div class="abc-right">
          <div class="word-label">${escHtml(word)}</div>
          <img class="abc-real-img interactive" src="${escHtml(data.target_url)}" alt="${escHtml(word)}">
        </div>
      </div>
    `;
  }

  // ---- 绑定交互：点击字母/图片 → 语音朗读 ----
  document.querySelectorAll(".big-letter").forEach(el => {
    el.style.cursor = "pointer";
    el.addEventListener("click", () => speak(el.textContent));
  });
  document.querySelectorAll(".abc-real-img").forEach(el => {
    el.addEventListener("click", () => speak(el.alt));
  });
}

/**
 * HTML 转义：防止 XSS
 * @param {string} s - 原始字符串
 * @returns {string} 转义后的安全字符串
 */
function escHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ================================================================
// 入口：加载数据 → 解析 → 渲染
// ================================================================
(async function () {
  const data = await loadData();
  if (!data) return;                            // 无数据则静默退出

  document.title = data.title || "ABC · 字母启蒙";   // 设置页面标题
  const lettersWords = data;
  render(lettersWords);              // 渲染页面
})();
