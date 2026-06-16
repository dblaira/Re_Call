import SwiftUI
import PhotosUI

/// The entry form. One screen, three faces: the type selector at the top swaps the field set —
/// Reminder (timed nudge), Action (broad GTD-style to-do), or Event (time block). White page,
/// tan entry cells. Reused for create and edit.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationProvider()

    let existing: Reminder?
    var onSave: (Reminder) -> Void

    @State private var r: Reminder
    @State private var hasDate: Bool
    @State private var hasTime: Bool
    @State private var hasDefer: Bool
    @State private var hasEnd: Bool
    @State private var date: Date
    @State private var time: Date
    @State private var deferDate: Date
    @State private var endTime: Date
    @State private var tagDraft = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var committed = false
    @State private var cancelled = false

    private let listChoices = ["Learning", "Leverage", "Delegation", "Inspiration", "Risk", "Health"]
    private let optionColumns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    init(initialKind: ReminderKind = .reminder, existing: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self.existing = existing
        self.onSave = onSave
        var base = existing ?? Reminder()
        if existing == nil { base.kind = initialKind }
        _r = State(initialValue: base)
        _hasDate = State(initialValue: base.dueDate != nil)
        _hasTime = State(initialValue: base.dueTime != nil)
        _hasDefer = State(initialValue: base.deferDate != nil)
        _hasEnd = State(initialValue: base.endTime != nil)
        _date = State(initialValue: base.dueDate ?? Date())
        _time = State(initialValue: base.dueTime ?? Date())
        _deferDate = State(initialValue: base.deferDate ?? Date())
        _endTime = State(initialValue: base.endTime ?? base.dueTime ?? Date())
        _pickedImage = State(initialValue: LocalImageStore.load(base.imageLocalPath))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $r.kind) {
                        ForEach(ReminderKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Brand.card)

                switch r.kind {
                case .reminder: reminderSections
                case .action:   actionSections
                case .event:    eventSections
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white.ignoresSafeArea())
            .tint(Brand.crimson)
            .navigationTitle((existing == nil ? "New " : "Edit ") + r.kind.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancelled = true; dismiss() }.tint(.black)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { commit() }
                        .fontWeight(.bold).tint(Brand.crimson)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onChange(of: photoItem) { _, item in loadPhoto(item) }
            // Auto-save: if the form is swiped away (not via Cancel) and has content, keep it.
            .onDisappear { autosaveIfNeeded() }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Reminder (timed nudge)

    @ViewBuilder private var reminderSections: some View {
        Section {
            TextField("Title", text: $r.title)
            TextField("Notes", text: $r.notes, axis: .vertical).lineLimit(1...5)
            urlField("URL")
            imageRow
        } header: { sectionHeader("Core") }
        .listRowBackground(Brand.card)

        Section {
            dateGroup("Date", icon: "calendar", isOn: $hasDate, date: $date)
            timeGroup("Time", icon: "clock", isOn: $hasTime, time: $time)
            Toggle(isOn: $r.urgent) { Label("Urgent", systemImage: "alarm") }
            repeatGroup
            earlyReminderGroup
        } header: { sectionHeader("Date & Time") }
        .listRowBackground(Brand.card)

        Section {
            listGroup
            tagsEditor
            subtasksEditor("Subtasks", addLabel: "Add Subtask")
            Toggle(isOn: $r.flag) { Label("Flag", systemImage: "flag") }
            priorityGroup
        } header: { sectionHeader("Organization") }
        .listRowBackground(Brand.card)

        Section {
            locationRow
            messagingRow
        } header: { sectionHeader("Places & People") } footer: {
            Text("Saved with the reminder. Apple limits live Messages integration to its own Reminders app.")
                .foregroundStyle(.black.opacity(0.45))
        }
        .listRowBackground(Brand.card)
    }

    // MARK: - Action (broad GTD-style)

    @ViewBuilder private var actionSections: some View {
        Section {
            TextField("What will you do?", text: $r.title)
            TextField("Outcome — what does done look like?", text: $r.outcome, axis: .vertical).lineLimit(1...3)
            subtasksEditor("Steps", addLabel: "Add Step")
        } header: { sectionHeader("Do") }
        .listRowBackground(Brand.card)

        Section {
            priorityGroup
            effortGroup
            energyGroup
            contextGroup
        } header: { sectionHeader("Choose") }
        .listRowBackground(Brand.card)

        Section {
            dateGroup("Due", icon: "calendar", isOn: $hasDate, date: $date)
            dateGroup("Start / defer", icon: "calendar.badge.clock", isOn: $hasDefer, date: $deferDate)
            repeatGroup
            timeGroup("Nudge", icon: "bell", isOn: $hasTime, time: $time)
        } header: { sectionHeader("Schedule") }
        .listRowBackground(Brand.card)

        Section {
            listGroup
            Toggle(isOn: $r.flag) { Label("Flag", systemImage: "flag") }
            tagsEditor
        } header: { sectionHeader("Organize") }
        .listRowBackground(Brand.card)

        Section {
            TextField("Notes", text: $r.notes, axis: .vertical).lineLimit(1...5)
            urlField("Link")
            imageRow
        } header: { sectionHeader("Details") }
        .listRowBackground(Brand.card)

        Section {
            locationRow
            HStack {
                Image(systemName: "person").foregroundStyle(.secondary)
                TextField("Waiting on / delegate to", text: $r.waitingOn)
            }
        } header: { sectionHeader("Place / People") }
        .listRowBackground(Brand.card)
    }

    // MARK: - Event (time block)

    @ViewBuilder private var eventSections: some View {
        Section {
            TextField("Title", text: $r.title)
            TextField("Notes", text: $r.notes, axis: .vertical).lineLimit(1...4)
            locationRow
        } header: { sectionHeader("Event") }
        .listRowBackground(Brand.card)

        Section {
            dateGroup("Date", icon: "calendar", isOn: $hasDate, date: $date)
            timeGroup("Starts", icon: "clock", isOn: $hasTime, time: $time)
            timeGroup("Ends", icon: "clock.badge.checkmark", isOn: $hasEnd, time: $endTime)
            repeatGroup
        } header: { sectionHeader("When") }
        .listRowBackground(Brand.card)
    }

    // MARK: - Reusable field groups

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.black.opacity(0.5))
    }

    private func urlField(_ placeholder: String) -> some View {
        TextField(placeholder, text: $r.url)
            .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
    }

    private var imageRow: some View {
        HStack {
            Label("Image", systemImage: "photo")
            Spacer()
            if let img = pickedImage {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Text(pickedImage == nil ? "Add" : "Change").foregroundStyle(Brand.crimson)
            }
        }
    }

    private var locationRow: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
            TextField("Location", text: $r.locationName)
            Button {
                Task { if let name = await location.currentPlaceName() { r.locationName = name } }
            } label: {
                if location.isResolving { ProgressView() } else { Image(systemName: "location") }
            }.foregroundStyle(Brand.crimson)
        }
    }

    private var messagingRow: some View {
        HStack {
            Image(systemName: "message").foregroundStyle(.secondary)
            TextField("When messaging a person", text: $r.whenMessagingPerson)
        }
    }

    private func dateGroup(_ title: String, icon: String, isOn: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) { Label(title, systemImage: icon) }
            DatePicker(title, selection: date, displayedComponents: .date)
                .labelsHidden().disabled(!isOn.wrappedValue).opacity(isOn.wrappedValue ? 1 : 0.45)
        }
    }

    private func timeGroup(_ title: String, icon: String, isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) { Label(title, systemImage: icon) }
            DatePicker(title, selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden().disabled(!isOn.wrappedValue).opacity(isOn.wrappedValue ? 1 : 0.45)
        }
    }

    private func grid<T: Identifiable & Equatable>(_ title: String, icon: String, _ items: [T], selected: T, label: @escaping (T) -> String, pick: @escaping (T) -> Void) -> some View {
        optionGroup(title, systemImage: icon) {
            LazyVGrid(columns: optionColumns, spacing: 8) {
                ForEach(items) { item in
                    optionButton(label(item), isSelected: item == selected) { pick(item) }
                }
            }
        }
    }

    private var repeatGroup: some View {
        grid("Repeat", icon: "repeat", RepeatRule.allCases, selected: r.repeatRule, label: { $0.label }) { r.repeatRule = $0 }
    }
    private var earlyReminderGroup: some View {
        grid("Early Reminder", icon: "bell", EarlyReminder.allCases, selected: r.earlyReminder, label: { $0.label }) { r.earlyReminder = $0 }
    }
    private var priorityGroup: some View {
        grid("Priority", icon: "exclamationmark.3", Priority.allCases, selected: r.priority, label: { $0.label }) { r.priority = $0 }
    }
    private var effortGroup: some View {
        grid("Effort", icon: "timer", Effort.allCases, selected: r.effort, label: { $0.label }) { r.effort = $0 }
    }
    private var energyGroup: some View {
        grid("Energy", icon: "bolt", Energy.allCases, selected: r.energy, label: { $0.label }) { r.energy = $0 }
    }
    private var contextGroup: some View {
        grid("Context", icon: "mappin.circle", ActionContext.allCases, selected: r.context, label: { $0.label }) { r.context = $0 }
    }
    private var listGroup: some View {
        optionGroup("Lift", systemImage: "sparkles") {
            LazyVGrid(columns: optionColumns, spacing: 8) {
                ForEach(listChoices, id: \.self) { name in
                    optionButton(name, isSelected: r.listName == name) { r.listName = name }
                }
            }
        }
    }

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
            HStack {
                TextField("Add a tag", text: $tagDraft)
                    .onSubmit(addTag)
                    .onChange(of: tagDraft) { _, value in if value.contains(",") { addTag() } }
                Button("Add", action: addTag)
                    .foregroundStyle(Brand.crimson)
                    .disabled(tagDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !r.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(r.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(.system(size: 15, weight: .semibold))
                                Button { r.tags.removeAll { $0 == tag } } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }.foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5).padding(.horizontal, 10)
                            .background(Color(white: 0.92)).clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func subtasksEditor(_ title: String, addLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "checklist")
            ForEach($r.subtasks) { $sub in
                HStack {
                    Image(systemName: "circle").foregroundStyle(.secondary)
                    TextField("Step", text: $sub.title)
                    Button { r.subtasks.removeAll { $0.id == sub.id } } label: {
                        Image(systemName: "minus.circle.fill")
                    }.foregroundStyle(.secondary)
                }
            }
            Button { r.subtasks.append(Subtask()) } label: {
                Text(addLabel).foregroundStyle(Brand.crimson)
            }
        }
    }

    private func optionButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.horizontal, 10)
                .background(isSelected ? Brand.crimson : Color(white: 0.92))
                .foregroundStyle(isSelected ? .white : .black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func optionGroup<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
            content()
        }
    }

    // MARK: - Actions

    private func addTag() {
        let t = tagDraft
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        if !t.isEmpty && !r.tags.contains(t) { r.tags.append(t) }
        tagDraft = ""
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                pickedImage = img
            }
        }
    }

    private func commit() {
        committed = true
        persist()
        dismiss()
    }

    /// Save when the sheet is dismissed by swiping (not Cancel) and the user actually entered something.
    private func autosaveIfNeeded() {
        guard !committed, !cancelled, hasContent else { return }
        persist()
    }

    private var hasContent: Bool {
        if !r.title.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        if !r.notes.isEmpty || !r.outcome.isEmpty || !r.url.isEmpty { return true }
        if !r.locationName.isEmpty || !r.waitingOn.isEmpty { return true }
        if !r.tags.isEmpty { return true }
        if r.subtasks.contains(where: { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }) { return true }
        if hasDate || hasTime || hasDefer || hasEnd || pickedImage != nil { return true }
        return false
    }

    private func persist() {
        addTag()
        if let pickedImage {
            r.imageLocalPath = LocalImageStore.save(pickedImage)
        }
        r.dueDate = hasDate ? date : nil
        r.dueTime = hasTime ? time : nil
        r.deferDate = (r.kind == .action && hasDefer) ? deferDate : nil
        r.endTime = (r.kind == .event && hasEnd) ? endTime : nil
        r.subtasks.removeAll { $0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        if r.title.trimmingCharacters(in: .whitespaces).isEmpty { r.title = "New \(r.kind.label)" }
        onSave(r)
    }
}
