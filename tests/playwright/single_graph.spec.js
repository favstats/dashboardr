const { test, expect } = require('@playwright/test');

test.describe('Sidebar with Single Graph', () => {
  test.beforeEach(async ({ page }) => {
    // The R script generates the dashboard in the root of the project.
    // We need to serve the files to be able to navigate to them.
    // The test assumes a web server is running on port 8080.
    // We can use `npx http-server` to start a simple server.
    await page.goto('http://localhost:8080/sidebar_single_echarts/S1_All_Inputs_Single_Bar.html');
  });

  test('should not have an empty div before the graph', async ({ page }) => {
    // The user reported an empty div before the graph.
    // The provided R script `dev/demo_sidebar_single_graph.R` adds a div with id `pw-single-graph-s1`
    // then a text with "### S1: All-input sidebar + single bar"
    // and then the visualization.
    // Let's check the structure of the generated HTML.

    // The visualization is rendered inside a div with class `col-sm-12 col-md-12 col-lg-12`.
    // Inside this div, there is another div with class `card`.
    // The title of the card is "Responses by region and education".
    // The graph is inside the `card-body`.
    const graphCard = page.locator('.card', { hasText: 'Responses by region and education' });

    // The problematic empty div would be a sibling of the graph card's parent.
    // The parent of the card is a div with class `col-sm-12 col-md-12 col-lg-12`.
    const graphContainer = graphCard.locator('..');

    // The container of the graph container is a div with class `row`.
    const rowContainer = graphContainer.locator('..');

    // The container of the row is a div with class `flex-grow-1 container-fluid`.
    const mainContainer = rowContainer.locator('..');

    // The user said there is an empty div. Let's look for an empty div inside the main container.
    const children = await mainContainer.locator('> div').all();

    let emptyDivCount = 0;
    for (const child of children) {
      const allText = await child.allTextContents();
      const innerHTML = await child.innerHTML();
      if (allText.join('').trim() === '' && innerHTML.trim() !== '' && (await child.locator('div, span, p').count() > 0)) {
        // It's not completely empty, but it might be a container with no visible content.
        const boundingBox = await child.boundingBox();
        if (boundingBox && boundingBox.height > 0) {
            emptyDivCount++;
        }
      } else if (innerHTML.trim() === '') {
        emptyDivCount++;
      }
    }

    // There should be some content, but not an empty div.
    expect(emptyDivCount).toBe(0);
  });
});
