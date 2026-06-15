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
            Toggle(isOn: $hasDate) { Label("Date", systemImage: "calendar") }
            if hasDate {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden().frame(maxWidth: .infinity, alignment: .trailing)
            }
            Toggle(isOn: $hasTime) { Label("Time", systemImage: "clock") }
            if hasTime {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden().frame(maxWidth: .infinity, alignment: .trailing)
            }
            Toggle(isOn: $r.urgent) { Label("Urgent", systemImage: "alarm") }
            Picker(selection: $r.repeatRule) {
                ForEach(RepeatRule.allCases) { Text($0.label).tag($0) }
            } label: { Label("Repeat", systemImage: "repeat") }
            Picker(selection: $r.earlyReminder) {
                ForEach(EarlyReminder.allCases) { Text($0.label).tag($0) }
            } label: { Label("Early Reminder", systemImage: "bell") }
        } header: {
            sectionHeader("Date & Time")
        }
        .listRowBackground(Color.white)
    }

    private var organizationSection: some View {
        Section {
            Picker(selection: $r.listName) {
                ForEach(["Reminders", "Work", "Personal", "Shopping", "Health"], id: \.self) { Text($0).tag($0) }
            } label: { Label("List", systemImage: "list.bullet") }

            VStack(alignment: .leading, spacing: 8) {
                Label("Tags", systemImage: "tag")
                HStack {
                    TextField("Add a tag", text: $tagDraft).onSubmit(addTag)
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
            Picker(selection: $r.priority) {
                ForEach(Priority.allCases) { Text($0.label).tag($0) }
            } label: { Label("Priority", systemImage: "exclamationmark.3") }
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
        let t = tagDraft.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        if !t.isEmpty && !r.tags.contains(t) { r.tags.append(t) }
        tagDraft = ""
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                pickedImage = img
                r.imageLocalPath = LocalImageStore.save(img)
            }
        }
    }

    private func commit() {
        addTag()
        r.dueDate = hasDate ? date : nil
        r.dueTime = hasTime ? time : nil
        r.subtasks.removeAll { $0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        if r.title.trimmingCharacters(in: .whitespaces).isEmpty { r.title = "New Reminder" }
        onSave(r)
        dismiss()
    }
}
