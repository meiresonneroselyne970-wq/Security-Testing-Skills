/* ========================================
   炎图 AI 知识问答 — 问答卡片逻辑（精简版）
   只保留问答结果展示 + 临时输入窗口
   ======================================== */

// ==================== DOM 引用 ====================
const $ = (sel) => document.querySelector(sel);

const dom = {
  body:    $('#qaBody'),
  input:   $('#qaInput'),
  sendBtn: $('#sendBtn'),
};

// ==================== 配置（硬编码，无需 data.json） ====================
const API_BASE   = 'http://127.0.0.1:8899';
const QA_URL     = API_BASE + '/qa';
const TOP_K      = 5;
const TIMEOUT_MS = 30000;

// 文件类型 → 图标 & CSS class
const FILE_META = {
  md:   { icon: '📘', cls: 'md' },
  docx: { icon: '📄', cls: 'docx' },
  doc:  { icon: '📄', cls: 'docx' },
  pptx: { icon: '📊', cls: 'pptx' },
  ppt:  { icon: '📊', cls: 'pptx' },
  pdf:  { icon: '📕', cls: 'pdf' },
  xlsx: { icon: '📈', cls: 'xlsx' },
  xls:  { icon: '📈', cls: 'xlsx' },
  txt:  { icon: '📝', cls: 'txt' },
};
const FILE_OTHER = { icon: '📎', cls: 'other' };

// ==================== 状态 ====================
let isSending = false;

// ==================== 初始化 ====================
function init() {
  bindEvents();
}

// ==================== 事件绑定 ====================
function bindEvents() {
  dom.sendBtn.addEventListener('click', ask);
  dom.input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') ask();
  });
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
    const res = await fetch(QA_URL, {
      method: 'POST',
      body: JSON.stringify({ question, top_k: TOP_K }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status} ${res.statusText}`);
    }

    const data = await res.json();
    renderAnswer(data, question);

  } catch (e) {
    showError(e.message);
  }

  isSending = false;
  dom.input.disabled = false;
  dom.sendBtn.disabled = false;
  dom.input.focus();
}

// ==================== 渲染回答结果 ====================
function renderAnswer(data, question) {
  let html = '<div class="qa-answer">';

  // --- 回答文本 ---
  const answerText = (data && data.description) || (data && data.answer) || '';
  if (answerText) {
    html += '<div class="answer-header">';
    html += '<div class="answer-avatar">AI</div>';
    html += '<div class="answer-meta">';
    html += '<span class="answer-label">AI 回答</span>';
    html += '<span class="answer-badge"><span>●</span> 基于知识库</span>';
    html += '</div></div>';
    html += `<div class="answer-text">${escHtml(answerText)}</div>`;
  }

  // --- 来源文件 ---
  if (data && data.sources && data.sources.length > 0) {
    html += '<div class="sources-block">';
    html += '<div class="sources-header">';
    html += '<span class="sources-label"><span class="label-icon">📂</span>参考来源</span>';
    html += `<span class="sources-count">${data.sources.length} 个文件</span>`;
    html += '</div>';
    html += '<div class="sources-files">';
    data.sources.forEach((f) => {
      const parsed = parseFileName(f);
      const meta = FILE_META[parsed.ext] || FILE_OTHER;
      html += `
        <div class="source-file">
          <span class="file-icon-wrap type-${meta.cls}">${meta.icon}</span>
          <div class="file-info">
            <div class="file-name" title="${escAttr(parsed.name)}">${escHtml(parsed.name)}</div>
            ${parsed.category ? `<div class="file-category">📁 ${escHtml(parsed.category)}</div>` : ''}
          </div>
          <span class="file-type-tag tag-${meta.cls}">${parsed.ext || 'file'}</span>
        </div>`;
    });
    html += '</div></div>';
  }

  // --- 错误 ---
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
        <p class="state-hint">试试换个问题？</p>
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
  dom.body.innerHTML = `
    <div class="qa-error">
      <span class="err-icon">⚠️</span>
      <p class="err-text">请求失败</p>
      <p class="err-detail">${escHtml(message)}</p>
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
  return { category: match ? match[1] : '', name: fullName, ext };
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
