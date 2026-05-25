/**
 * media-card/ai-card.js — 媒体预览卡片
 * 模板：暗色媒体预览区（类型标签+播放按钮+时长）+ 标题 + 描述 + 按钮
 */
const BASE = document.currentScript
  ? new URL('.', document.currentScript.src).href
  : location.href;

const PALETTE = {
  indigo:  { brand:'#4f46e5', light:'#eef2ff', soft:'#e0e7ff', gradStart:'#4f46e5', gradEnd:'#818cf8' },
};

function themeColor(t) { const n=(t||'indigo_white').split('_')[0]; return PALETTE[n]||PALETTE.indigo; }

const ICONS = { video:'🎬', audio:'🎧', image:'🖼', file:'📄' };
function iconEmoji(d) { const i=(d.layout&&d.layout.icon)||'video'; return ICONS[i]||'🎬'; }

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
    wrapper.innerHTML = mediaHTML(d);
    this.shadowRoot.appendChild(wrapper.firstElementChild);
  }
}

function mediaHTML(d) {
  const btn = d.button_text || '播放视频';
  const mtype = (d.layout&&d.layout.icon)||'video';
  const typeLabel = { video:'视频', audio:'音频', image:'图片', file:'文件' }[mtype]||'文件';
  return `
<div class="card">
  <div class="media-area">
    <span class="media-badge">${typeLabel}</span>
    <div class="media-play">▶</div>
    ${d.subtitle?`<span class="media-dur">${esc(d.subtitle)}</span>`:''}
  </div>
  <div class="card-body">
    <div class="hdr">
      <div class="icon">${iconEmoji(d)}</div>
      <div class="hinfo"><div class="title">${esc(d.title)}</div></div>
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
