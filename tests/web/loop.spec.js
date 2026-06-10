import { test, expect } from "@playwright/test";

// Suggestions look like normal reminder rows: title + one "+" — nothing else.
// The KG works invisibly: it decides WHAT appears, never decorates the page.
// Accepting persists a real item; items soft-delete and restore; every accept
// records a signal.

test.beforeEach(async ({ page }) => {
  await page.goto("/index.html");
});

test("Suggested rows render from the KG as plain rows", async ({ page }) => {
  const rows = page.locator("#resurface-list .sug");
  await expect(rows.first()).toBeVisible();
  expect(await rows.count()).toBeGreaterThanOrEqual(4);
  const miles = page.locator('.sug[data-rec="kg:MilesProtocol"]');
  await expect(miles).toContainText("Next dose");
  // no exposed reasoning anywhere
  await expect(page.locator("#resurface-list .why")).toHaveCount(0);
});

test("+ on a suggested task creates a persistent task", async ({ page }) => {
  await page.locator('.sug[data-rec="kg:TrustContract"] [data-act="add"]').click();
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator("#today-sec .task", { hasText: "Run ./qc.sh" })).toBeVisible();
  await page.reload();
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator("#today-sec .task", { hasText: "Run ./qc.sh" })).toBeVisible();
});

test("+ on a suggested reminder creates a persistent reminder", async ({ page }) => {
  await page.locator('.sug[data-rec="kg:OpenLoop_AskStephanie"] [data-act="add"]').click();
  await expect(page.locator("#latest-list .item", { hasText: "ask Stephanie first" })).toBeVisible();
  await page.reload();
  await expect(page.locator("#latest-list .item", { hasText: "ask Stephanie first" })).toBeVisible();
});

test("created items can be deleted and restored", async ({ page }) => {
  await page.locator('.sug[data-rec="kg:OpenLoop_SemanticWeb"] [data-act="add"]').click();
  await page.click('.tab[data-go="tasks"]');
  const created = page.locator("#today-sec .task", { hasText: "Commit or pivot" });
  await expect(created).toBeVisible();
  await created.locator("[data-del]").click();
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toHaveCount(0);
  const bin = page.locator("#deleted-sec");
  await expect(bin).toContainText("Commit or pivot");
  await bin.locator("[data-restore]").first().click();
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toBeVisible();
  await page.reload();
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toBeVisible();
});

test("accepting records a signal and the row leaves the deck", async ({ page }) => {
  await page.locator('.sug[data-rec="kg:MilesProtocol"] [data-act="add"]').click();
  const signals = await page.evaluate(() => JSON.parse(localStorage.getItem("recall.signals") || "[]"));
  expect(signals.some((s) => s.recId === "kg:MilesProtocol" && s.signalType === "accept")).toBe(true);
  await expect(page.locator('.sug[data-rec="kg:MilesProtocol"]')).toHaveCount(0);
});

test("FAB opens the composer; typing a title creates the right item per screen", async ({ page }) => {
  // Reminders screen -> New Reminder
  await page.click(".fab");
  await expect(page.locator("#composer")).toBeVisible();
  await expect(page.locator("#composer-title")).toHaveText("New Reminder");
  await page.fill("#composer-name", "Pick up dry cleaning");
  await page.click("#composer [data-add]");
  await expect(page.locator("#latest-list .item", { hasText: "Pick up dry cleaning" })).toBeVisible();
  // Calendar screen -> New Event, persists
  await page.click('.tab[data-go="calendar"]');
  await page.click(".fab");
  await expect(page.locator("#composer-title")).toHaveText("New Event");
  await page.fill("#composer-name", "Sauna with Miles");
  await page.click("#composer [data-add]");
  await expect(page.locator("#agenda-list .agenda", { hasText: "Sauna with Miles" })).toBeVisible();
  await page.reload();
  await page.click('.tab[data-go="calendar"]');
  await expect(page.locator("#agenda-list .agenda", { hasText: "Sauna with Miles" })).toBeVisible();
});

test("composer cancel adds nothing", async ({ page }) => {
  const before = await page.locator("#latest-list .item").count();
  await page.click(".fab");
  await page.click("#composer [data-cancel]");
  await expect(page.locator("#composer")).toBeHidden();
  await expect(page.locator("#latest-list .item")).toHaveCount(before);
});

test("hamburger opens the sidebar and navigates", async ({ page }) => {
  await page.locator('.scroll.active [data-menu]').click();
  await expect(page.locator("#drawer")).toBeVisible();
  await page.locator('#drawer [data-nav="calendar"]').click();
  await expect(page.locator(".scroll.active")).toHaveAttribute("data-screen", "calendar");
  await expect(page.locator("#drawer")).toBeHidden();
});
