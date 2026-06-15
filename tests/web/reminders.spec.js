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

test("FAB opens the full-page entry form with all four part groups and every control", async ({ page }) => {
  await page.click(".fab");
  await expect(page.locator("#composer.form-page")).toBeVisible();
  await expect(page.locator(".fgroup > h4")).toHaveText([
    "Core", "Date & Time", "Organization", "Places & People",
  ]);
  // every "part" control is present
  for (const id of [
    "composer-name", "composer-notes", "f-url", "f-image",
    "f-date", "f-time", "f-urgent", "f-repeat", "f-early",
    "f-list", "f-tag-input", "f-subadd", "f-flag", "f-priority",
    "f-location", "f-messaging",
  ]) {
    await expect(page.locator(`#${id}`)).toHaveCount(1);
  }
});

test("entry form captures every part and persists it onto the user's own item", async ({ page }) => {
  await page.click(".fab");
  await page.fill("#composer-name", "Renew passport");
  await page.fill("#composer-notes", "Bring 2x2 photos");
  await page.fill("#f-url", "https://travel.state.gov");
  await page.fill("#f-date", "2026-07-20");
  await page.fill("#f-time", "09:30");
  await page.locator("#f-urgent").check();
  await page.selectOption("#f-repeat", "yearly");
  await page.selectOption("#f-early", "1d");
  await page.selectOption("#f-list", "Personal");
  await page.selectOption("#f-priority", "high");
  await page.locator("#f-flag").check();
  await page.fill("#f-location", "Post Office");
  await page.fill("#f-messaging", "Stephanie");
  // tag
  await page.fill("#f-tag-input", "travel");
  await page.press("#f-tag-input", "Enter");
  await expect(page.locator("#f-tags .chip")).toHaveCount(1);
  // subtask
  await page.click("#f-subadd");
  await page.fill("#f-subtasks .subrow input", "Find old passport");

  await page.click("#composer [data-add]");

  // the new row reflects the key parts
  const row = page.locator("#latest-list .item").first();
  await expect(row.locator("strong")).toHaveText("Renew passport");
  await expect(row.locator("[data-flag]")).toHaveCount(1);
  await expect(row.locator("[data-prio]")).toHaveText("!!!");
  await expect(row.locator("[data-when]")).toContainText("Jul 20");

  // the data lives in the user's own store
  const it = await page.evaluate(() => {
    const all = JSON.parse(localStorage.getItem("recall.items"));
    return all[all.length - 1];
  });
  expect(it).toMatchObject({
    type: "reminder",
    title: "Renew passport",
    notes: "Bring 2x2 photos",
    url: "https://travel.state.gov",
    date: "2026-07-20",
    time: "09:30",
    urgent: true,
    repeat: "yearly",
    earlyReminder: "1d",
    list: "Personal",
    priority: "high",
    flag: true,
    location: "Post Office",
    whenMessaging: "Stephanie",
  });
  expect(it.tags).toEqual(["travel"]);
  expect(it.subtasks).toEqual([{ title: "Find old passport", done: false }]);
});

test("tags add and remove inside the form", async ({ page }) => {
  await page.click(".fab");
  await page.fill("#f-tag-input", "home");
  await page.press("#f-tag-input", "Enter");
  await page.fill("#f-tag-input", "urgent");
  await page.press("#f-tag-input", "Enter");
  await expect(page.locator("#f-tags .chip")).toHaveCount(2);
  await page.locator("#f-tags .chip [data-tagdel]").first().click();
  await expect(page.locator("#f-tags .chip")).toHaveCount(1);
  await expect(page.locator("#f-tags .chip")).toContainText("urgent");
});

test("attaching an image stores it on the item as a data URL and shows a thumbnail", async ({ page }) => {
  await page.click(".fab");
  await page.fill("#composer-name", "Receipt to file");
  const png = Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgAAIAAAUAAen63NgAAAAASUVORK5CYII=",
    "base64",
  );
  await page.setInputFiles("#f-image", { name: "receipt.png", mimeType: "image/png", buffer: png });
  await expect(page.locator("#f-image-thumb")).toBeVisible();
  await page.click("#composer [data-add]");
  await expect(page.locator("#latest-list .item").first().locator("img.row-thumb")).toHaveCount(1);
  const image = await page.evaluate(() => {
    const all = JSON.parse(localStorage.getItem("recall.items"));
    return all[all.length - 1].image;
  });
  expect(image).toMatch(/^data:image\/png;base64,/);
});

test("cancelling the full-page form discards everything", async ({ page }) => {
  await page.click(".fab");
  await page.fill("#composer-name", "Should not be saved");
  await page.fill("#f-location", "Nowhere");
  await page.click("#composer [data-cancel]");
  await expect(page.locator("#composer")).toBeHidden();
  await expect(page.locator("#latest-list .item")).toHaveCount(2);
  // reopening starts clean
  await page.click(".fab");
  await expect(page.locator("#composer-name")).toHaveValue("");
  await expect(page.locator("#f-location")).toHaveValue("");
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
