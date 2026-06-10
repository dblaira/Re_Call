import { test, expect } from "@playwright/test";

// The capture→infer loop: KG-derived recommendations render with their
// graph provenance, one tap turns them into real items, items persist,
// delete/restore works, and every choice records a signal.

test.beforeEach(async ({ page }) => {
  await page.goto("/index.html");
});

test("Resurface cards render from the KG with why-chains", async ({ page }) => {
  const cards = page.locator("#resurface-list .rec");
  await expect(cards.first()).toBeVisible();
  expect(await cards.count()).toBeGreaterThanOrEqual(4);
  // the Miles' protocol card carries its actual graph path as provenance
  const miles = page.locator('.rec[data-rec="kg:MilesProtocol"]');
  await expect(miles).toContainText("Next dose");
  await expect(miles.locator(".why")).toContainText("conflicts with");
  await expect(miles.locator(".why")).toContainText("Miles' dosing protocol");
});

test("accepting a card as Task creates a persistent task", async ({ page }) => {
  await page.locator('.rec[data-rec="kg:TrustContract"] [data-act="task"]').click();
  await page.click('.tab[data-go="tasks"]');
  const created = page.locator("#today-sec .task", { hasText: "Run ./qc.sh" });
  await expect(created).toBeVisible();
  // survives a cold reload (localStorage)
  await page.reload();
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator("#today-sec .task", { hasText: "Run ./qc.sh" })).toBeVisible();
});

test("accepting a card as Reminder creates a persistent reminder", async ({ page }) => {
  await page.locator('.rec[data-rec="kg:OpenLoop_AskStephanie"] [data-act="reminder"]').click();
  const item = page.locator("#latest-list .item", { hasText: "ask Stephanie first" });
  await expect(item).toBeVisible();
  await page.reload();
  await expect(page.locator("#latest-list .item", { hasText: "ask Stephanie first" })).toBeVisible();
});

test("accepting a card as Event creates a persistent calendar event", async ({ page }) => {
  await page.locator('.rec[data-rec="kg:Pattern_CaptureAntidote"] [data-act="event"]').click();
  await page.click('.tab[data-go="calendar"]');
  const ev = page.locator("#agenda-list .agenda", { hasText: "Capture today's friction" });
  await expect(ev).toBeVisible();
  await page.reload();
  await page.click('.tab[data-go="calendar"]');
  await expect(page.locator("#agenda-list .agenda", { hasText: "Capture today's friction" })).toBeVisible();
});

test("created items can be deleted and restored", async ({ page }) => {
  await page.locator('.rec[data-rec="kg:OpenLoop_SemanticWeb"] [data-act="task"]').click();
  await page.click('.tab[data-go="tasks"]');
  const created = page.locator("#today-sec .task", { hasText: "Commit or pivot" });
  await expect(created).toBeVisible();
  // delete -> leaves the list, appears in Recently deleted
  await created.locator("[data-del]").click();
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toHaveCount(0);
  const bin = page.locator("#deleted-sec");
  await expect(bin).toContainText("Commit or pivot");
  // restore -> back in the list, bin empties; survives reload
  await bin.locator("[data-restore]").first().click();
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toBeVisible();
  await page.reload();
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator("#today-sec .task", { hasText: "Commit or pivot" })).toBeVisible();
});

test("dismissing a card hides it permanently and records the signal", async ({ page }) => {
  const card = page.locator('.rec[data-rec="kg:Pattern_AmbitionAvoidance"]');
  await expect(card).toBeVisible();
  await card.locator('[data-act="dismiss"]').click();
  await expect(card).toHaveCount(0);
  await page.reload();
  await expect(page.locator('.rec[data-rec="kg:Pattern_AmbitionAvoidance"]')).toHaveCount(0);
  const signals = await page.evaluate(() => JSON.parse(localStorage.getItem("recall.signals") || "[]"));
  expect(signals.some((s) => s.recId === "kg:Pattern_AmbitionAvoidance" && s.signalType === "dismiss")).toBe(true);
});

test("accepting records an accept signal that feeds the KG loop", async ({ page }) => {
  await page.locator('.rec[data-rec="kg:MilesProtocol"] [data-act="reminder"]').click();
  const signals = await page.evaluate(() => JSON.parse(localStorage.getItem("recall.signals") || "[]"));
  expect(signals.some((s) => s.recId === "kg:MilesProtocol" && s.signalType === "accept")).toBe(true);
  // accepted card leaves the deck (it became a real item)
  await expect(page.locator('.rec[data-rec="kg:MilesProtocol"]')).toHaveCount(0);
});
