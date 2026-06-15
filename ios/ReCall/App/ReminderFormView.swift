import SwiftUI
import PhotosUI

/// The full-page native entry form: BLACK page (sides, gaps, bottom) with WHITE entry-row cells,
/// grouping all 16 "parts" like the Figma board — Core / Date & Time / Organization /
/// Places & People. Reused for create and edit.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationProvider()

    let existing: Reminder?
    var onSave: (Reminder) -> Void

    @State private var r: Reminder
    @State private var hasDate: Bool
    @State private var hasTime: Bool
    @State private var date: Date
    @State private var time: Date
    @State private var tagDraft = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    private let listChoices = ["Reminders", "Work", "Personal", "Shopping", "Health"]
    private let optionColumns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    init(existing: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self.existing = existing
        self.onSave = onSave
        let base = existing ?? Reminder()
        _r = State(initialValue: base)
        _hasDate = State(initialValue: base.dueDate != nil)
        _hasTime = State(initialValue: base.dueTime != nil)
        _date = State(initialValue: base.dueDate ?? Date())
        _time = State(initialValue: base.dueTime ?? Date())
        _pickedImage = State(initialValue: LocalImageStore.load(base.imageLocalPath))
    }

    var body: some View {
        NavigationStack {
            Form {
                coreSection
                dateTimeSection
                organizationSection
                placesSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())   // black sides / gaps / bottom
            .tint(Brand.crimson)
            .navigationTitle(existing == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") { commit() }
                        .fontWeight(.bold).tint(Brand.crimson)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: photoItem) { _, item in loadPhoto(item) }
        }
        // Light color scheme so the WHITE row cells render dark, legible text/controls.
        // Section headers/footers sit on the black page and are colored light explicitly below.
        .preferredColorScheme(.light)
    }

    /// Light-on-black group label so headers read against the black page.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.6))
    }

    private func optionButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
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

    private var coreSection: some View {
        Section {
            TextField("Title", text: $r.title)
            TextField("Notes", text: $r.notes, axis: .vertical).lineLimit(1...5)
            TextField("URL", text: $r.url)
                .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
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
        } header: {
            sectionHeader("Core")
        }
        .listRowBackground(Color.white)
    }

    private var dateTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $hasDate) { Label("Date", systemImage: "calendar") }
                DatePicker("Date value", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .disabled(!hasDate)
                    .opacity(hasDate ? 1 : 0.45)
            }
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $hasTime) { Label("Time", systemImage: "clock") }
                DatePicker("Time value", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .disabled(!hasTime)
                    .opacity(hasTime ? 1 : 0.45)
            }
            Toggle(isOn: $r.urgent) { Label("Urgent", systemImage: "alarm") }
            optionGroup("Repeat", systemImage: "repeat") {
                LazyVGrid(columns: optionColumns, spacing: 8) {
                    ForEach(RepeatRule.allCases) { rule in
                        optionButton(rule.label, isSelected: r.repeatRule == rule) { r.repeatRule = rule }
                    }
                }
            }
            optionGroup("Early Reminder", systemImage: "bell") {
                LazyVGrid(columns: optionColumns, spacing: 8) {
                    ForEach(EarlyReminder.allCases) { lead in
                        optionButton(lead.label, isSelected: r.earlyReminder == lead) { r.earlyReminder = lead }
                    }
                }
            }
        } header: {
            sectionHeader("Date & Time")
        }
        .listRowBackground(Color.white)
    }

    private var organizationSection: some View {
        Section {
            optionGroup("List", systemImage: "list.bullet") {
                LazyVGrid(columns: optionColumns, spacing: 8) {
                    ForEach(listChoices, id: \.self) { name in
                        optionButton(name, isSelected: r.listName == name) { r.listName = name }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Tags", systemImage: "tag")
                HStack {
                    TextField("Add a tag", text: $tagDraft)
                        .onSubmit(addTag)
                        .onChange(of: tagDraft) { _, value in
                            if value.contains(",") { addTag() }
                        }
                    Button("Add", action: addTag)
                        .foregroundStyle(Brand.crimson)
                        .disabled(tagDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if !r.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(r.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag).font(.system(size: 13, weight: .semibold))
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

            VStack(alignment: .leading, spacing: 8) {
                Label("Subtasks", systemImage: "checklist")
                ForEach($r.subtasks) { $sub in
                    HStack {
                        Image(systemName: "circle").foregroundStyle(.secondary)
                        TextField("Subtask", text: $sub.title)
                        Button { r.subtasks.removeAll { $0.id == sub.id } } label: {
                            Image(systemName: "minus.circle.fill")
                        }.foregroundStyle(.secondary)
                    }
                }
                Button { r.subtasks.append(Subtask()) } label: {
                    Text("Add Subtask").foregroundStyle(Brand.crimson)
                }
            }

            Toggle(isOn: $r.flag) { Label("Flag", systemImage: "flag") }
            optionGroup("Priority", systemImage: "exclamationmark.3") {
                LazyVGrid(columns: optionColumns, spacing: 8) {
                    ForEach(Priority.allCases) { priority in
                        optionButton(priority.label, isSelected: r.priority == priority) { r.priority = priority }
                    }
                }
            }
        } header: {
            sectionHeader("Organization")
        }
        .listRowBackground(Color.white)
    }

    private var placesSection: some View {
        Section {
            HStack {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(.secondary)
                TextField("Location", text: $r.locationName)
                Button {
                    Task { if let name = await location.currentPlaceName() { r.locationName = name } }
                } label: {
                    if location.isResolving { ProgressView() } else { Image(systemName: "location") }
                }.foregroundStyle(Brand.crimson)
            }
            HStack {
                Image(systemName: "message").foregroundStyle(.secondary)
                TextField("When messaging a person", text: $r.whenMessagingPerson)
            }
        } header: {
            sectionHeader("Places & People")
        } footer: {
            Text("Saved with the reminder. Apple limits live Messages integration to its own Reminders app.")
                .foregroundStyle(.white.opacity(0.4))
        }
        .listRowBackground(Color.white)
    }

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
        addTag()
        if let pickedImage {
            r.imageLocalPath = LocalImageStore.save(pickedImage)
        }
        r.dueDate = hasDate ? date : nil
        r.dueTime = hasTime ? time : nil
        r.subtasks.removeAll { $0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        if r.title.trimmingCharacters(in: .whitespaces).isEmpty { r.title = "New Reminder" }
        onSave(r)
        dismiss()
    }
}
