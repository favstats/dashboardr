const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('file:///Users/favstats/Dropbox/dashboardr/dashboardr/sidebar_single_echarts/docs/s2_pie_showwhen.html');
  await page.waitForTimeout(3000);

  const info = await page.evaluate(() => {
    const select = document.querySelector('select[data-filter-var="education"]');
    if (!select) return { found: false };
    const options = Array.from(select.options || []);
    const inputId = select.id || '';
    const choicesInst = inputId && window.dashboardrChoicesInstances && window.dashboardrChoicesInstances[inputId];
    const st = window.getComputedStyle(select);
    const isHidden = st.display === 'none' || st.visibility === 'hidden';
    const rect = select.getBoundingClientRect();
    return {
      found: true,
      id: select.id,
      tagName: select.tagName,
      optionsCount: options.length,
      optionValues: options.map(o => o.value),
      currentValue: select.value,
      isHidden: isHidden,
      display: st.display,
      visibility: st.visibility,
      width: rect.width,
      height: rect.height,
      hasChoicesInst: !!choicesInst,
      choicesType: choicesInst ? typeof choicesInst.setChoiceByValue : 'N/A',
      allChoicesKeys: Object.keys(window.dashboardrChoicesInstances || {}),
      parentClasses: select.parentElement ? select.parentElement.className : 'none',
      parentDisplay: select.parentElement ? window.getComputedStyle(select.parentElement).display : 'N/A'
    };
  });

  console.log(JSON.stringify(info, null, 2));
  await browser.close();
})();
