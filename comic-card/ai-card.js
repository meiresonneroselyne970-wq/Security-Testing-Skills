/**
 * comic-card/ai-card.js
 * Template: Video player + paginated comic strip (one frame per page)
 */

var PALETTE = {
  amber: { brand:'#f59e0b', light:'#fffbeb', soft:'#fef3c7', gradStart:'#f59e0b', gradEnd:'#fbbf24' },
};

var THEME_MAP = { comic: 'amber' };

function themeColor(t) {
  var c = THEME_MAP[t || 'comic'] || 'amber';
  return PALETTE[c] || PALETTE.amber;
}

var BUBBLE_CLASSES = ['left', 'right', 'center'];

function esc(s) {
  if (s == null) return '';
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function cardHTML(d) {
  var title = d.title || '';
  var subtitle = d.subtitle || '';
  var desc = d.description || '';
  var videoUrl = d.video_url || '';
  var frames = d.frames || [];
  var total = frames.length;

  return '<div class="comic-card">' +
    (videoUrl ? '<div class="video-area"><video controls src="' + esc(videoUrl) + '"></video></div>' : '') +
    '<div class="card-body">' +
      '<div class="hdr">' +
        '<div class="title">' + esc(title) + '</div>' +
        (subtitle ? '<div class="subtitle">' + esc(subtitle) + '</div>' : '') +
      '</div>' +
      (desc ? '<div class="desc">' + esc(desc) + '</div>' : '') +
      '<div class="comic-viewport"></div>' +
      '<div class="nav">' +
        '<button class="nav-btn" data-nav="prev" disabled>← 上一页</button>' +
        '<button class="nav-btn primary" data-nav="next">下一页 →</button>' +
      '</div>' +
    '</div>' +
  '</div>';
}

function renderFrame(viewport, frame, index, total) {
  var texts = frame.texts || [];
  var html = '<div class="page-indicator">' + (index + 1) + ' / ' + total + '</div>' +
    '<div class="frame-container"><img class="frame-img" src="' + esc(frame.image) + '" alt="panel ' + (index + 1) + '">' +
    '<div class="bubbles">';
  for (var j = 0; j < texts.length; j++) {
    var cls = BUBBLE_CLASSES[j] || 'center';
    if (j === 1 && texts.length === 2) cls += ' bottom';
    html += '<div class="bubble ' + cls + '">' + esc(texts[j]) + '</div>';
  }
  html += '</div></div>';
  viewport.innerHTML = html;
}

var AICard = (function () {
  var el = customElements.get('ai-card');
  if (el) return el;

  var Klass = function () {
    var self = Reflect.construct(HTMLElement, [], new.target);
    self.attachShadow({ mode: 'open' });
    self._connected = false;
    self._current = 0;
    self._frames = [];
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
    this._frames = d.frames || [];
    this._current = 0;
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
    var total = this._frames.length;
    var viewport = this.shadowRoot.querySelector('.comic-viewport');
    var prevBtn = this.shadowRoot.querySelector('[data-nav="prev"]');
    var nextBtn = this.shadowRoot.querySelector('[data-nav="next"]');

    if (total > 0) {
      renderFrame(viewport, this._frames[0], 0, total);
    }

    function updateNav() {
      prevBtn.disabled = self._current === 0;
      nextBtn.disabled = self._current === total - 1;
    }

    prevBtn.addEventListener('click', function () {
      if (self._current > 0) {
        self._current--;
        renderFrame(viewport, self._frames[self._current], self._current, total);
        updateNav();
      }
    });

    nextBtn.addEventListener('click', function () {
      if (self._current < total - 1) {
        self._current++;
        renderFrame(viewport, self._frames[self._current], self._current, total);
        updateNav();
      }
    });

    updateNav();
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
  var fallback = [{
    "schema_version": "1.0",
    "card_type": "comic_strip",
    "title": "PEP 人教版 · Unit 1 Describing People",
    "subtitle": "Story Time — We Are Twins!",
    "description": "Watch the video first, then flip through the comic story. Practice describing body features with Meimei and Feifei!",
    "button_text": "查看完整内容",
    "video_url": "../assets/video/activity1.mp4",
    "theme": "comic",
    "frames": [
      {"image": "../assets/image/panel1.jpg", "texts": ["Hi, I'm Meimei.", "I'm Feifei.", "We are twins."]},
      {"image": "../assets/image/panel2.jpg", "texts": ["I have big eyes.", "Me too."]},
      {"image": "../assets/image/panel3.jpg", "texts": ["I have a small nose.", "Me too."]},
      {"image": "../assets/image/panel4.jpg", "texts": ["I have a small mouth.", "Me too."]},
      {"image": "../assets/image/panel5.jpg", "texts": ["We look the same.", "I know!"]},
      {"image": "../assets/image/panel6.jpg", "texts": ["Now I have long hair.", "I have short hair.", "We are different now."]}
    ],
    "layout": { "variant": "comic_strip", "icon": "comic" }
  }];

  var p = Promise.all(FILES.map(function (f) {
    return fetch(f).then(function (r) { return r.json(); });
  }));
  p.then(function (data) {
    renderCards('root', data.map(function (d) { return { data: d }; }));
  }).catch(function () {
    renderCards('root', fallback.map(function (d) { return { data: d }; }));
  });
})();
