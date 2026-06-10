import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("/index.html");
  await page.click('.tab[data-go="tasks"]');
});

test("Today starts with 3 left (3 open, 1 done)", async ({ page }) => {
  await expect(page.locator("#left-count")).toHaveText("3 left");
  await expect(page.locator("#today-sec .task")).toHaveCount(4);
  await expect(page.locator("#today-sec .task.done")).toHaveCount(1);
});

test("tapping a task completes it and decrements the count", async ({ page }) => {
  const first = page.locator("#today-sec .task").first();
  await first.click();
  await expect(first).toHaveClass(/done/);
  await expect(page.locator("#left-count")).toHaveText("2 left");
  // tap again -> un-complete
  await first.click();
  await expect(first).not.toHaveClass(/done/);
  await expect(page.locator("#left-count")).toHaveText("3 left");
});

test("+ button adds a new task and increments the count", async ({ page }) => {
  await page.click(".fab");
  await expect(page.locator("#today-sec .task").first().locator("strong")).toHaveText("New task");
  await expect(page.locator("#left-count")).toHaveText("4 left");
  await expect(page.locator("#today-sec .task")).toHaveCount(5);
});

test("segmented control filters Today / Upcoming / Done", async ({ page }) => {
  // Today: upcoming section hidden
  await expect(page.locator("#up-sec")).toBeVisible();
  await page.click(".seg:has-text('Today')");
  await expect(page.locator("#up-sec")).toBeHidden();
  await expect(page.locator("#today-sec")).toBeVisible();
  // Upcoming: today hidden
  await page.click(".seg:has-text('Upcoming')");
  await expect(page.locator("#today-sec")).toBeHidden();
  await expect(page.locator("#up-sec")).toBeVisible();
  // Done: only completed tasks visible
  await page.click(".seg:has-text('Done')");
  await expect(page.locator("#today-sec .task:visible")).toHaveCount(1);
  await expect(page.locator("#today-sec .task:visible").first()).toHaveClass(/done/);
});
