/**
 * homework-card/ai-card.js — 作业提醒卡片
 * 模板：学科色条横幅（标题+教师+学科标签）+ 描述 + 按钮
 */
const BASE = document.currentScript
  ? new URL('.', document.currentScript.src).href
  : location.href;

const PALETTE = {
  red:     { brand:'#dc2626', light:'#fef2f2', soft:'#fee2e2', gradStart:'#dc2626', gradEnd:'#f87171' },
  blue:    { brand:'#3b82f6', light:'#eff6ff', soft:'#dbeafe', gradStart:'#3b82f6', gradEnd:'#60a5fa' },
  green:   { brand:'#16a34a', light:'#f0fdf4', soft:'#dcfce7', gradStart:'#16a34a', gradEnd:'#4ade80' },
};

function themeColor(t) { const n=(t||'blue_white').split('_')[0]; return PALETTE[n]||PALETTE.blue; }

const ICONS = { chinese:'📖', math:'📐', english:'🌐', homework:'📖' };
function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'homework'; return ICONS[i]||'📖'; }

function subjectFromTheme(t) { const c=(t||'').split('_')[0]; return {red:'chinese',blue:'math',green:'english'}[c]||''; }
function subjectLabel(s) { return {chinese:'语文',math:'数学',english:'英语'}[s]||''; }

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
    wrapper.innerHTML = homeworkHTML(d);
    this.shadowRoot.appendChild(wrapper.firstElementChild);
  }
}

function homeworkHTML(d) {
  const icon = iconEmoji(d);
  const label = subjectLabel(subjectFromTheme(d.theme));
  const btn = d.button_text || '查看作业';
  return `
<div class="card">
  <div class="bar">
    <div class="bicon">${icon}</div>
    <div class="binfo">
      <div class="btitle">${esc(d.title)}</div>
      ${d.subtitle?`<div class="bsub">${esc(d.subtitle)}</div>`:''}
      ${label?`<span class="bbadge">${label}</span>`:''}
    </div>
  </div>
  <div class="card-body">
    ${d.description?`<div class="desc">${esc(d.description)}</div>`:''}
    <div class="actions"><button class="btn primary">${esc(btn)}</button></div>
  </div>
</div>`;
}

function esc(s) { if(s==null)return''; return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

if (!customElements.get('ai-card')) customElements.define('ai-card', AICard);

// ── 卡片列表渲染 ──
(function(){
  if (typeof CARDS==='undefined') return;
  var root=document.getElementById('root');
  if (!root) return;
  root.innerHTML=CARDS.map(function(c){
    return '<div class="wrap"><span class="label">'+c.file+' · '+c.data.theme+' · icon='+c.data.layout.icon+'</span><ai-card data=\''+JSON.stringify(c.data)+'\'></ai-card></div>';
  }).join('');
})();
