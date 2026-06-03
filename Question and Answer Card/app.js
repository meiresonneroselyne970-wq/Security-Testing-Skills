/* ========================================
   炎图 AI 知识问答 — 问答卡片逻辑
   ======================================== */

// ==================== DOM 引用 ====================
const $ = (sel) => document.querySelector(sel);

const dom = {
  logo:        $('#qaLogo'),
  title:       $('#qaTitle'),
  subtitle:    $('#qaSubtitle'),
  body:        $('#qaBody'),
  input:       $('#qaInput'),
  sendBtn:     $('#sendBtn'),
  prompts:     $('#quickPrompts'),
  statusDot:   $('#statusDot'),
  statusText:  $('#statusText'),
};

// ==================== 配置状态 ====================
let cfg = null;
let isSending = false;

// ==================== 初始化 ====================
async function init() {
  await loadConfig();
  applyUI();
  renderQuickPrompts();
  bindEvents();
  checkHealth();
}

// ==================== 加载配置 ====================
async function loadConfig() {
  try {
    const res = await fetch('./data.json');
    cfg = await res.json();
  } catch (e) {
    // 使用默认配置
    cfg = getDefaultConfig();
  }
}

function getDefaultConfig() {
  return {
    api: {
      base: 'http://127.0.0.1:8899',
      qa_endpoint: '/qa',
      health_endpoint: '/health',
    },
    ui: {
      title: '炎图 AI 知识问答',
      subtitle: '基于知识库的智能检索与回答',
      placeholder: '请输入你的问题…',
      logo: '🤖',
      quick_prompts: [
        { label: '🍱 公司餐补', question: '公司餐补是多少？' },
        { label: '🎁 员工福利', question: '员工有什么福利待遇？' },
        { label: '🏗️ 技术架构', question: '公司的技术架构是怎样的？' },
        { label: '🚀 公司项目', question: '公司有哪些项目？' },
      ],
      category_icons: {
        architecture: '🏗️', company: '🏢', hr: '👥', projects: '🚀',
      },
      file_icons: {
        md: '📘', docx: '📄', pptx: '📊',
      },
      default_file_icon: '📎',
      default_category_icon: '📁',
    },
    request: {
      top_k: 5,
      timeout_ms: 30000,
    },
  };
}

// ==================== 应用 UI 配置 ====================
function applyUI() {
  const ui = cfg.ui;
  dom.logo.textContent     = ui.logo;
  dom.title.textContent    = ui.title;
  dom.subtitle.textContent = ui.subtitle;
  dom.input.placeholder    = ui.placeholder;
}

// ==================== 快捷提问 ====================
function renderQuickPrompts() {
  const prompts = cfg.ui.quick_prompts;
  dom.prompts.innerHTML = prompts.map((p) =>
    `<button class="quick-prompt" data-q="${escAttr(p.question)}">${escHtml(p.label)}</button>`
  ).join('');
}

// ==================== 事件绑定 ====================
function bindEvents() {
  // 快捷标签点击
  dom.prompts.addEventListener('click', (e) => {
    const btn = e.target.closest('.quick-prompt');
    if (!btn) return;
    dom.input.value = btn.dataset.q;
    ask();
  });

  // 发送按钮
  dom.sendBtn.addEventListener('click', ask);

  // 回车发送
  dom.input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') ask();
  });
}

// ==================== 健康检查 ====================
async function checkHealth() {
  const url = cfg.api.base + cfg.api.health_endpoint;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
    const data = await res.json();
    if (data.status === 'ok') {
      setApiOnline(true);
      return;
    }
    throw new Error();
  } catch (e) {
    setApiOnline(false);
  }
}

function setApiOnline(online) {
  if (online) {
    dom.statusDot.classList.remove('offline');
    dom.statusText.textContent = 'API 在线';
  } else {
    dom.statusDot.classList.add('offline');
    dom.statusText.textContent = 'API 离线';
  }
}

// ==================== 发送问题 ====================
async function ask() {
  const question = dom.input.value.trim();
  if (!question || isSending) return;

  isSending = true;
  dom.input.disabled = true;
  dom.sendBtn.disabled = true;
  dom.input.value = '';

  showLoading();

  try {
    const url = cfg.api.base + cfg.api.qa_endpoint;
    const res = await fetch(url, {
      method: 'POST',
      // 不设 Content-Type，避免触发 CORS 预检（OPTIONS）
      body: JSON.stringify({
        question: question,
        top_k: cfg.request.top_k,
      }),
      signal: AbortSignal.timeout(cfg.request.timeout_ms),
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status} ${res.statusText}`);
    }

    const data = await res.json();
    setApiOnline(true);
    renderAnswer(data, question);

  } catch (e) {
    setApiOnline(false);
    showError(e.message);
  }

  isSending = false;
  dom.input.disabled = false;
  dom.sendBtn.disabled = false;
  dom.input.focus();
}

// ==================== 渲染回答 ====================
function renderAnswer(data, question) {
  let html = '<div class="qa-answer">';

  // --- answer/description 文本 ---
  const answerText = (data && data.description) || (data && data.answer) || '';
  if (answerText) {
    html += `<div class="answer-text">${escHtml(answerText)}</div>`;
  }

  // --- sources: 解析出分类和文件 ---
  if (data && data.sources && data.sources.length > 0) {
    const catSet = new Set();
    data.sources.forEach((s) => {
      const p = parseFileName(s);
      if (p.category) catSet.add(p.category);
    });

    // categories from sources
    if (catSet.size > 0) {
      html += '<div class="kc-block">';
      html += '<div class="kc-label">📂 相关分类</div>';
      html += '<div class="kc-tags">';
      catSet.forEach((c) => {
        const icon = cfg.ui.category_icons[c] || cfg.ui.default_category_icon;
        html += `<span class="kc-tag">${icon} ${escHtml(c)}</span>`;
      });
      html += '</div></div>';
    }

    // files from sources
    html += '<div class="kc-block">';
    html += `<div class="kc-label">📄 相关文件 (${data.sources.length})</div>`;
    html += '<div class="kc-files">';
    data.sources.forEach((f) => {
      const parsed = parseFileName(f);
      const icon = cfg.ui.file_icons[parsed.ext] || cfg.ui.default_file_icon;
      html += `
        <div class="kc-file">
          <span class="file-icon">${icon}</span>
          <span class="file-name" title="${escAttr(parsed.name)}">${escHtml(parsed.name)}</span>
          <span class="file-type">${parsed.ext}</span>
        </div>`;
    });
    html += '</div></div>';
  }

  // --- error field ---
  if (data && data.error) {
    html += `<div class="qa-error">
      <span class="err-icon">⚠️</span>
      <p class="err-text">服务端错误</p>
      <p class="err-detail">${escHtml(data.error)}</p>
    </div>`;
  }

  // --- 空响应 ---
  const isEmpty = !data ||
    (!answerText &&
     (!data.sources || data.sources.length === 0) &&
     (!data.error));

  if (isEmpty) {
    html += `
      <div class="qa-state">
        <span class="state-icon">🤔</span>
        <p class="state-text">未找到与 "<strong>${escHtml(question)}</strong>" 相关的内容</p>
        <p class="state-hint">试试其他问题？</p>
      </div>`;
  }

  html += '</div>';
  dom.body.innerHTML = html;
  dom.body.scrollTop = 0;
}

// ==================== 状态切换 ====================
function showLoading() {
  dom.body.innerHTML = `
    <div class="typing-dots">
      <span></span><span></span><span></span>
    </div>`;
}

function showError(message) {
  const url = cfg.api.base + cfg.api.qa_endpoint;
  dom.body.innerHTML = `
    <div class="qa-error">
      <span class="err-icon">⚠️</span>
      <p class="err-text">请求失败</p>
      <p class="err-detail">${escHtml(message)} — 请确认 API 运行在 ${escHtml(url)}</p>
    </div>`;
}

// ==================== 工具函数 ====================

/**
 * 解析文件名 "[category] filename.ext"
 * 返回 { category, name, ext }
 */
function parseFileName(raw) {
  const match = raw.match(/^\[(.+?)\]\s*(.+)$/);
  const fullName = match ? match[2] : raw;
  const dotIdx = fullName.lastIndexOf('.');
  const name = dotIdx > 0 ? fullName.slice(0, dotIdx) : fullName;
  const ext  = dotIdx > 0 ? fullName.slice(dotIdx + 1).toLowerCase() : '';
  return {
    category: match ? match[1] : '',
    name: fullName,
    ext: ext,
  };
}

function escHtml(s) {
  const d = document.createElement('div');
  d.textContent = s || '';
  return d.innerHTML;
}

function escAttr(s) {
  return (s || '').replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// ==================== 启动 ====================
document.addEventListener('DOMContentLoaded', init);
