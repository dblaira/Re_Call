import { defineConfig, devices } from "@playwright/test";

// QC Layer 1 — behavior tests against the exact HTML the iOS app bundles.
// WebKit project: same engine as the WKWebView on the phone.
export default defineConfig({
  testDir: "tests/web",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:5179",
    ...devices["iPhone 14"],
  },
  projects: [{ name: "webkit-iphone", use: { browserName: "webkit", ...devices["iPhone 14"] } }],
  webServer: {
    command: "python3 -m http.server 5179 --directory ios/ReCall/Web --bind 127.0.0.1",
    url: "http://127.0.0.1:5179/index.html",
    reuseExistingServer: true,
    timeout: 15000,
  },
});
