import { test, expect } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.goto("/index.html");
  // app opens on Reminders
});

test("opens on Reminders with 2 latest reminders", async ({ page }) => {
  await expect(page.locator(".scroll.active")).toHaveAttribute("data-screen", "reminders");
  await expect(page.locator("#latest-list .item")).toHaveCount(2);
});

test("tapping a tile selects it and shows its name in the toast", async ({ page }) => {
  const tile = page.locator(".tile", { hasText: "Pay before due" });
  await tile.click();
  await expect(tile).toHaveAttribute("data-selected", "true");
  await expect(page.locator("#toast")).toHaveText("Pay before due");
  // selecting another moves the outline
  const other = page.locator(".tile", { hasText: "Text them back" });
  await other.click();
  await expect(other).toHaveAttribute("data-selected", "true");
  await expect(tile).toHaveAttribute("data-selected", "false");
});

test("+ button opens the composer and adds a reminder", async ({ page }) => {
  await page.click(".fab");
  await expect(page.locator("#composer-title")).toHaveText("New Reminder");
  await page.fill("#composer-name", "Water the plants");
  await page.click("#composer [data-add]");
  await expect(page.locator("#latest-list .item")).toHaveCount(3);
  await expect(page.locator("#latest-list .item").first().locator("strong")).toHaveText("Water the plants");
});

test("tab bar navigates between all three screens", async ({ page }) => {
  await page.click('.tab[data-go="tasks"]');
  await expect(page.locator(".scroll.active")).toHaveAttribute("data-screen", "tasks");
  await page.click('.tab[data-go="calendar"]');
  await expect(page.locator(".scroll.active")).toHaveAttribute("data-screen", "calendar");
  await page.click('.tab[data-go="reminders"]');
  await expect(page.locator(".scroll.active")).toHaveAttribute("data-screen", "reminders");
});

test("build fingerprint element is present", async ({ page }) => {
  await expect(page.locator("#build-info")).toHaveCount(1);
  const md5 = await page.locator("#build-info").getAttribute("data-src-md5");
  expect(md5).toBeTruthy();
});

test("template tile → composer prefilled → edit → reminder created + deeper card surfaces", async ({ page }) => {
  await page.locator('.tile[data-template="HabitStackGymReminder"]').click();
  await expect(page.locator("#composer-title")).toHaveText("Habit stack at the gym");
  const name = page.locator("#composer-name");
  await expect(name).toHaveValue(/foam roll/i);
  // edit until owned — the strongest signal (+0.30)
  await name.fill("After hoops: foam roll lower body, 2 minutes");
  await page.click("#composer [data-add]");
  await expect(page.locator("#toast")).toHaveText("Owned — deeper unlocked");
  await expect(page.locator("#latest-list .item").first().locator("strong")).toHaveText("After hoops: foam roll lower body, 2 minutes");
  // the edit signal lifts HabitStacking affinity → the deeper card enters Suggested
  await expect(page.locator("#resurface-list")).toContainText("Run a readiness bet");
});

test("post-run body discovery tile exposes the 20-option scan field", async ({ page }) => {
  await expect(page.locator('.tile[data-template="PostRunBodyDiscoveryReminder"]')).toContainText("Post-run body discovery");

  const bundleCheck = await page.evaluate(() => {
    const recs = window.RECALL_RECS.depth.filter((card) =>
      card.why.some((line) => line.includes("PostRunBodyDiscoveryReminder"))
    );
    return {
      count: recs.length,
      hasLowHigh: recs.some((card) => /low-to-high/i.test(card.title)),
      hasTwenty: recs.some((card) => /twenty movement hypotheses/i.test(card.title)),
      frame: recs[0]?.generationFrame?.id
    };
  });

  expect(bundleCheck).toEqual({
    count: 20,
    hasLowHigh: true,
    hasTwenty: true,
    frame: "FeltDiscoveryScanFrame"
  });
});
