import SwiftUI
import AVFAudio
import UserNotifications
import WebKit

/// Hosts the bundled Re_Call prototype full-screen, edge-to-edge, with no Safari
/// chrome. The HTML and its relative `covers/*.png` assets ship inside the app
/// bundle (folder reference `Web/`) and load entirely offline.
struct WebView: UIViewRepresentable {
    @ObservedObject var nativeCaptureBridge: NativeCaptureBridge

    func makeCoordinator() -> Coordinator {
        Coordinator(nativeCaptureBridge: nativeCaptureBridge)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow the prototype's inline media to play without forcing fullscreen.
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "recallReminders")
        config.userContentController.add(context.coordinator, name: "recallVoice")
        config.userContentController.add(context.coordinator, name: "recallDebug")
        config.userContentController.add(context.coordinator, name: "recallNativeUI")

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
        private let iso8601 = ISO8601DateFormatter()
        private var recorder: AVAudioRecorder?
        private var activeVoiceMemoID: String?
        private var simulatedVoiceCaptureStartedAt: Date?
        private let nativeCaptureBridge: NativeCaptureBridge
        weak var webView: WKWebView?

        init(nativeCaptureBridge: NativeCaptureBridge) {
            self.nativeCaptureBridge = nativeCaptureBridge
            super.init()
            nativeCaptureBridge.onSave = { [weak self] payload in
                self?.handleNativeCaptureSave(payload)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "recallVoice" {
                guard let payload = message.body as? [String: Any],
                      let action = payload["action"] as? String else { return }

                if action == "start" {
                    startVoiceCapture()
                } else if action == "stop" {
                    stopVoiceCapture()
                }
                return
            }

            if message.name == "recallDebug" {
                guard let payload = message.body as? [String: Any] else { return }
                debugLog(payload)
                return
            }

            if message.name == "recallNativeUI" {
                guard let payload = message.body as? [String: Any],
                      let action = payload["action"] as? String else { return }

                if action == "openMacBookCapture" {
                    let seedTitle = (payload["seedTitle"] as? String) ?? "Catch the new machine while it still feels vivid."
                    DispatchQueue.main.async {
                        self.nativeCaptureBridge.presentMacBookCapture(seedTitle: seedTitle)
                    }
                }
                return
            }

            guard message.name == "recallReminders",
                  let payload = message.body as? [String: Any],
                  let action = payload["action"] as? String else { return }

            if action == "list" {
                sendPendingReminders()
                return
            }

            if action == "scheduleSeries",
               let title = payload["title"] as? String,
               let body = payload["body"] as? String,
               let entries = payload["entries"] as? [[String: String]] {
                scheduleReminderSeries(title: title, body: body, entries: entries)
                return
            }

            guard action == "schedule",
                  let title = payload["title"] as? String,
                  let body = payload["body"] as? String,
                  let times = payload["times"] as? [String] else { return }

            scheduleTodayReminders(title: title, body: body, times: times)
        }

        private func scheduleTodayReminders(title: String, body: String, times: [String]) {
            #if targetEnvironment(simulator)
                let now = Date()
                let calendar = Calendar.current
                let scheduled = times.filter { time in
                    let parts = time.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2,
                          let fireDate = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: now) else {
                        return false
                    }
                    return fireDate > now
                }.count

                if isStaleDefaultReminder(title: title, body: body) {
                    clearSavedReminderSchedule()
                    sendReminderResult(success: true, count: 0)
                    return
                }

                saveReminderSchedule(title: title, body: body, times: times)
                sendReminderResult(success: true, count: scheduled)
                return
            #endif

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

        private func scheduleReminderSeries(title: String, body: String, entries: [[String: String]]) {
            #if targetEnvironment(simulator)
                if isStaleDefaultReminder(title: title, body: body) {
                    clearSavedReminderSchedule()
                    sendReminderResult(success: true, count: 0)
                    return
                }

                let now = Date()
                let scheduled = entries.filter { entry in
                    guard let fireDate = fireDate(for: entry) else { return false }
                    return fireDate > now
                }.count

                saveReminderSchedule(entries: entries, title: title, body: body)
                sendReminderResult(success: true, count: scheduled)
                return
            #endif

            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                guard granted, error == nil else {
                    self.sendReminderResult(success: false, count: 0)
                    return
                }

                if self.isStaleDefaultReminder(title: title, body: body) {
                    self.removeSavedReminderScheduleRequests()
                    self.clearSavedReminderSchedule()
                    self.sendReminderResult(success: true, count: 0)
                    return
                }

                self.removeSavedReminderScheduleRequests()
                self.saveReminderSchedule(entries: entries, title: title, body: body)

                let now = Date()
                var scheduled = 0

                for entry in entries {
                    guard let fireDate = self.fireDate(for: entry), fireDate > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default

                    let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(
                        identifier: self.reminderIdentifier(for: entry),
                        content: content,
                        trigger: trigger
                    )

                    center.add(request)
                    scheduled += 1
                }

                self.sendReminderResult(success: true, count: scheduled)
            }
        }

        private func startVoiceCapture() {
            #if targetEnvironment(simulator)
                let memoID = "memo-\(UUID().uuidString)"
                activeVoiceMemoID = memoID
                simulatedVoiceCaptureStartedAt = Date()
                sendVoiceResult([
                    "success": true,
                    "state": "recording"
                ])
                return
            #endif

            AVAudioApplication.requestRecordPermission { granted in
                guard granted else {
                    self.sendVoiceResult(["success": false])
                    return
                }

                DispatchQueue.main.async {
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
                        try session.setActive(true, options: [])

                        let memoID = "memo-\(UUID().uuidString)"
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(memoID).m4a")
                        let settings: [String: Any] = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 44_100,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]

                        let recorder = try AVAudioRecorder(url: url, settings: settings)
                        recorder.prepareToRecord()
                        recorder.record()

                        self.recorder = recorder
                        self.activeVoiceMemoID = memoID
                        self.sendVoiceResult([
                            "success": true,
                            "state": "recording"
                        ])
                    } catch {
                        self.sendVoiceResult(["success": false])
                    }
                }
            }
        }

        private func stopVoiceCapture() {
            DispatchQueue.main.async {
                #if targetEnvironment(simulator)
                    if let startedAt = self.simulatedVoiceCaptureStartedAt {
                        let simulatedDuration = max(1, Int(Date().timeIntervalSince(startedAt).rounded()))
                        let simulatedMemoID = self.activeVoiceMemoID ?? "memo-\(UUID().uuidString)"
                        self.simulatedVoiceCaptureStartedAt = nil
                        self.activeVoiceMemoID = nil

                        self.sendVoiceResult([
                            "success": true,
                            "state": "recorded",
                            "memo": [
                                "id": simulatedMemoID,
                                "durationSeconds": simulatedDuration,
                                "createdAt": self.iso8601.string(from: Date())
                            ]
                        ])
                        return
                    }
                #endif

                guard let recorder = self.recorder else {
                    self.sendVoiceResult(["success": false])
                    return
                }

                recorder.stop()
                let duration = max(1, Int(recorder.currentTime.rounded()))
                let memoID = self.activeVoiceMemoID ?? "memo-\(UUID().uuidString)"

                self.recorder = nil
                self.activeVoiceMemoID = nil
                try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

                self.sendVoiceResult([
                    "success": true,
                    "state": "recorded",
                    "memo": [
                        "id": memoID,
                        "durationSeconds": duration,
                        "createdAt": self.iso8601.string(from: Date())
                    ]
                ])
            }
        }

        private func sendReminderResult(success: Bool, count: Int) {
            DispatchQueue.main.async {
                let script = "window.recallReminderNativeResult && window.recallReminderNativeResult({ success: \(success), count: \(count) });"
                self.webView?.evaluateJavaScript(script)
            }
        }

        private func handleNativeCaptureSave(_ payload: NativeCaptureSavePayload) {
            var fields: [String] = [
                "title: \(jsonStringLiteral(payload.title))"
            ]

            if let voiceMemo = payload.voiceMemo,
               let data = try? JSONEncoder().encode(voiceMemo),
               let json = String(data: data, encoding: .utf8) {
                fields.append("voiceMemo: \(json)")
            } else {
                fields.append("voiceMemo: null")
            }

            if let scheduledCount = payload.scheduledCount {
                fields.append("scheduledCount: \(scheduledCount)")
            } else {
                fields.append("scheduledCount: null")
            }

            let script = """
            window.recallNativeCaptureSaved && window.recallNativeCaptureSaved({ \(fields.joined(separator: ", ")) });
            """

            DispatchQueue.main.async {
                self.webView?.evaluateJavaScript(script)
            }
        }

        private func jsonStringLiteral(_ value: String) -> String {
            let data = try? JSONSerialization.data(withJSONObject: [value])
            let json = String(data: data ?? Data("[]".utf8), encoding: .utf8) ?? "[\"\"]"
            return String(json.dropFirst().dropLast())
        }

        private func debugLog(_ payload: [String: Any]) {
            guard JSONSerialization.isValidJSONObject(payload),
                  let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
                  let json = String(data: data, encoding: .utf8) else {
                print("RECALL_DEBUG invalid payload")
                return
            }

            print("RECALL_DEBUG \(json)")
        }

        private func sendVoiceResult(_ payload: [String: Any]) {
            sendJavaScriptCallback(named: "recallVoiceNativeResult", payload: payload)
        }

        private func sendJavaScriptCallback(named name: String, payload: [String: Any]) {
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else { return }

            DispatchQueue.main.async {
                let script = "window.\(name) && window.\(name)(\(json));"
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

        private func saveReminderSchedule(entries: [[String: String]], title: String, body: String) {
            guard !isStaleDefaultReminder(title: title, body: body) else {
                clearSavedReminderSchedule()
                return
            }

            let payload = entries.map { entry in
                [
                    "date": entry["date"] ?? "",
                    "time": entry["time"] ?? "",
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

        private func removeSavedReminderScheduleRequests() {
            let identifiers = savedReminderSchedule().map(reminderIdentifier(for:))
            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
        }

        private func reminderIdentifier(for entry: [String: String]) -> String {
            let date = entry["date"] ?? "today"
            let time = (entry["time"] ?? "00:00").replacingOccurrences(of: ":", with: "-")
            return "recall.capture.\(date).\(time)"
        }

        private func fireDate(for entry: [String: String]) -> Date? {
            guard let date = entry["date"], let time = entry["time"] else { return nil }
            let formatter = DateFormatter()
            formatter.calendar = Calendar.current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.date(from: "\(date) \(time)")
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
