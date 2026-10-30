import SwiftUI
import PhotosUI
import UIKit

/// The entry form. One shared Action-style capture flow for Reminder, Action, and Event entries:
/// the top selector changes where the saved item lands, while the field order stays identical.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationProvider()

    let existing: Reminder?
    let existingTags: [String]
    var onSave: (Reminder) -> Void

    @State private var r: Reminder
    @State private var themeDraft: PostEntryDraft
    @State private var hasDate: Bool
    @State private var hasDefer: Bool
    @State private var date: Date
    @State private var deferDate: Date
    @State private var tagDraft = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var committed = false
    @State private var cancelled = false
    @State private var showSaved = false
    @FocusState private var focusedField: EntryField?
    @State private var decideFocus: Int?
    @State private var visualFocus: Int?
    @State private var subtasks: [Subtask]

    private let listChoices = ["Learning", "Leverage", "Delegation", "Inspiration", "Risk", "Health"]

    private static func dueDateTime(on date: Date, at time: Date? = nil) -> Date {
        let calendar = Calendar.current
        let defaultTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time ?? defaultTime)
        return calendar.date(bySettingHour: timeComponents.hour ?? 12, minute: timeComponents.minute ?? 0, second: 0, of: date) ?? date
    }

    init(initialKind: ReminderKind = .reminder, existing: Reminder?, existingTags: [String] = [], onSave: @escaping (Reminder) -> Void) {
        self.existing = existing
        self.existingTags = existingTags
        self.onSave = onSave
        var base = existing ?? Reminder()
        if existing == nil { base.kind = initialKind }
        _r = State(initialValue: base)
        _themeDraft = State(initialValue: PostEntryDraft(entry: base))
        _subtasks = State(initialValue: base.subtasks)
        _hasDate = State(initialValue: base.dueDate != nil)
        _hasDefer = State(initialValue: base.deferDate != nil)
        _date = State(initialValue: Self.dueDateTime(on: base.dueDate ?? Date(), at: base.dueTime))
        _deferDate = State(initialValue: base.deferDate ?? Date())
        _pickedImage = State(initialValue: LocalImageStore.load(base.imageLocalPath))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(EntryFormCopy.destinationPickerTitle, selection: $r.kind) {
                        ForEach(ReminderKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Brand.card)

                unifiedEntrySections
            }
            .font(.system(size: 17, weight: .regular))
            .dynamicTypeSize(.large)
            .environment(\.legibilityWeight, .regular)
            .accessibilityIdentifier("sharedEntryForm")
            .scrollContentBackground(.hidden)
            .background(Color.white.ignoresSafeArea())
            .tint(Brand.crimson)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    EntryShareBar(content: shareContent)
                    if activeField != nil { keyboardRow }
                }
            }
            // Header mirrors the Title as you type — the type name until the first character, then
            // the live title at full size. Compact icon buttons leave it more room.
            .navigationTitle(r.title.trimmingCharacters(in: .whitespaces).isEmpty ? r.kind.label : r.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(r.title.trimmingCharacters(in: .whitespaces).isEmpty ? r.kind.label : r.title)
                        .font(Brand.serif(24))
                        .foregroundStyle(Self.formInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { cancelled = true; dismiss() } label: {
                        Image(systemName: "xmark.circle").font(.system(size: 22))
                    }
                    .tint(.black)
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { commit() } label: {
                        SaveDiskIcon(size: 24)
                    }
                    .accessibilityLabel("Save")
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onChange(of: photoItem) { _, item in loadPhoto(item) }
            // Auto-save: if the form is swiped away (not via Cancel) and has content, keep it.
            .onDisappear { autosaveIfNeeded() }
        }
        .overlay { if showSaved { savedToast } }
        .preferredColorScheme(.light)
    }

    /// Brief confirmation shown when the Save button is tapped (not on swipe-to-save).
    private var savedToast: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 46)).foregroundStyle(Brand.crimson)
                Text("Locked In").font(Brand.serif(30)).foregroundStyle(.black)
            }
            .padding(.horizontal, 40).padding(.vertical, 30)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.2), radius: 28, y: 12)
        }
        .transition(.opacity)
    }

    // MARK: - Shared entry flow

    private var shareContent: EntryShareContent {
        var entry = r
        entry.visualTemplates = visualDraft
        themeDraft.apply(to: &entry)
        entry.subtasks = subtasks
        entry.tags = EntryShareContent.tags(r.tags, pending: tagDraft)
        entry.dueDate = hasDate ? date : nil
        entry.dueTime = hasDate ? date : nil
        entry.deferDate = hasDefer ? deferDate : nil
        entry.endTime = nil
        return EntryShareContent(entry: entry, sourceApp: "Understood", entryLabel: entry.kind.label,
                                 whenIAm: entry.whenIAm)
    }

    @ViewBuilder private var unifiedEntrySections: some View {
        themeSections

        visualTemplatesSection

        Section {
            persistentField(EntryFormCopy.wantPrompt, text: $r.title, identifier: "Title", field: .title)
            persistentField(EntryFormCopy.whenPrompt, text: $r.whenIAm, identifier: "WhenIAm", field: .whenIAm)
            persistentField(EntryFormCopy.donePrompt, text: $r.outcome, identifier: "Outcome", field: .doneLooksLike)
        } header: { sectionHeader(EntryFormCopy.delegateHeader) }
        .listRowBackground(Brand.card)

        stepsSection

        organizationSection

        Section {
            priorityGroup
            energyGroup
        } header: { sectionHeader(EntryFormCopy.chooseHeader) }
        .listRowBackground(Brand.card)

        Section {
            dateGroup("Start", icon: "calendar.badge.clock", isOn: $hasDefer, date: $deferDate)
            dueDateTimeGroup
            repeatGroup
        } header: { sectionHeader(EntryFormCopy.scheduleHeader) }
        .listRowBackground(Brand.card)

        Section {
            TextField("Notes", text: $r.notes, axis: .vertical).lineLimit(1...)
            urlField("Link")
            imageRow
        } header: { sectionHeader("Details") }
        .listRowBackground(Brand.card)

        Section {
            locationRow
            HStack {
                Image(systemName: "person").foregroundStyle(.secondary)
                TextField("Waiting on / delegate to", text: $r.waitingOn, axis: .vertical).lineLimit(1...)
            }
        } header: { sectionHeader("Place / People") }
        .listRowBackground(Brand.card)
    }

    // MARK: - Reusable field groups

    @ViewBuilder private var themeSections: some View {
        Section {
            Picker(selection: Binding(
                get: { themeDraft.themeID },
                set: { moveCursor(to: nil); themeDraft.selectTheme($0) }
            )) {
                ForEach(PostThemeCatalog.themes) { theme in
                    Label {
                        Text(theme.name)
                    } icon: {
                        Image(uiImage: formPickerIcon(theme.questions.first?.symbol ?? "list.bullet"))
                    }
                    .tag(theme.id)
                }
            } label: {
                Label("Theme", systemImage: "list.bullet")
            }
            .pickerStyle(.menu)
            .tint(Brand.crimson)
            .accessibilityIdentifier("Theme")
        }
        .listRowBackground(Brand.card)

        Section {
            ForEach(themeDraft.answers.indices, id: \.self) { index in
                let question = themeDraft.theme.questions.indices.contains(index) ? themeDraft.theme.questions[index] : nil
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: question?.symbol ?? "text.bubble")
                        .font(Self.decideIconFont)
                        .foregroundStyle(Brand.crimson)
                        .frame(width: 24)
                    PredictiveWritingField(
                        text: postAnswerBinding(index),
                        isFocused: decideFocus == index,
                        label: question?.prompt ?? "Decide",
                        identifier: "themeAnswer\(index)",
                        movesCursorPastQuestion: true,
                        onFocusChange: { editing in
                            if editing {
                                visualFocus = nil
                                decideFocus = index
                            } else if decideFocus == index {
                                decideFocus = nil
                            }
                        }
                    )
                    .id("\(themeDraft.themeID)-\(index)")
                    .alignmentGuide(.firstTextBaseline) { _ in PredictiveWritingField.writingFont.ascender }
                }
            }
        } header: { sectionHeader("Decide") }
        .listRowBackground(Brand.card)
    }

    private func formPickerIcon(_ symbol: String) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        return (UIImage(systemName: symbol, withConfiguration: configuration) ?? UIImage())
            .withTintColor(UIColor(Brand.crimson), renderingMode: .alwaysOriginal)
    }

    private static let formInk = Color(hex: 0x08172D)
    private static let decideQuestionTopPadding: CGFloat = 0
    private static let decideIconFont: Font = .system(size: 16)
    private static let questionFont: Font = .system(size: 17, weight: .regular)
    private var hasDecideQuestions: Bool { true }

    private func postAnswerBinding(_ index: Int) -> Binding<String> {
        let themeID = themeDraft.themeID
        return Binding(
            get: { themeDraft.answers.indices.contains(index) ? themeDraft.answers[index] : "" },
            set: { text in
                guard themeDraft.themeID == themeID else { return }
                themeDraft.setAnswer(text, at: index)
            }
        )
    }

    private func persistentField(_ prompt: String, text: Binding<String>, identifier: String, field: EntryField) -> some View {
        let symbol: String
        switch field {
        case .title: symbol = "target"
        case .whenIAm: symbol = "lightbulb"
        case .doneLooksLike: symbol = "checkmark.circle"
        default: symbol = "pencil"
        }
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(Self.decideIconFont)
                .foregroundStyle(Brand.crimson)
                .frame(width: 24, height: PredictiveWritingField.writingFont.lineHeight)
                .onTapGesture { moveCursor(to: field) }
            VStack(alignment: .leading, spacing: 0) {
                Text(prompt)
                    .font(Self.questionFont)
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { moveCursor(to: field) }
                    .accessibilityIdentifier("DelegateQuestion\(identifier)")
                TextField("", text: text, axis: .vertical)
                    .lineLimit(1...)
                    .textFieldStyle(.plain)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: PredictiveWritingField.writingFont.lineHeight * 2, alignment: .topLeading)
                    .focused($focusedField, equals: field)
                    .accessibilityLabel(prompt)
                    .accessibilityIdentifier(identifier)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            if activeField != field { moveCursor(to: field) }
        })
    }

    // MARK: - Visual templates

    private var visualDraft: VisualTemplateDraft { r.visualTemplates ?? VisualTemplateDraft() }
    private var visualFormatChoices: [VisualTemplate] {
        let selected = visualDraft.format
        let formats = VisualTemplateCatalog.formats
        return formats.contains { $0.id == selected.id } ? formats : [selected] + formats
    }
    private let visualSymbols = ["target", "doc.text", "lightbulb", "person.2"]

    private var visualTemplatesSection: some View {
        Section {
            Picker(selection: Binding(
                get: { visualDraft.selectedFormatID },
                set: { formatID in
                    moveCursor(to: nil)
                    var draft = visualDraft
                    draft.selectFormat(formatID)
                    r.visualTemplates = draft
                }
            )) {
                ForEach(visualFormatChoices) { format in
                    Label {
                        Text(format.name)
                    } icon: {
                        Image(uiImage: formPickerIcon(format.symbol))
                    }
                    .tag(format.id)
                }
            } label: {
                Label("Visual", systemImage: "list.bullet")
            }
            .pickerStyle(.menu)
            .tint(Brand.crimson)
            .accessibilityIdentifier("VisualFormat")
            .accessibilityValue(visualDraft.format.name)
            ForEach(0..<4, id: \.self) { index in
                let prompt = visualDraft.questions[index]
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: visualSymbols[index])
                        .font(Self.decideIconFont)
                        .foregroundStyle(Brand.crimson)
                        .frame(width: 24, height: PredictiveWritingField.writingFont.lineHeight)
                        .onTapGesture { moveCursor(to: .visual(index)) }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(prompt.isEmpty ? "?" : prompt)
                            .font(Self.questionFont)
                            .foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture { moveCursor(to: .visual(index)) }
                            .accessibilityIdentifier("VisualQuestion\(index)")
                        PredictiveWritingField(
                            text: visualAnswerBinding(index),
                            isFocused: visualFocus == index,
                            label: prompt.isEmpty ? "Answer \(index + 1)" : prompt,
                            identifier: "VisualAnswer\(index)",
                            minimumLines: 2,
                            onFocusChange: { editing in
                                if editing {
                                    decideFocus = nil
                                    visualFocus = index
                                } else if visualFocus == index {
                                    visualFocus = nil
                                }
                            }
                        )
                        .id("visual-\(visualDraft.selectedFormatID)-\(index)")
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    if visualFocus != index { moveCursor(to: .visual(index)) }
                })
                .padding(.top, Self.decideQuestionTopPadding)
            }
        }
        .listRowBackground(Brand.card)
    }

    private func visualAnswerBinding(_ index: Int) -> Binding<String> {
        let formatID = visualDraft.selectedFormatID
        return Binding(
            get: { visualDraft.answers[index] },
            set: { text in
                guard visualDraft.selectedFormatID == formatID else { return }
                var draft = visualDraft
                draft.setAnswer(text, at: index)
                r.visualTemplates = draft
            }
        )
    }

    // MARK: - Keyboard row

    /// Adam, 2026-09-26: "why can't it replace the word prediction I never fucking use?" It can't.
    /// With autocorrection off in this form, iOS 27 still kept its suggestion bar above the keys,
    /// empty. Turning prediction off won no space and cost autocorrect and gray completion, so
    /// prediction stays on and the row sits on top of Apple's bar. The Mac has no keyboard to ride.

    /// Every box the cursor can sit in, in the order the keyboard row walks them.
    private enum EntryField: Hashable {
        case decide(Int)
        case visual(Int)
        case title
        case whenIAm
        case doneLooksLike
        case step(UUID)
        case tag
    }

    /// The row that rides on top of the keyboard — Adam, 2026-09-26: "a row of buttons that
    /// could be used for quickly navigating different sections with a form without leaving the
    /// keyboard area". Up and down step box to box, the Decide icons jump straight to their
    /// question, Done drops the keyboard and the row with it. Seven buttons on a four-question
    /// theme, eight on The 5 Ws; Reminder, Action and Calendar get the three-button row.
    ///
    /// The row is the form's own bar, not Apple's keyboard toolbar: Apple's toolbar pushed
    /// Done out of sight when The 5 Ws put eight buttons in it. Fixed 38-point buttons keep all
    /// eight on the narrowest iPhone, and the bar is 40 points tall.
    private var keyboardRow: some View {
        HStack(spacing: 0) {
            keyboardRowButton("chevron.up", label: "Previous box", id: "KeyboardRowUp") { moveFocus(by: -1) }
            keyboardRowButton("chevron.down", label: "Next box", id: "KeyboardRowDown") { moveFocus(by: 1) }

            Spacer(minLength: 4)
            if hasDecideQuestions {
                // The same icons that sit beside each question in the form, so no reading is needed.
                ForEach(themeDraft.answers.indices, id: \.self) { index in
                    let question = themeDraft.theme.questions.indices.contains(index) ? themeDraft.theme.questions[index] : nil
                    keyboardRowButton(question?.symbol ?? "text.bubble",
                                      label: question?.prompt ?? "Decide \(index + 1)",
                                      id: "KeyboardRowDecide\(index)") { moveCursor(to: .decide(index)) }
                }
                Spacer(minLength: 4)
            }

            Button { moveCursor(to: nil) } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Brand.crimson)
            .accessibilityIdentifier("KeyboardRowDone")
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func keyboardRowButton(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 38, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Brand.crimson)
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    /// The boxes in form order: Decide, Visual templates, Delegate, Steps, then the tag box.
    private var fieldOrder: [EntryField] {
        var order: [EntryField] = []
        if hasDecideQuestions {
            order += themeDraft.answers.indices.map { EntryField.decide($0) }
        }
        order += (0..<4).map { EntryField.visual($0) }
        order += [.title, .whenIAm, .doneLooksLike]
        order += subtasks.map { EntryField.step($0.id) }
        order.append(.tag)
        return order
    }

    /// One box up or down. At either end the row does nothing.
    private func moveFocus(by step: Int) {
        let order = fieldOrder
        guard let current = activeField, let index = order.firstIndex(of: current) else {
            moveCursor(to: order.first)
            return
        }
        let next = index + step
        guard order.indices.contains(next) else { return }
        moveCursor(to: order[next])
    }

    /// The box that has the cursor, whether it is a SwiftUI box or a UIKit Decide box.
    private var activeField: EntryField? {
        if let index = visualFocus { return .visual(index) }
        if let index = decideFocus { return .decide(index) }
        return focusedField
    }

    /// Puts the cursor in one box, or nowhere. Decide boxes are UIKit, the rest are SwiftUI.
    private func moveCursor(to field: EntryField?) {
        switch field {
        case .decide(let index)?:
            // The UIKit box takes the cursor itself; clearing SwiftUI's focus here as well
            // would dismiss the keyboard out from under it.
            visualFocus = nil
            decideFocus = index
        case .visual(let index)?:
            decideFocus = nil
            visualFocus = index
        case let other?:
            visualFocus = nil
            decideFocus = nil
            focusedField = other
        case nil:
            visualFocus = nil
            decideFocus = nil
            focusedField = nil
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Self.formInk.opacity(0.72))
    }

    private func urlField(_ placeholder: String) -> some View {
        TextField(placeholder, text: $r.url, axis: .vertical)
            .lineLimit(1...)
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
            TextField("Location", text: $r.locationName, axis: .vertical).lineLimit(1...)
            Button {
                Task { if let name = await location.currentPlaceName() { r.locationName = name } }
            } label: {
                if location.isResolving { ProgressView() } else { Image(systemName: "location") }
            }.foregroundStyle(Brand.crimson)
        }
    }

    private func dateGroup(_ title: String, icon: String, isOn: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) { Label(title, systemImage: icon) }
            DatePicker(title, selection: date, displayedComponents: .date)
                .labelsHidden().disabled(!isOn.wrappedValue).opacity(isOn.wrappedValue ? 1 : 0.45)
        }
    }

    private var dueDateTimeGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasDate) { Label("Due", systemImage: "calendar") }
            DatePicker("Due", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden().disabled(!hasDate).opacity(hasDate ? 1 : 0.45)
        }
        .onChange(of: hasDate) { _, isEnabled in
            if isEnabled { date = Self.dueDateTime(on: date) }
        }
    }

    /// A single clean dropdown row for a CaseIterable enum selector.
    private func enumMenu<T: CaseIterable & Identifiable & Hashable>(
        _ title: String, icon: String, selection: Binding<T>, label: @escaping (T) -> String
    ) -> some View where T.AllCases: RandomAccessCollection {
        Picker(selection: selection) {
            ForEach(T.allCases) { Text(label($0)).tag($0) }
        } label: {
            Label(title, systemImage: icon)
        }
        .pickerStyle(.menu)
        .tint(Brand.crimson)
    }

    private var repeatGroup: some View {
        enumMenu("Repeat", icon: "repeat", selection: $r.repeatRule) { $0.label }
    }
    private var priorityGroup: some View {
        enumMenu("Priority", icon: "exclamationmark.3", selection: $r.priority) { $0.label }
    }
    private var energyGroup: some View {
        enumMenu("Energy", icon: "bolt", selection: $r.energy) { $0.label }
    }
    /// One organizing area: Pattern first, then Lift and Tags at the same hierarchy level.
    private var organizationSection: some View {
        Section {
            enumMenu(EntryFormCopy.patternTitle, icon: "list.number", selection: $r.context) { $0.label }
            listGroup
            tagsEditor
        } header: { sectionHeader(EntryFormCopy.patternHeader) }
        .listRowBackground(Brand.card)
    }
    private var listGroup: some View {
        Picker(selection: $r.listName) {
            Text("None").tag("")
            ForEach(listChoices, id: \.self) { Text($0).tag($0) }
        } label: {
            Label("Lift", systemImage: "sparkles")
        }
        .pickerStyle(.menu)
        .tint(Brand.crimson)
    }

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags", systemImage: "tag")
            HStack {
                TextField("Add a tag", text: $tagDraft, axis: .vertical).lineLimit(1...)
                    .focused($focusedField, equals: .tag)
                    .onSubmit(addTag)
                    .onChange(of: tagDraft) { _, value in if value.contains(",") { addTag() } }
                Button("Add", action: addTag)
                    .foregroundStyle(Brand.crimson)
                    .disabled(tagDraft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !suggestedTags.isEmpty {
                Menu {
                    ForEach(suggestedTags, id: \.self) { tag in
                        Button(tag) { addExistingTag(tag) }
                    }
                } label: {
                    HStack {
                        Label("Add a recent tag", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                .tint(Brand.crimson)
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

    private var stepsSection: some View {
        Section {
            ForEach($subtasks) { $sub in
                HStack {
                    Image(systemName: "circle").foregroundStyle(.secondary)
                    TextField("Step", text: $sub.title, axis: .vertical).lineLimit(1...)
                        .accessibilityIdentifier("Step")
                        .focused($focusedField, equals: .step(sub.id))
                    Button {
                        subtasks.removeAll { $0.id == sub.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("removeStep")
                }
            }

            Button(action: addSubtask) {
                Text(EntryFormCopy.addStepTitle).foregroundStyle(Brand.crimson)
            }
        } header: {
            sectionHeader(EntryFormCopy.stepsTitle)
        }
        .listRowBackground(Brand.card)
    }

    // MARK: - Actions

    private func addSubtask() {
        let subtask = Subtask()
        subtasks.append(subtask)
        DispatchQueue.main.async { moveCursor(to: .step(subtask.id)) }
    }

    private func addTag() {
        let t = tagDraft
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        if !t.isEmpty && !r.tags.contains(t) { r.tags.append(t) }
        tagDraft = ""
    }

    /// Previously-used tags not already on this item (most-used first, supplied by the caller).
    private var suggestedTags: [String] { existingTags.filter { !r.tags.contains($0) } }

    private func addExistingTag(_ tag: String) {
        if !r.tags.contains(tag) { r.tags.append(tag) }
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.3)) { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { dismiss() }
    }

    /// Save when the sheet is dismissed by swiping (not Cancel) and the user actually entered something.
    private func autosaveIfNeeded() {
        guard !committed, !cancelled, hasContent else { return }
        persist()
    }

    private var hasContent: Bool {
        if themeDraft.hasUserContent || visualDraft.hasUserContent { return true }
        if !r.title.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        if !r.notes.isEmpty || !r.outcome.isEmpty || !r.whenIAm.isEmpty || !r.url.isEmpty { return true }
        if !r.locationName.isEmpty || !r.waitingOn.isEmpty { return true }
        if !r.tags.isEmpty { return true }
        if subtasks.contains(where: { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }) { return true }
        if hasDate || hasDefer || pickedImage != nil { return true }
        return false
    }

    private func persist() {
        addTag()
        r.visualTemplates = visualDraft
        themeDraft.apply(to: &r)
        if let pickedImage {
            r.imageLocalPath = LocalImageStore.save(pickedImage)
        }
        r.dueDate = hasDate ? date : nil
        r.dueTime = hasDate ? date : nil
        r.deferDate = hasDefer ? deferDate : nil
        r.endTime = nil
        r.subtasks = subtasks.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        if r.title.trimmingCharacters(in: .whitespaces).isEmpty { r.title = "New \(r.kind.label)" }
        onSave(r)
    }
}

private struct PredictiveWritingField: UIViewRepresentable {
    @Binding var text: String
    let isFocused: Bool
    let label: String
    let identifier: String
    var minimumLines: CGFloat = 3
    var movesCursorPastQuestion = false
    let onFocusChange: (Bool) -> Void

    static var writingFont: UIFont {
        #if targetEnvironment(macCatalyst)
        UIFont.preferredFont(forTextStyle: .body)
        #else
        UIFont.systemFont(ofSize: 17, weight: .regular)
        #endif
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .black
        view.tintColor = UIColor(Brand.crimson)
        view.font = Self.writingFont
        #if targetEnvironment(macCatalyst)
        view.adjustsFontForContentSizeCategory = true
        #else
        view.adjustsFontForContentSizeCategory = false
        #endif
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.isScrollEnabled = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.keyboardType = .default
        view.autocapitalizationType = .sentences
        view.autocorrectionType = .yes
        view.spellCheckingType = .yes
        view.inlinePredictionType = .yes
        view.text = text
        view.accessibilityLabel = label
        view.accessibilityIdentifier = identifier
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        view.accessibilityLabel = label
        view.accessibilityIdentifier = identifier
        // Marked text is the gray continuation. Replacing storage or moving the
        // cursor here drops it. Space accepts it through the system keyboard.
        // Focus still follows the keyboard row while a continuation is showing.
        if view.markedTextRange == nil, view.text != text {
            let selection = view.selectedRange
            view.text = text
            let length = (text as NSString).length
            let location = min(selection.location, length)
            view.selectedRange = NSRange(location: location, length: min(selection.length, length - location))
        }
        if isFocused, !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused, view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let minimum = (uiView.font ?? Self.writingFont).lineHeight * minimumLines
        return CGSize(width: width, height: ceil(max(minimum, fitted.height)))
    }

    static func dismantleUIView(_ view: UITextView, coordinator: Coordinator) {
        view.delegate = nil
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PredictiveWritingField
        init(parent: PredictiveWritingField) { self.parent = parent }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            true
        }

        func textViewDidChange(_ textView: UITextView) {
            let committed = Self.committedText(in: textView)
            if parent.text != committed { parent.text = committed }
        }

        /// Everything typed, without the gray continuation. Saving while a continuation is
        /// showing keeps every typed word and never saves the gray suggestion.
        static func committedText(in textView: UITextView) -> String {
            guard let marked = textView.markedTextRange else { return textView.text }
            let start = textView.offset(from: textView.beginningOfDocument, to: marked.start)
            let end = textView.offset(from: textView.beginningOfDocument, to: marked.end)
            let storage = textView.text as NSString
            guard start >= 0, end >= start, end <= storage.length else { return textView.text }
            return storage.replacingCharacters(in: NSRange(location: start, length: end - start), with: "")
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused { parent.onFocusChange(true) }
            #if targetEnvironment(macCatalyst)
            // Mac finalizes click selection after this callback. Only Decide embeds a question.
            if parent.movesCursorPastQuestion {
                DispatchQueue.main.async { Self.moveCursorPastQuestion(in: textView) }
            }
            #endif
        }

        #if targetEnvironment(macCatalyst)
        static func moveCursorPastQuestion(in textView: UITextView) {
            guard textView.isFirstResponder, textView.markedTextRange == nil else { return }
            let storage = textView.text as NSString
            let lineBreak = storage.range(of: "\n").location
            let questionEnd = lineBreak == NSNotFound ? storage.length : lineBreak
            let selection = textView.selectedRange
            guard selection.length == 0, selection.location <= questionEnd else { return }
            textView.selectedRange = NSRange(location: storage.length, length: 0)
        }
        #endif

        func textViewDidEndEditing(_ textView: UITextView) {
            let committed = Self.committedText(in: textView)
            if parent.text != committed { parent.text = committed }
            if parent.isFocused { parent.onFocusChange(false) }
        }
    }
}

private enum EntryFormCopy {
    static let destinationPickerTitle = "Destination"
    static let delegateHeader = "Delegate"
    static let patternHeader = "Pattern"
    static let chooseHeader = "Choose"
    static let scheduleHeader = "Schedule"
    static let wantPrompt = "What do I want?"
    static let whenPrompt = "When I am...I like to"
    static let donePrompt = "Done looks like..."
    static let stepsTitle = "Steps"
    static let addStepTitle = "Add Step"
    static let patternTitle = "Pattern"
}

// MARK: - Save (floppy disk) icon

/// A classic floppy-disk "save" glyph drawn as line art — iOS has no built-in floppy symbol.
/// Body with a beveled top-right corner, a shutter window up top, and a label at the bottom.
struct FloppyDisk: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let ox = rect.midX - s / 2, oy = rect.midY - s / 2
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x / 24 * s, y: oy + y / 24 * s) }
        var p = Path()
        // Body outline (rounded corners, beveled top-right)
        p.move(to: pt(3, 2))
        p.addLine(to: pt(16, 2))
        p.addLine(to: pt(22, 8))
        p.addLine(to: pt(22, 21))
        p.addQuadCurve(to: pt(21, 22), control: pt(22, 22))
        p.addLine(to: pt(3, 22))
        p.addQuadCurve(to: pt(2, 21), control: pt(2, 22))
        p.addLine(to: pt(2, 3))
        p.addQuadCurve(to: pt(3, 2), control: pt(2, 2))
        p.closeSubpath()
        // Shutter window (open at the top edge)
        p.move(to: pt(8, 2))
        p.addLine(to: pt(8, 9))
        p.addLine(to: pt(15, 9))
        p.addLine(to: pt(15, 2))
        // Label (rounded top, open at the bottom edge)
        p.move(to: pt(6, 22))
        p.addLine(to: pt(6, 15))
        p.addQuadCurve(to: pt(7, 14), control: pt(6, 14))
        p.addLine(to: pt(17, 14))
        p.addQuadCurve(to: pt(18, 15), control: pt(18, 14))
        p.addLine(to: pt(18, 22))
        return p
    }
}

struct SaveDiskIcon: View {
    var size: CGFloat = 24
    var body: some View {
        FloppyDisk()
            .stroke(Color.black, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
