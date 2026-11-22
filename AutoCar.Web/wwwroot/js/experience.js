'use strict';
(() => {
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  const header = document.querySelector('.site-header');
  const topButton = document.querySelector('.back-to-top');
  const hero = document.querySelector('.hero-premium');
  let scheduled = false;
  const updateScroll = () => {
    scheduled = false;
    const y = window.scrollY;
    const range = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
    document.documentElement.style.setProperty('--reading-progress', String(Math.min(1, y / range)));
    header?.classList.toggle('is-scrolled', y > 20);
    topButton?.classList.toggle('is-visible', y > 650);
    if (hero && !reduced.matches && window.innerWidth > 760 && y < hero.offsetHeight) {
      hero.style.setProperty('--hero-shift', Math.min(y * .055, 35) + 'px');
    }
  };
  window.addEventListener('scroll', () => {
    if (!scheduled) { scheduled = true; requestAnimationFrame(updateScroll); }
  }, { passive: true });
  window.addEventListener('resize', updateScroll, { passive: true });
  topButton?.addEventListener('click', () => window.scrollTo({ top: 0, behavior: reduced.matches ? 'instant' : 'smooth' }));
  updateScroll();

  // Content is visible without JS; only opt in after the observer is ready.
  if ('IntersectionObserver' in window && !reduced.matches) {
    const revealObserver = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          revealObserver.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px 35px 0px', threshold: .06 });
    document.documentElement.classList.add('motion-ready');
    const selector = '.section-top,.journey-intro>div,.car-card,.brand-tile,.segment-card,.journal-card,.experience-inner>div,.promotion-banner,.owner-empty,.stat-card,.welcome-panel,.revenue-highlight';
    const register = node => {
      if (!(node instanceof Element)) return;
      const targets = [...(node.matches(selector) ? [node] : []), ...node.querySelectorAll(selector)];
      targets.forEach(el => {
        if (el.classList.contains('reveal')) return;
        el.classList.add('reveal');
        const siblings = el.parentElement ? [...el.parentElement.children] : [];
        const stagger = Math.min(siblings.indexOf(el) % 4, 3) * 65;
        el.style.setProperty('--reveal-delay', stagger + 'ms');
        revealObserver.observe(el);
      });
    };
    register(document.body);
    new MutationObserver(records => records.forEach(record => record.addedNodes.forEach(register)))
      .observe(document.querySelector('main') || document.body, { childList: true, subtree: true });

    const countObserver = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        countObserver.unobserve(entry.target);
        const target = Number(entry.target.dataset.count);
        if (!Number.isFinite(target) || target <= 0) return;
        const start = performance.now();
        const tick = now => {
          const p = Math.min(1, (now - start) / 1050);
          entry.target.textContent = new Intl.NumberFormat('vi-VN').format(Math.round(target * (1 - Math.pow(1 - p, 3))));
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      });
    }, { threshold: .4 });
    document.querySelectorAll('[data-count]').forEach(el => countObserver.observe(el));
  }

  // Mobile menu closes after navigation or Escape and reports its actual state.
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && header?.classList.contains('menu-open')) {
      header.classList.remove('menu-open');
      document.querySelector('.mobile-toggle')?.setAttribute('aria-expanded', 'false');
    }
  });
  document.querySelectorAll('.main-nav a').forEach(a => a.addEventListener('click', () => {
    header?.classList.remove('menu-open');
    document.querySelector('.mobile-toggle')?.setAttribute('aria-expanded', 'false');
  }));

  // Show progress on real asynchronous form buttons, including admin dialogs.
  new MutationObserver(records => records.forEach(record => {
    const button = record.target;
    if (button instanceof HTMLButtonElement && button.classList.contains('btn')) {
      button.classList.toggle('is-submitting', button.disabled);
      button.setAttribute('aria-busy', String(button.disabled));
    }
  })).observe(document.body, { attributes: true, attributeFilter: ['disabled'], subtree: true });
})();
