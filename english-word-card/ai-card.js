/**
 * english-word-card/ai-card.js
 * Template: Sticky note with tape + ribbon + English word + image
 * Interactive: click to speak English word + show Chinese meaning
 */

var PALETTE = {
  purple: { brand:'#8e44ad', light:'#f5f3ff', soft:'#ede9fe', gradStart:'#8e44ad', gradEnd:'#a78bfa' },
};

var THEME_MAP = { abc: 'purple' };

function themeColor(t) {
  var c = THEME_MAP[t || 'abc'] || 'purple';
  return PALETTE[c] || PALETTE.purple;
}

function speak(text, lang) {
  if (!window.speechSynthesis) return;
  window.speechSynthesis.cancel();
  var u = new SpeechSynthesisUtterance(text);
  u.lang = lang || 'en-US';
  u.rate = 0.85;
  u.pitch = 1.1;
  window.speechSynthesis.speak(u);
}

function esc(s) {
  if (s == null) return '';
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function cardHTML(d) {
  var word = d.subtitle || '';
  var zh = d.description || '';
  var ribbon = d.title || 'ABC';
  var btn = d.button_text || '单词发音';

  return '<div class="abc-card">' +
    '<div class="tape-decor"></div>' +
    '<div class="abc-ribbon">' + esc(ribbon) + '</div>' +
    '<div class="abc-body">' +
      '<div class="abc-row">' +
        '<div class="abc-word-area">' +
          '<div class="big-word" data-speak="' + esc(word) + '">' + esc(word) + '</div>' +
          (zh ? '<div class="word-zh">' + esc(zh) + '</div>' : '') +
        '</div>' +
        (d.target_url ? '<img class="abc-img" src="' + esc(d.target_url) + '" alt="' + esc(word) + '" data-speak="' + esc(word) + '">' : '') +
      '</div>' +
      '<div class="actions"><button class="btn primary" data-speak="' + esc(word) + '">' + esc(btn) + '</button></div>' +
    '</div>' +
  '</div>';
}

var AICard = (function () {
  var el = customElements.get('ai-card');
  if (el) return el;

  var Klass = function () {
    var self = Reflect.construct(HTMLElement, [], new.target);
    self.attachShadow({ mode: 'open' });
    self._connected = false;
    return self;
  };
  Klass.prototype = Object.create(HTMLElement.prototype);
  Klass.prototype.constructor = Klass;

  Object.defineProperty(Klass, 'observedAttributes', {
    get: function () { return ['data']; }
  });

  Klass.prototype.attributeChangedCallback = function () {
    if (this._connected) this._render();
  };

  Klass.prototype.connectedCallback = function () {
    this._connected = true;
    this._render();
  };

  Klass.prototype._render = function () {
    var raw = this.getAttribute('data');
    if (!raw) { this.shadowRoot.innerHTML = ''; return; }
    var d;
    try { d = JSON.parse(raw); } catch (e) { this.shadowRoot.innerHTML = ''; return; }

    var p = themeColor(d.theme);
    this.shadowRoot.innerHTML = '';

    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'ai-card.css';
    this.shadowRoot.appendChild(link);

    var vars = document.createElement('style');
    vars.textContent = ':host{--c-brand:' + p.brand + ';--c-light:' + p.light + ';--c-soft:' + p.soft + ';--c-grad-start:' + p.gradStart + ';--c-grad-end:' + p.gradEnd + '}';
    this.shadowRoot.appendChild(vars);

    var wrapper = document.createElement('div');
    wrapper.innerHTML = cardHTML(d);
    this.shadowRoot.appendChild(wrapper.firstElementChild);

    var self = this;
    setTimeout(function () {
      var zhEl = self.shadowRoot.querySelector('.word-zh');
      var timer = null;
      function showZh() {
        if (!zhEl) return;
        zhEl.classList.add('show');
        clearTimeout(timer);
        timer = setTimeout(function () { zhEl.classList.remove('show'); }, 2000);
      }
      var els = self.shadowRoot.querySelectorAll('[data-speak]');
      els.forEach(function (el) {
        el.addEventListener('click', function () {
          speak(el.getAttribute('data-speak'));
          showZh();
        });
      });
    }, 0);
  };

  customElements.define('ai-card', Klass);
  return Klass;
})();

window.renderCards = function (containerId, cards) {
  var root = document.getElementById(containerId);
  if (!root) return;
  root.innerHTML = cards.map(function (c) {
    var d = c.data;
    return '<ai-card data=\'' + JSON.stringify(d).replace(/'/g, '&#39;') + '\'></ai-card>';
  }).join('');
};

(function () {
  var root = document.getElementById('root');
  if (!root) return;
  var FILES = ['data.json'];
  var fallback = [{"schema_version":"1.0","card_type":"english_word","title":"ABC · 字母启蒙","subtitle":"apple","description":"苹果","button_text":"单词发音","target_url":"https://works.blazegraph.site/works/e02656c2-d563-4ca2-8406-33031d109b48/2-1-6-4-1779693877148/images/img16.png","theme":"abc","layout":{"variant":"english_word","icon":"abc"}}];

  var p = Promise.all(FILES.map(function (f) {
    return fetch(f).then(function (r) { return r.json(); });
  }));
  p.then(function (data) {
    renderCards('root', data.map(function (d) { return { data: d }; }));
  }).catch(function () {
    renderCards('root', fallback.map(function (d) { return { data: d }; }));
  });
})();
