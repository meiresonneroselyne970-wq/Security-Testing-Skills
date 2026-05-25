/**
 * text-card/ai-card.js — 文本类卡片（h5_entry / assistant_welcome / recommendation / task / health_advice）
 * 模板：顶部渐变装饰条 + 左侧品牌色条 + 图标标题 + 描述 + 按钮
 */
const BASE = document.currentScript
  ? new URL('.', document.currentScript.src).href
  : location.href;

const PALETTE = {
  blue:    { brand:'#3b82f6', light:'#eff6ff', soft:'#dbeafe', gradStart:'#3b82f6', gradEnd:'#60a5fa' },
  purple:  { brand:'#8b5cf6', light:'#f5f3ff', soft:'#ede9fe', gradStart:'#8b5cf6', gradEnd:'#a78bfa' },
  red:     { brand:'#dc2626', light:'#fef2f2', soft:'#fee2e2', gradStart:'#dc2626', gradEnd:'#f87171' },
  green:   { brand:'#16a34a', light:'#f0fdf4', soft:'#dcfce7', gradStart:'#16a34a', gradEnd:'#4ade80' },
  cyan:    { brand:'#0891b2', light:'#ecfeff', soft:'#cffafe', gradStart:'#0891b2', gradEnd:'#22d3ee' },
  amber:   { brand:'#d97706', light:'#fffbeb', soft:'#fef3c7', gradStart:'#d97706', gradEnd:'#fbbf24' },
  emerald: { brand:'#059669', light:'#ecfdf5', soft:'#d1fae5', gradStart:'#059669', gradEnd:'#34d399' },
  indigo:  { brand:'#4f46e5', light:'#eef2ff', soft:'#e0e7ff', gradStart:'#4f46e5', gradEnd:'#818cf8' },
};

function themeColor(t) { const n=(t||'blue_white').split('_')[0]; return PALETTE[n]||PALETTE.blue; }

const ICONS = { ai:'🤖', link:'🔗', sparkle:'✨', task:'📋', health:'💊', audio:'🎧' };
function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'link'; return ICONS[i]||'🔗'; }

const BADGES = { h5_entry:'H5 入口', assistant_welcome:'AI 助手', recommendation:'AI 推荐', task:'', health_advice:'' };

class AICard extends HTMLElement {
  constructor() { super(); this.attachShadow({ mode:'open' }); }
  static get observedAttributes() { return ['data']; }
  attributeChangedCallback() { this.render(); }
  connectedCallback() { this.render(); }

  render() {
    const raw = this.getAttribute('data');
    if (!raw) { this.shadowRoot.innerHTML=''; return; }
    let d; try { d=JSON.parse(raw); } catch { this.shadowRoot.innerHTML=''; return; }
    const p = themeColor(d.theme);
    this.shadowRoot.innerHTML='';

    const link = document.createElement('link');
    link.rel='stylesheet'; link.href=new URL('./ai-card.css', BASE).href;
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

(function(){
  if (typeof CARDS==='undefined') return;
  var root=document.getElementById('root');
  if (!root) return;
  root.innerHTML=CARDS.map(function(c){
    return '<div class="wrap"><span class="label">'+c.file+' · '+c.data.theme+' · icon='+c.data.layout.icon+'</span><ai-card data=\''+JSON.stringify(c.data)+'\'></ai-card></div>';
  }).join('');
})();
