import { defineConfig, devices } from "@playwright/test";
import os from "node:os";

// QC Layer 1 — behavior tests against the exact HTML the iOS app bundles.
// WebKit project: same engine as the WKWebView on the phone (CI + supported macOS).
// Firefox project: macOS 26 (Tahoe) fallback — Playwright WebKit/Chromium crash there today.
const iphone = devices["iPhone 14"];
const darwinMajor = parseInt(os.release().split(".")[0], 10);
const needsFirefoxFallback = os.platform() === "darwin" && darwinMajor >= 25;

const projects = needsFirefoxFallback
  ? [{ name: "firefox-iphone", use: { browserName: "firefox", headless: false, ...iphone } }]
  : [
      { name: "webkit-iphone", use: { browserName: "webkit", ...iphone } },
      { name: "chromium-iphone", use: { browserName: "chromium", ...iphone } }
    ];

export default defineConfig({
  testDir: "tests/web",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:5179",
    ...iphone,
  },
  projects,
  webServer: {
    command: "node scripts/stamp-web.mjs && python3 -m http.server 5179 --directory ios/ReCall/Web --bind 127.0.0.1",
    url: "http://127.0.0.1:5179/index.html",
    reuseExistingServer: true,
    timeout: 15000,
  },
});
