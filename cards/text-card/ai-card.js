/**
 * text-card/ai-card.js — 文本类卡片（h5_entry / assistant_welcome / recommendation / task / health_advice）
 * 模板：顶部渐变装饰条 + 左侧品牌色条 + 图标标题 + 描述 + 按钮
 */
const PALETTE = {
  blue:    { brand:'#3b82f6', light:'#eff6ff', soft:'#dbeafe', gradStart:'#3b82f6', gradEnd:'#60a5fa' },
  purple:  { brand:'#8b5cf6', light:'#f5f3ff', soft:'#ede9fe', gradStart:'#8b5cf6', gradEnd:'#a78bfa' },
  cyan:    { brand:'#0891b2', light:'#ecfeff', soft:'#cffafe', gradStart:'#0891b2', gradEnd:'#22d3ee' },
  amber:   { brand:'#d97706', light:'#fffbeb', soft:'#fef3c7', gradStart:'#d97706', gradEnd:'#fbbf24' },
  emerald: { brand:'#059669', light:'#ecfdf5', soft:'#d1fae5', gradStart:'#059669', gradEnd:'#34d399' },
};

var THEME_MAP = { general:'blue', ai:'purple', recommendation:'cyan', task:'amber', health:'emerald' };
function themeColor(t) { var c = THEME_MAP[t||'general'] || 'blue'; return PALETTE[c] || PALETTE.blue; }

const ICONS = { ai:'🤖', link:'🔗', sparkle:'✨', task:'📋', health:'💊', audio:'🎧' };
function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'link'; return ICONS[i]||'🔗'; }

const BADGES = { h5_entry:'H5 入口', assistant_welcome:'AI 助手', recommendation:'AI 推荐', task:'', health_advice:'' };

class AICard extends HTMLElement {
  constructor() { super(); this.attachShadow({ mode:'open' }); this._connected = false; }
  static get observedAttributes() { return ['data']; }
  attributeChangedCallback() { if (this._connected) this.render(); }
  connectedCallback() { this._connected = true; this.render(); }

  render() {
    const raw = this.getAttribute('data');
    if (!raw) { this.shadowRoot.innerHTML=''; return; }
    let d; try { d=JSON.parse(raw); } catch { this.shadowRoot.innerHTML=''; return; }
    const p = themeColor(d.theme);
    this.shadowRoot.innerHTML='';

    const link = document.createElement('link');
    link.rel='stylesheet'; link.href='ai-card.css';
    this.shadowRoot.appendChild(link);

    const vars = document.createElement('style');
    vars.textContent = `:host{--c-brand:${p.brand};--c-light:${p.light};--c-soft:${p.soft};--c-grad-start:${p.gradStart};--c-grad-end:${p.gradEnd}}`;
    this.shadowRoot.appendChild(vars);

    const wrapper = document.createElement('div');
    wrapper.innerHTML = defaultHTML(d);
    this.shadowRoot.appendChild(wrapper.firstElementChild);
  }
}

function defaultHTML(d) {
  const icon = iconEmoji(d);
  const badge = BADGES[d.card_type] || '';
  const btn = d.button_text || '打开页面';
  return `
<div class="card">
  <div class="strip"></div>
  <div class="card-body">
    <div class="hdr">
      <div class="icon">${icon}</div>
      <div class="hinfo">
        <div class="title">${esc(d.title)}</div>
        ${d.subtitle?`<div class="subtitle">${esc(d.subtitle)}</div>`:''}
        ${badge?`<span class="badge">${badge}</span>`:''}
      </div>
    </div>
    ${d.description?`<div class="desc">${esc(d.description)}</div>`:''}
    <div class="actions"><button class="btn primary">${esc(btn)}</button></div>
  </div>
</div>`;
}

function esc(s) { if(s==null)return''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

if (!customElements.get('ai-card')) customElements.define('ai-card', AICard);

window.renderCards = function(containerId, cards) {
  var root = document.getElementById(containerId);
  if (!root) return;
  root.innerHTML = cards.map(function(c) {
    var d = c.data;
    var label = esc((d.layout&&d.layout.variant||d.card_type) + ' · ' + d.theme);
    return '<div class="wrap"><span class="label">'+label+'</span><ai-card data=\''+JSON.stringify(d)+'\'></ai-card></div>';
  }).join('');
};

(function() {
  var root = document.getElementById('root');
  if (!root) return;
  var DATA_FILES = [
    {"schema_version":"1.0","card_type":"h5_entry","title":"炎图 AI 助手","subtitle":"我已加入当前聊天室","description":"可以为你提供智能协同服务，点击查看推荐内容。","button_text":"打开页面","target_url":"https://www.baidu.com","theme":"general","layout":{"variant":"h5_entry","icon":"ai"}},
    {"schema_version":"1.0","card_type":"h5_entry","title":"作文范文：我的家乡","subtitle":"点击查看完整内容与老师点评","description":"三年级优秀作文展示，包含老师点评与修改建议。","button_text":"查看范文","target_url":"https://example.com/essay","theme":"general","layout":{"variant":"h5_entry","icon":"link"}},
    {"schema_version":"1.0","card_type":"assistant_welcome","title":"教育 AI 助手","subtitle":"已就绪 · 随时为你服务","description":"我可以帮你完成：布置作业、批改作文、生成课程总结、回答学科问题。试试对我说「总结今天课程」吧！","button_text":"开始对话","target_url":"https://example.com/edu-ai","theme":"ai","layout":{"variant":"assistant_welcome","icon":"ai"}},
    {"schema_version":"1.0","card_type":"assistant_welcome","title":"医疗 AI 助手","subtitle":"已就绪 · 李医生随访团队","description":"我可以帮你：定时用药提醒、复诊预约、健康报告解读、饮食运动建议。对我说「今天药吃了吗」试试！","button_text":"开始对话","target_url":"https://example.com/medical-ai","theme":"health","layout":{"variant":"assistant_welcome","icon":"ai"}},
    {"schema_version":"1.0","card_type":"recommendation","title":"英语口语 · 餐厅点餐场景","subtitle":"根据你的学习进度智能推荐","description":"包含 12 组实用对话，覆盖点餐、结账、询问优惠等常见场景。AI 实时评分并给出改进建议。约 15 分钟 · 4.8 分 · 326 人练过。","button_text":"开始练习","target_url":"https://example.com/oral-practice","theme":"recommendation","layout":{"variant":"recommendation","icon":"audio"}},
    {"schema_version":"1.0","card_type":"task","title":"班级群 · 教学周报汇总","subtitle":"由班主任发起 · 三年级组","description":"请各科老师在周五前提交本周教学周报（语文、数学、英语、科学），汇总后将统一发送至年级组存档。","button_text":"提交我的","target_url":"https://task.example.com/weekly-report","theme":"task","layout":{"variant":"task","icon":"task"}},
    {"schema_version":"1.0","card_type":"health_advice","title":"服药提醒 · 阿莫西林","subtitle":"医疗 AI 助手 · 李医生随访","description":"每日 3 次，每次 1 粒，饭后服用。请勿与牛奶同服，两次用药间隔至少 6 小时。本次疗程剩余 5 天，下次服药时间：今天 18:30。","button_text":"确认已服药","target_url":"https://health.example.com/medication/confirm","theme":"health","layout":{"variant":"health_advice","icon":"health"}}
  ];
  renderCards('root', DATA_FILES.map(function(d) { return { data:d }; }));
})();
