import SwiftUI
import AVFAudio
import UserNotifications

struct NativeCaptureSavePayload {
    let title: String
    let voiceMemo: VoiceMemoPayload?
    let scheduledCount: Int?
}

struct VoiceMemoPayload: Codable {
    let id: String
    let durationSeconds: Int
    let createdAt: String
}

@MainActor
final class NativeCaptureBridge: ObservableObject {
    @Published var isPresentingMacBookCapture = false
    @Published var seedTitle = "Catch the new machine while it still feels vivid."

    var onSave: ((NativeCaptureSavePayload) -> Void)?

    func presentMacBookCapture(seedTitle: String) {
        self.seedTitle = seedTitle
        isPresentingMacBookCapture = true
    }
}

@MainActor
final class NativeCaptureComposerModel: ObservableObject {
    @Published var title: String
    @Published var scheduleEnabled = true
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var voiceState: VoiceCaptureState = .idle
    @Published var voiceMemo: VoiceMemoPayload?

    private let scheduler = NativeCaptureScheduler()
    private let voiceRecorder = NativeVoiceRecorder()

    init(seedTitle: String) {
        title = seedTitle
    }

    var voiceButtonTitle: String {
        voiceState == .recording ? "Stop recording" : "Record voice memo"
    }

    var voiceStatusText: String {
        switch voiceState {
        case .idle:
            return voiceMemo.map { "Voice memo captured · \($0.durationSeconds)s" } ?? "No voice memo yet."
        case .recording:
            return "Recording now… speak the unlock, friction, or surprise."
        }
    }

    func toggleVoiceCapture() async {
        errorMessage = nil

        do {
            if voiceState == .recording {
                voiceMemo = try await voiceRecorder.stop()
                voiceState = .idle
            } else {
                try await voiceRecorder.start()
                voiceState = .recording
            }
        } catch {
            voiceState = .idle
            errorMessage = "Voice capture needs microphone access."
        }
    }

    func save() async throws -> NativeCaptureSavePayload {
        if voiceState == .recording {
            throw NativeCaptureError.stopRecordingFirst
        }

        isSaving = true
        defer { isSaving = false }

        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = normalizedTitle.isEmpty ? "Catch the new machine while it still feels vivid." : normalizedTitle
        let scheduledCount = scheduleEnabled ? try await scheduler.scheduleMacBookCapture(body: finalTitle) : nil
        return NativeCaptureSavePayload(title: finalTitle, voiceMemo: voiceMemo, scheduledCount: scheduledCount)
    }
}

enum VoiceCaptureState {
    case idle
    case recording
}

enum NativeCaptureError: LocalizedError {
    case microphoneDenied
    case stopRecordingFirst
    case notificationsDenied
    case recorderUnavailable

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Voice capture needs microphone access."
        case .stopRecordingFirst:
            return "Stop the voice memo first."
        case .notificationsDenied:
            return "Capture cadence needs notification access."
        case .recorderUnavailable:
            return "Voice capture recorder is unavailable."
        }
    }
}

private final class NativeVoiceRecorder {
    private let iso8601 = ISO8601DateFormatter()
    private var recorder: AVAudioRecorder?
    private var activeVoiceMemoID: String?
    private var simulatedVoiceCaptureStartedAt: Date?

    func start() async throws {
        #if targetEnvironment(simulator)
        activeVoiceMemoID = "memo-\(UUID().uuidString)"
        simulatedVoiceCaptureStartedAt = Date()
        #else
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }

        guard granted else { throw NativeCaptureError.microphoneDenied }

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
        activeVoiceMemoID = memoID
        #endif
    }

    func stop() async throws -> VoiceMemoPayload {
        #if targetEnvironment(simulator)
            if let startedAt = simulatedVoiceCaptureStartedAt {
                let duration = max(1, Int(Date().timeIntervalSince(startedAt).rounded()))
                simulatedVoiceCaptureStartedAt = nil
                let memoID = activeVoiceMemoID ?? "memo-\(UUID().uuidString)"
                activeVoiceMemoID = nil
                return VoiceMemoPayload(
                    id: memoID,
                    durationSeconds: duration,
                    createdAt: iso8601.string(from: Date())
                )
            }
        #endif

        guard let recorder else { throw NativeCaptureError.recorderUnavailable }

        recorder.stop()
        let duration = max(1, Int(recorder.currentTime.rounded()))
        let memoID = activeVoiceMemoID ?? "memo-\(UUID().uuidString)"

        self.recorder = nil
        activeVoiceMemoID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

        return VoiceMemoPayload(
            id: memoID,
            durationSeconds: duration,
            createdAt: iso8601.string(from: Date())
        )
    }
}

private final class NativeCaptureScheduler {
    private let savedReminderScheduleKey = "recall.savedReminderSchedule"

    func scheduleMacBookCapture(body: String) async throws -> Int {
        let entries = buildMacBookCaptureEntries()

        #if targetEnvironment(simulator)
        saveReminderSchedule(entries: entries, title: "MacBook unlock capture", body: body)
        return entries.count
        #else
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { throw NativeCaptureError.notificationsDenied }

        removeSavedReminderScheduleRequests()
        saveReminderSchedule(entries: entries, title: "MacBook unlock capture", body: body)

        let now = Date()
        var scheduled = 0
        for entry in entries {
            guard let fireDate = fireDate(for: entry), fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "MacBook unlock capture"
            content.body = body
            content.sound = .default

            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminderIdentifier(for: entry),
                content: content,
                trigger: trigger
            )

            try await center.add(request)
            scheduled += 1
        }

        return scheduled
        #endif
    }

    private func buildMacBookCaptureEntries(now: Date = Date()) -> [[String: String]] {
        let times = ["09:00", "12:30", "16:00", "19:30"]
        let start = Calendar.current.date(bySetting: .second, value: 0, of: now) ?? now
        var entries: [[String: String]] = []

        for dayOffset in 0..<8 where entries.count < 16 {
            guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            let date = isoLocalDate(day)

            for time in times {
                let parts = time.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2 else { continue }
                guard let fireAt = Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day) else { continue }
                if fireAt <= now { continue }

                entries.append(["date": date, "time": time])
                if entries.count == 16 { break }
            }
        }

        return entries
    }

    private func isoLocalDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func saveReminderSchedule(entries: [[String: String]], title: String, body: String) {
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
        UserDefaults.standard.array(forKey: savedReminderScheduleKey) as? [[String: String]] ?? []
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
}

struct NativeCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: NativeCaptureComposerModel
    let onSave: (NativeCaptureSavePayload) -> Void

    private let shellBlack = Color(red: 0.10, green: 0.10, blue: 0.11)
    private let panelGrey = Color(red: 0.18, green: 0.18, blue: 0.20)
    private let lineGrey = Color.white.opacity(0.10)
    private let textGrey = Color(red: 0.63, green: 0.63, blue: 0.68)
    private let paperWhite = Color.white
    private let accentRed = Color(red: 0.86, green: 0.08, blue: 0.24)
    private let accentBrown = Color(red: 0.82, green: 0.66, blue: 0.19)

    init(seedTitle: String, onSave: @escaping (NativeCaptureSavePayload) -> Void) {
        _model = StateObject(wrappedValue: NativeCaptureComposerModel(seedTitle: seedTitle))
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            shellBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 96, height: 6)
                    .padding(.top, 12)
                    .padding(.bottom, 26)

                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        captureSection
                        voiceSection
                        cadenceSection

                        if let errorMessage = model.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(accentRed)
                                .padding(.horizontal, 4)
                                .accessibilityIdentifier("nativeCaptureError")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(paperWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(panelGrey)
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                )

            Text("MacBook capture")
                .font(.title2.weight(.heavy))
                .foregroundStyle(paperWhite)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            Button(model.isSaving ? "Saving…" : "Save") {
                Task {
                    do {
                        let payload = try await model.save()
                        onSave(payload)
                        dismiss()
                    } catch {
                        model.errorMessage = error.localizedDescription
                    }
                }
            }
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(paperWhite)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(accentRed)
                    .overlay(Capsule().stroke(accentRed.opacity(0.55), lineWidth: 1))
            )
            .disabled(model.isSaving)
            .opacity(model.isSaving ? 0.75 : 1)
        }
        .padding(.horizontal, 20)
    }

    private var captureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Capture")

            VStack(alignment: .leading, spacing: 0) {
                TextField("", text: $model.title, axis: .vertical)
                    .lineLimit(4, reservesSpace: false)
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(paperWhite)
                    .tint(accentRed)
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(panelGrey)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityIdentifier("nativeCaptureTitleField")
            }
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Voice memo")

            VStack(alignment: .leading, spacing: 18) {
                Button(model.voiceButtonTitle) {
                    Task { await model.toggleVoiceCapture() }
                }
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(voiceButtonColor)
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(lineGrey)
                    .frame(height: 1)

                Text(model.voiceStatusText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textGrey)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)
            .background(panelGrey)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var cadenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Cadence")

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    Text("4x/day for 4 days")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(paperWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle("", isOn: $model.scheduleEnabled)
                        .labelsHidden()
                        .tint(accentRed)
                }

                Rectangle()
                    .fill(lineGrey)
                    .frame(height: 1)

                Text("Catch the unlock while it still feels live.")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(textGrey)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)
            .background(panelGrey)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 31, weight: .heavy))
            .foregroundStyle(textGrey)
            .padding(.horizontal, 4)
    }

    private var voiceButtonColor: Color {
        model.voiceState == .recording ? accentRed : accentBrown
    }
}
