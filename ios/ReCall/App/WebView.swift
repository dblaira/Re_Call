import SwiftUI
import UserNotifications
import WebKit

/// Hosts the bundled Re_Call prototype full-screen, edge-to-edge, with no Safari
/// chrome. The HTML and its relative `covers/*.png` assets ship inside the app
/// bundle (folder reference `Web/`) and load entirely offline.
struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow the prototype's inline media to play without forcing fullscreen.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "recallReminders")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        // The prototype is a single mobile screen; kill the rubber-band bounce so
        // it reads like a native app rather than a scrollable web page.
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = webView

        loadBundledPrototype(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = uiView
    }

    private func loadBundledPrototype(into webView: WKWebView) {
        // `Web` is bundled as a folder reference, so index.html and covers/ keep
        // their relative layout. Read access is granted to the whole Web dir so
        // the relative cover images resolve.
        guard let webDir = Bundle.main.url(forResource: "Web", withExtension: nil) else {
            assertionFailure("Bundled Web/ directory missing from app target")
            return
        }
        let indexURL = webDir.appendingPathComponent("index.html")
        webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let savedReminderScheduleKey = "recall.savedReminderSchedule"
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "recallReminders",
                  let payload = message.body as? [String: Any],
                  let action = payload["action"] as? String else { return }

            if action == "list" {
                sendPendingReminders()
                return
            }

            guard action == "schedule",
                  let title = payload["title"] as? String,
                  let body = payload["body"] as? String,
                  let times = payload["times"] as? [String] else { return }

            scheduleTodayReminders(title: title, body: body, times: times)
        }

        private func scheduleTodayReminders(title: String, body: String, times: [String]) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                guard granted, error == nil else {
                    self.sendReminderResult(success: false, count: 0)
                    return
                }

                center.removePendingNotificationRequests(withIdentifiers: times.map { "recall.awake.\($0)" })
                if self.isStaleDefaultReminder(title: title, body: body) {
                    self.clearSavedReminderSchedule()
                    self.sendReminderResult(success: true, count: 0)
                    return
                }

                self.saveReminderSchedule(title: title, body: body, times: times)

                let calendar = Calendar.current
                let now = Date()
                var scheduled = 0

                for time in times {
                    let parts = time.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2,
                          let fireDate = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: now),
                          fireDate > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default

                    let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: "recall.awake.\(time)", content: content, trigger: trigger)

                    center.add(request)
                    scheduled += 1
                }

                self.sendReminderResult(success: true, count: scheduled)
            }
        }

        private func sendReminderResult(success: Bool, count: Int) {
            DispatchQueue.main.async {
                let script = "window.recallReminderNativeResult && window.recallReminderNativeResult({ success: \(success), count: \(count) });"
                self.webView?.evaluateJavaScript(script)
            }
        }

        private func sendPendingReminders() {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let recallRequests = requests.filter { $0.identifier.hasPrefix("recall.awake.") }
                let staleRequestIds = recallRequests
                    .filter { self.isStaleDefaultReminder(title: $0.content.title, body: $0.content.body) }
                    .map(\.identifier)

                if !staleRequestIds.isEmpty {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: staleRequestIds)
                }

                var pending = recallRequests
                    .filter { !self.isStaleDefaultReminder(title: $0.content.title, body: $0.content.body) }
                    .compactMap { request -> [String: String]? in
                        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                              let hour = trigger.dateComponents.hour,
                              let minute = trigger.dateComponents.minute else { return nil }

                        return [
                            "time": String(format: "%02d:%02d", hour, minute),
                            "title": request.content.title,
                            "body": request.content.body
                        ]
                    }
                    .sorted { ($0["time"] ?? "") < ($1["time"] ?? "") }

                if pending.isEmpty {
                    pending = self.savedReminderSchedule()
                }

                guard let data = try? JSONSerialization.data(withJSONObject: pending),
                      let json = String(data: data, encoding: .utf8) else { return }

                DispatchQueue.main.async {
                    let script = "window.recallReminderNativeResult && window.recallReminderNativeResult({ success: true, pending: \(json) });"
                    self.webView?.evaluateJavaScript(script)
                }
            }
        }

        private func saveReminderSchedule(title: String, body: String, times: [String]) {
            guard !isStaleDefaultReminder(title: title, body: body) else {
                clearSavedReminderSchedule()
                return
            }

            let payload = times.map { time in
                [
                    "time": time,
                    "title": title,
                    "body": body
                ]
            }
            UserDefaults.standard.set(payload, forKey: savedReminderScheduleKey)
        }

        private func savedReminderSchedule() -> [[String: String]] {
            let saved = UserDefaults.standard.array(forKey: savedReminderScheduleKey) as? [[String: String]] ?? []
            let filtered = saved.filter {
                !isStaleDefaultReminder(title: $0["title"] ?? "", body: $0["body"] ?? "")
            }
            if filtered.count != saved.count {
                UserDefaults.standard.set(filtered, forKey: savedReminderScheduleKey)
            }
            return filtered
        }

        private func clearSavedReminderSchedule() {
            UserDefaults.standard.removeObject(forKey: savedReminderScheduleKey)
        }

        private func isStaleDefaultReminder(title: String, body: String) -> Bool {
            let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedBody = body.lowercased()

            return normalizedTitle == "re_call"
                || normalizedBody.contains("50 grams of protein")
                || normalizedBody.contains("50 g")
                || normalizedBody.contains("every 4 hours")
                || normalizedBody.contains("every four hours")
                || normalizedBody.contains("pause, check what is still alive")
        }
    }
}
