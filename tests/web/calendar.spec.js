import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("/index.html");
  await page.click('.tab[data-go="calendar"]');
});

test("June grid renders with today on the 9th", async ({ page }) => {
  await expect(page.locator("#cal-grid .day")).toHaveCount(35);
  await expect(page.locator("#cal-grid .day.today .num")).toHaveText("9");
});

test("tapping a day moves the selection", async ({ page }) => {
  await page.locator("#cal-grid .day", { hasText: /^12$/ }).click();
  await expect(page.locator("#cal-grid .day.today .num")).toHaveText("12");
  await expect(page.locator("#cal-grid .day.today")).toHaveCount(1);
});

test("muted (other-month) days are not selectable", async ({ page }) => {
  await page.locator("#cal-grid .day.muted").first().click();
  await expect(page.locator("#cal-grid .day.today .num")).toHaveText("9");
});

test("agenda shows 4 events for today", async ({ page }) => {
  await expect(page.locator("#agenda-list .agenda")).toHaveCount(4);
});

test("+ button adds a new event to the agenda", async ({ page }) => {
  await page.click(".fab");
  await expect(page.locator("#agenda-list .agenda")).toHaveCount(5);
  await expect(page.locator("#agenda-list .agenda").first().locator("strong")).toHaveText("New event");
});
