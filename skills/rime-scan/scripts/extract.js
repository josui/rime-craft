/**
 * rime-scan extract.js
 * 注入目标页面执行的设计语言提取脚本。
 * 调用方式：const result = rimeScanExtract({ form, nav, patterns, effects })
 * 返回：scan JSON 的 extracted 部分 + meta 部分
 */
window.rimeScanExtract = function(scope = {}) {
  const { form = false, nav = false, patterns = false, effects = false } = scope;

  // ── 工具函数 ──────────────────────────────────────────────

  /** 将 rgba/rgb 字符串标准化为 hex，忽略透明色 */
  function normalizeColor(str) {
    if (!str || str === 'transparent' || str === 'rgba(0, 0, 0, 0)') return null;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = 1;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = str;
    ctx.fillRect(0, 0, 1, 1);
    const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
    if (a < 10) return null; // 近透明
    return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');
  }

  /** 统计数组中各值出现频率，返回按频率降序排列的去重数组（top N）*/
  function topByFrequency(arr, top = 10) {
    const freq = {};
    arr.forEach(v => { if (v) freq[v] = (freq[v] || 0) + 1; });
    return Object.entries(freq)
      .sort((a, b) => b[1] - a[1])
      .slice(0, top)
      .map(([v]) => v);
  }

  /** 解析 px 字符串为数值，失败返回 null */
  function parsePx(str) {
    const n = parseFloat(str);
    return isNaN(n) ? null : n;
  }

  /** 对一组数值求最大公约数（推断 base unit）*/
  function inferBaseUnit(values) {
    const ints = values.map(v => Math.round(v)).filter(v => v > 0);
    if (ints.length === 0) return null;
    const gcd = (a, b) => b === 0 ? a : gcd(b, a % b);
    return ints.reduce(gcd);
  }

  /** 从元素提取视觉相关样式（供 pattern 提取使用）*/
  function extractVisualStyles(el) {
    const cs = getComputedStyle(el);
    const result = {};
    const props = ['padding', 'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
      'borderRadius', 'background', 'backgroundColor', 'boxShadow', 'border',
      'borderColor', 'display', 'flexDirection', 'gap', 'gridTemplateColumns',
      'color', 'fontSize', 'fontWeight'];
    props.forEach(p => {
      const v = cs[p];
      if (v && v !== 'none' && v !== 'normal' && v !== '0px' && v !== 'auto') {
        result[p] = v;
      }
    });
    return result;
  }

  /**
   * 视觉容器策略：input 系列的 border 可能在 wrapper 上
   * 向上最多走 3 层父元素找第一个有 border 的元素
   */
  function getVisualContainer(el) {
    const cs = getComputedStyle(el);
    if (cs.borderStyle !== 'none' && cs.borderWidth !== '0px') return el;
    let cur = el.parentElement;
    for (let i = 0; i < 3 && cur; i++, cur = cur.parentElement) {
      const pcs = getComputedStyle(cur);
      if (pcs.borderStyle !== 'none' && pcs.borderWidth !== '0px') return cur;
    }
    return el;
  }

  // ── 提取各 Section ──────────────────────────────────────

  const result = {
    meta: {
      url: location.href,
      title: document.title,
      scannedAt: new Date().toISOString().split('T')[0],
      mode: 'url',
      scope: ['token', 'ui', ...(form ? ['form'] : []), ...(nav ? ['nav'] : []),
              ...(patterns ? ['patterns'] : []), ...(effects ? ['effects'] : [])],
      extractionError: null
    },
    extracted: {}
  };

  // ── 颜色 ──────────────────────────────────────────────────
  try {
    const colorProps = [];
    for (const sheet of document.styleSheets) {
      try {
        for (const rule of sheet.cssRules) {
          if (rule.selectorText === ':root' || rule.selectorText === 'html') {
            const text = rule.cssText;
            const matches = text.matchAll(/(--[\w-]+):\s*([^;]+)/g);
            for (const m of matches) {
              const val = m[2].trim();
              if (/^#|rgb|hsl/.test(val)) colorProps.push(`${m[1]}: ${val}`);
            }
          }
        }
      } catch (_) {} // cross-origin stylesheet — skip
    }

    const allElements = Array.from(document.querySelectorAll('*')).slice(0, 500);
    const bgs = [], texts = [], borders = [], accents = [];

    allElements.forEach(el => {
      const cs = getComputedStyle(el);
      const bg = normalizeColor(cs.backgroundColor);
      const color = normalizeColor(cs.color);
      const bc = normalizeColor(cs.borderColor);
      if (bg) bgs.push(bg);
      if (color) texts.push(color);
      if (bc) borders.push(bc);
    });

    // 强调色：从 button 和 a 的 background/color 收集
    document.querySelectorAll('button, a').forEach(el => {
      const cs = getComputedStyle(el);
      const bg = normalizeColor(cs.backgroundColor);
      const color = normalizeColor(cs.color);
      if (bg && bg !== '#ffffff' && bg !== '#000000') accents.push(bg);
      if (color) accents.push(color);
    });

    result.extracted.colors = {
      properties: colorProps.slice(0, 20),
      computed: {
        backgrounds: topByFrequency(bgs),
        texts: topByFrequency(texts),
        borders: topByFrequency(borders),
        accents: topByFrequency(accents, 5)
      }
    };
  } catch (e) {
    result.extracted.colors = null;
  }

  // ── 字体 ──────────────────────────────────────────────────
  try {
    const families = [], sizes = [], weights = [], lineHeights = [];
    const sampleEls = Array.from(document.querySelectorAll('h1,h2,h3,h4,p,span,a,button,li,td'))
      .slice(0, 200);

    sampleEls.forEach(el => {
      const cs = getComputedStyle(el);
      const family = cs.fontFamily.split(',')[0].replace(/['"]/g, '').trim();
      const size = parsePx(cs.fontSize);
      const weight = cs.fontWeight;
      const lh = parseFloat(cs.lineHeight) / parseFloat(cs.fontSize);

      if (family) families.push(family);
      if (size) sizes.push(size);
      if (weight) weights.push(weight);
      if (!isNaN(lh)) lineHeights.push(Math.round(lh * 100) / 100);
    });

    result.extracted.typography = {
      families: topByFrequency(families, 5),
      sizes: topByFrequency(sizes.map(String), 10).map(Number).sort((a, b) => a - b),
      weights: [...new Set(weights)].sort(),
      lineHeights: [...new Set(lineHeights)].sort()
    };
  } catch (e) {
    result.extracted.typography = null;
  }

  // ── 间距 ──────────────────────────────────────────────────
  try {
    const spacingValues = [];
    const sampleEls = Array.from(document.querySelectorAll('*')).slice(0, 300);

    sampleEls.forEach(el => {
      const cs = getComputedStyle(el);
      ['paddingTop','paddingBottom','paddingLeft','paddingRight',
       'marginTop','marginBottom','gap','rowGap','columnGap'].forEach(prop => {
        const v = parsePx(cs[prop]);
        if (v && v > 0 && v < 200) spacingValues.push(v);
      });
    });

    const uniqueValues = [...new Set(spacingValues)].sort((a, b) => a - b);
    result.extracted.spacing = {
      values: uniqueValues.slice(0, 15),
      baseUnit: inferBaseUnit(uniqueValues)
    };
  } catch (e) {
    result.extracted.spacing = null;
  }

  // ── Layout ──────────────────────────────────────────────
  try {
    const allEls = Array.from(document.querySelectorAll('*'));
    const maxWidths = allEls.map(el => getComputedStyle(el).maxWidth)
      .filter(v => v && v !== 'none' && v.endsWith('px'));
    const topMaxWidth = topByFrequency(maxWidths, 3)[0] || null;

    const breakpoints = new Set();
    for (const sheet of document.styleSheets) {
      try {
        for (const rule of sheet.cssRules) {
          if (rule.media) {
            const mq = rule.conditionText || rule.media.mediaText;
            const match = mq.match(/(\d+)px/g);
            if (match) match.forEach(bp => breakpoints.add(bp));
          }
        }
      } catch (_) {}
    }

    let gridColumns = null;
    for (const el of allEls) {
      const cs = getComputedStyle(el);
      if (cs.display === 'grid' && cs.gridTemplateColumns !== 'none') {
        const cols = cs.gridTemplateColumns.split(' ').length;
        if (cols > 1) { gridColumns = cols; break; }
      }
    }

    result.extracted.layout = {
      maxWidth: topMaxWidth,
      breakpoints: [...breakpoints].sort((a, b) => parseInt(a) - parseInt(b)),
      gridColumns
    };
  } catch (e) {
    result.extracted.layout = null;
  }

  // ── Shape（border-radius / shadow）────────────────────────
  try {
    const radii = [], shadows = [];
    Array.from(document.querySelectorAll('*')).slice(0, 300).forEach(el => {
      const cs = getComputedStyle(el);
      const r = parsePx(cs.borderRadius);
      if (r !== null) radii.push(r);
      const s = cs.boxShadow;
      if (s && s !== 'none') shadows.push(s);
    });

    result.extracted.shape = {
      borderRadius: [...new Set(radii)].sort((a, b) => a - b).slice(0, 8),
      shadows: topByFrequency(shadows, 5)
    };
  } catch (e) {
    result.extracted.shape = null;
  }

  // ── UI 组件（始终）────────────────────────────────────────
  try {
    const btn = document.querySelector('button');
    const link = document.querySelector('a');
    result.extracted.ui = {};

    if (btn) {
      const cs = getComputedStyle(btn);
      result.extracted.ui.button = {
        padding: cs.padding,
        borderRadius: cs.borderRadius,
        background: cs.backgroundColor,
        color: cs.color,
        fontSize: cs.fontSize,
        fontWeight: cs.fontWeight,
        border: cs.border
      };
    }

    if (link) {
      const cs = getComputedStyle(link);
      result.extracted.ui.link = {
        color: cs.color,
        fontWeight: cs.fontWeight,
        textDecoration: cs.textDecoration
      };
    }
  } catch (e) {
    result.extracted.ui = null;
  }

  // ── 表单元素（scope: form）────────────────────────────────
  if (form) {
    try {
      result.extracted.form = {};
      const input = document.querySelector('input:not([type="hidden"])');
      const select = document.querySelector('select');
      const textarea = document.querySelector('textarea');

      if (input) {
        const target = getVisualContainer(input);
        const cs = getComputedStyle(target);
        result.extracted.form.input = {
          padding: cs.padding,
          borderRadius: cs.borderRadius,
          border: cs.border,
          background: cs.backgroundColor,
          fontSize: getComputedStyle(input).fontSize
        };
      }
      if (select) {
        const target = getVisualContainer(select);
        const cs = getComputedStyle(target);
        result.extracted.form.select = {
          padding: cs.padding,
          borderRadius: cs.borderRadius,
          border: cs.border,
          background: cs.backgroundColor,
          fontSize: getComputedStyle(select).fontSize
        };
      }
      if (textarea) {
        const target = getVisualContainer(textarea);
        const cs = getComputedStyle(target);
        result.extracted.form.textarea = {
          padding: cs.padding,
          borderRadius: cs.borderRadius,
          border: cs.border,
          background: cs.backgroundColor,
          fontSize: getComputedStyle(textarea).fontSize
        };
      }
    } catch (e) {
      result.extracted.form = null;
    }
  }

  // ── 导航 / 头部（scope: nav）──────────────────────────────
  if (nav) {
    try {
      const navEl = document.querySelector('nav') || document.querySelector('header');
      if (navEl) {
        const cs = getComputedStyle(navEl);
        result.extracted.navigation = {
          background: cs.backgroundColor,
          borderBottom: cs.borderBottom,
          height: cs.height,
          position: cs.position
        };
      }
    } catch (e) {
      result.extracted.navigation = null;
    }
  }

  // ── 重复 pattern（scope: patterns）───────────────────────
  if (patterns) {
    try {
      const utilityPrefixes = ['flex','grid','w-','h-','p-','px-','py-','pt-','pb-','pl-','pr-',
        'm-','mx-','my-','mt-','mb-','ml-','mr-','text-','font-','bg-','border-','rounded',
        'gap-','space-','items-','justify-','content-','overflow-','relative','absolute',
        'fixed','sticky','hidden','block','inline','z-','opacity-','transition','duration-',
        'ease-','cursor-','select-','resize-','list-','table-','sr-','not-sr-','container',
        'aspect-','basis-','grow','shrink','order-','col-','row-','place-'];

      const isUtility = cls =>
        utilityPrefixes.some(p => cls.startsWith(p)) || cls.length < 2;

      const classCount = {};
      document.querySelectorAll('[class]').forEach(el => {
        el.className.split(/\s+/).forEach(cls => {
          if (!isUtility(cls)) classCount[cls] = (classCount[cls] || 0) + 1;
        });
      });

      const topClasses = Object.entries(classCount)
        .filter(([, count]) => count >= 3)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);

      result.extracted.patterns = topClasses.map(([cls, count]) => {
        const el = document.querySelector(`.${CSS.escape(cls)}`);
        if (!el) return null;
        return {
          selector: `.${cls}`,
          count,
          tag: el.tagName.toLowerCase(),
          styles: extractVisualStyles(el),
          children: [...new Set(Array.from(el.children).map(c => c.tagName.toLowerCase()))]
        };
      }).filter(Boolean);
    } catch (e) {
      result.extracted.patterns = null;
    }
  }

  // ── 视觉效果（scope: effects）────────────────────────────
  if (effects) {
    try {
      const hasCanvas = document.querySelectorAll('canvas').length > 0;
      let hasWebGL = false;
      if (hasCanvas) {
        const c = document.querySelector('canvas');
        hasWebGL = !!(c.getContext('webgl') || c.getContext('webgl2'));
      }

      const scripts = Array.from(document.querySelectorAll('script[src]'))
        .map(s => s.src.toLowerCase());
      const libraryChecks = { gsap: 'gsap', three: 'three', lottie: 'lottie', motion: 'framer-motion' };
      const detectedLibs = Object.entries(libraryChecks)
        .filter(([, kw]) => scripts.some(s => s.includes(kw)) ||
          (typeof window !== 'undefined' && window[Object.keys(libraryChecks).find(k => libraryChecks[k] === kw)]))
        .map(([name]) => name);

      const inlineScripts = Array.from(document.querySelectorAll('script:not([src])')).map(s => s.textContent);
      const ioCount = inlineScripts.join('').split('IntersectionObserver').length - 1;
      const scrollListeners = ioCount === 0 ? 'low' : ioCount < 5 ? 'medium' : 'high';

      result.extracted.effects = { hasCanvas, hasWebGL, libraries: detectedLibs, scrollListeners };
    } catch (e) {
      result.extracted.effects = null;
    }
  }

  return result;
};
