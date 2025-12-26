import SwiftUI
import AlarmKit

struct AlarmListView: View {
    @Environment(ItsukiAlarmManager.self) private var alarmManager: ItsukiAlarmManager

    @State private var showingAddSheet = false
    @State private var editingAlarm: ItsukiAlarm?
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                if alarmManager.runningAlarms.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Next alarm countdown banner
                            if let nextAlarm = getNextAlarm() {
                                NextAlarmBanner(alarm: nextAlarm)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            ForEach(alarmManager.runningAlarms) { alarm in
                                AlarmRow(
                                    alarm: alarm,
                                    onToggle: { toggleAlarm(alarm) },
                                    onEdit: { editingAlarm = alarm },
                                    onDuplicate: { duplicateAlarm(alarm) },
                                    onDelete: { deleteAlarm(alarm) }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding()
                        .animation(Theme.SpringConfig.gentle, value: alarmManager.runningAlarms.count)
                    }
                }
            }
            .navigationTitle("ItsukiAlarm")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                        HapticManager.shared.light()
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.textSecondary)
                            .font(.system(size: 20))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                        HapticManager.shared.light()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Theme.accentGradient)
                                .frame(width: 36, height: 36)

                            Image(systemName: "plus")
                                .foregroundColor(Theme.background)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AlarmEditSheet(alarmManager: alarmManager)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditSheet(alarmManager: alarmManager, existingAlarm: alarm)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Helper Functions

    func getNextAlarm() -> ItsukiAlarm? {
        // Filter for scheduled alarms
        let scheduledAlarms = alarmManager.runningAlarms.filter { $0.state == .scheduled }
        guard !scheduledAlarms.isEmpty else { return nil }

        // Find the one with the earliest scheduled time
        return scheduledAlarms.min(by: { alarm1, alarm2 in
            guard let time1 = alarm1.scheduledTime, let time2 = alarm2.scheduledTime else {
                return false
            }
            return getNextOccurrence(for: time1) < getNextOccurrence(for: time2)
        })
    }

    func getNextOccurrence(for time: Alarm.Schedule.Relative.Time) -> Date {
        let now = Date()
        let calendar = Calendar.current

        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        if let todayOccurrence = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) {
            return todayOccurrence
        }

        return now.addingTimeInterval(86400) // Fallback: tomorrow
    }

    func toggleAlarm(_ alarm: ItsukiAlarm) {
        HapticManager.shared.light()

        Task {
            do {
                try await alarmManager.toggleAlarm(alarm.id)
            } catch {
                print("❌ Failed to toggle alarm: \(error)")
            }
        }
    }

    func duplicateAlarm(_ alarm: ItsukiAlarm) {
        HapticManager.shared.medium()

        // Create duplicate with modified metadata
        var duplicateMetadata = alarm.metadata
        duplicateMetadata.title = alarm.title.isEmpty ? "Alarm (Copy)" : "\(alarm.title) (Copy)"
        duplicateMetadata.createdAt = Date()

        // Add duplicate alarm
        Task {
            do {
                guard let time = alarm.scheduledTime else {
                    print("❌ Cannot duplicate alarm without scheduled time")
                    return
                }

                let repeats = alarm.scheduledWeekdays ?? []
                try await alarmManager.addAlarm(time: time, repeats: repeats, metadata: duplicateMetadata)
                print("✅ Alarm duplicated successfully")
            } catch {
                print("❌ Failed to duplicate alarm: \(error)")
            }
        }
    }

    func deleteAlarm(_ alarm: ItsukiAlarm) {
        HapticManager.shared.heavy()

        Task {
            do {
                try await alarmManager.deleteAlarm(id: alarm.id)
            } catch {
                print("❌ Failed to delete alarm: \(error)")
            }
        }
    }
}

// MARK: - Next Alarm Banner

struct NextAlarmBanner: View {
    let alarm: ItsukiAlarm
    @State private var timeUntilAlarm: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundColor(Theme.accent)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text("Next Alarm")
                    .font(Theme.caption())
                    .foregroundColor(Theme.textSecondary)

                Text(timeUntilAlarm.isEmpty ? "Calculating..." : timeUntilAlarm)
                    .font(Theme.subheadline())
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()

            if let scheduledTime = alarm.scheduledTime {
                Text("\(scheduledTime.hour):\(String(format: "%02d", scheduledTime.minute))")
                    .font(Theme.headline())
                    .foregroundColor(Theme.accent)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .onAppear(perform: updateTimeUntilAlarm)
        .onReceive(timer) { _ in
            updateTimeUntilAlarm()
        }
    }

    func updateTimeUntilAlarm() {
        guard let scheduledTime = alarm.scheduledTime else {
            timeUntilAlarm = "Unknown"
            return
        }

        let now = Date()
        let calendar = Calendar.current

        var components = DateComponents()
        components.hour = scheduledTime.hour
        components.minute = scheduledTime.minute
        components.second = 0

        guard let nextOccurrence = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else {
            timeUntilAlarm = "Unknown"
            return
        }

        let interval = nextOccurrence.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            timeUntilAlarm = "Rings in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            timeUntilAlarm = "Rings in \(minutes)m"
        } else {
            timeUntilAlarm = "Rings in < 1m"
        }
    }
}

// MARK: - Alarm Row

struct AlarmRow: View {
    let alarm: ItsukiAlarm
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // Time display
                if let scheduledTime = alarm.scheduledTime {
                    Text("\(scheduledTime.hour):\(String(format: "%02d", scheduledTime.minute))")
                        .font(Theme.timeMedium())
                        .foregroundColor(alarm.state == .scheduled ? Theme.textPrimary : Theme.textSecondary)
                }

                HStack(spacing: 8) {
                    Text(alarm.title.isEmpty ? "Alarm" : alarm.title)
                        .font(Theme.subheadline())
                        .foregroundColor(Theme.textSecondary)

                    if alarm.wakeUpCheck.isEnabled {
                        Image(systemName: "bell.badge")
                            .foregroundColor(Theme.accent.opacity(0.7))
                            .font(.system(size: 12))
                    }
                }

                // Repeat pattern
                if let weekdays = alarm.scheduledWeekdays, !weekdays.isEmpty {
                    Text(formatRepeatPattern(weekdays))
                        .font(Theme.caption())
                        .foregroundColor(Theme.textTertiary)
                }

                // Challenge badges
                if !alarm.challenges.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 12))

                        Text("\(alarm.challenges.count) challenge\(alarm.challenges.count == 1 ? "" : "s")")
                            .font(Theme.caption())
                            .foregroundColor(Theme.textSecondary)

                        // Challenge type icons
                        HStack(spacing: 4) {
                            ForEach(Array(alarm.challenges.prefix(3)), id: \.id) { challenge in
                                Image(systemName: challengeIcon(for: challenge.type))
                                    .foregroundColor(Theme.accent.opacity(0.7))
                                    .font(.system(size: 10))
                            }

                            if alarm.challenges.count > 3 {
                                Text("+\(alarm.challenges.count - 3)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.accent.opacity(0.7))
                            }
                        }
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.state == .scheduled },
                set: { _ in
                    HapticManager.shared.light()
                    withAnimation(Theme.SpringConfig.gentle) {
                        onToggle()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .modernCard(elevation: .light)
        .opacity(alarm.state == .scheduled ? 1.0 : 0.6)
        .blur(radius: alarm.state == .scheduled ? 0 : 0.5)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.SpringConfig.snappy, value: isPressed)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                HapticManager.shared.light()
                onEdit()
            }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(action: {
                HapticManager.shared.light()
                onDuplicate()
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Button(role: .destructive, action: {
                HapticManager.shared.heavy()
                onDelete()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }

            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            .tint(Theme.accent)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            HapticManager.shared.medium()
            onEdit()
        }
    }

    func challengeIcon(for type: ChallengeType) -> String {
        switch type {
        case .math:
            return "function"
        case .bluetooth:
            return "bluetooth"
        case .typing:
            return "keyboard"
        case .memory:
            return "brain.head.profile"
        }
    }

    func formatRepeatPattern(_ weekdays: Set<Locale.Weekday>) -> String {
        let sorted = weekdays.sorted { weekdayOrder($0) < weekdayOrder($1) }

        if sorted == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Weekdays"
        } else if sorted == [.saturday, .sunday] {
            return "Weekend"
        } else if sorted.count == 7 {
            return "Every day"
        } else {
            return sorted.map { weekdayShort($0) }.joined(separator: ", ")
        }
    }

    func weekdayShort(_ weekday: Locale.Weekday) -> String {
        switch weekday {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    func weekdayOrder(_ weekday: Locale.Weekday) -> Int {
        switch weekday {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "bell.slash")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.textSecondary, Theme.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .pulse(minOpacity: 0.6, maxOpacity: 1.0, duration: 2.0)

            VStack(spacing: 12) {
                Text("No Alarms Yet")
                    .font(Theme.title1())
                    .foregroundColor(Theme.textPrimary)

                Text("Create your first alarm to get started")
                    .font(Theme.body())
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Helpful tips
            VStack(alignment: .leading, spacing: 16) {
                TipRow(icon: "puzzlepiece.fill", text: "Add challenges to make waking up interactive")
                TipRow(icon: "bell.badge", text: "Enable wake-up check to verify you're awake")
                TipRow(icon: "bluetooth", text: "Connect to devices for creative wake-up challenges")
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .font(.system(size: 16))
                .frame(width: 24)

            Text(text)
                .font(Theme.caption())
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Alarm Edit Sheet

struct AlarmEditSheet: View {
    @Environment(\.dismiss) var dismiss
    let alarmManager: ItsukiAlarmManager
    var existingAlarm: ItsukiAlarm?

    @State private var selectedHour = 7
    @State private var selectedMinute = 0
    @State private var label = ""
    @State private var selectedIcon: _AlarmMetadata.Icon = .sun
    @State private var selectedWeekdays: Set<Locale.Weekday> = []
    @State private var challenges: [AnyChallengeConfiguration] = []
    @State private var wakeUpCheckEnabled = false
    @State private var wakeUpDelayMinutes = 10
    @State private var wakeUpResponseMinutes = 2
    @State private var showingSaveSuccess = false
    @State private var showingChallengePicker = false

    var isEditMode: Bool {
        existingAlarm != nil
    }

    init(alarmManager: ItsukiAlarmManager, existingAlarm: ItsukiAlarm? = nil) {
        self.alarmManager = alarmManager
        self.existingAlarm = existingAlarm
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.surfaceElevated.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Time Picker Section
                        timePickerSection

                        // Label and Icon Section
                        labelSection

                        // Repeat Section
                        repeatSection

                        // Challenges Section
                        challengesSection

                        // Wake-Up Check Section
                        wakeUpCheckSection

                        // Action Buttons
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditMode ? "Edit Alarm" : "New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveAlarm) {
                        if showingSaveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Text("Save")
                                .font(Theme.headline())
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.shared.light()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .onAppear {
                loadExistingAlarm()
            }
            .sheet(isPresented: $showingChallengePicker) {
                ChallengePickerView(challenges: $challenges)
            }
        }
    }

    // MARK: - Sections

    var timePickerSection: some View {
        VStack(spacing: 16) {
            Text("Set Time")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                HStack {
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text(":")
                        .font(Theme.timeMedium())
                        .foregroundColor(Theme.textPrimary)

                    Picker("Minute", selection: $selectedMinute) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 150)

                Text("\(selectedHour):\(String(format: "%02d", selectedMinute))")
                    .font(Theme.timeMedium())
                    .foregroundColor(Theme.textPrimary)
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }

    var labelSection: some View {
        VStack(spacing: 16) {
            Text("Label & Icon")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                FloatingTextField(label: "Alarm name (optional)", text: $label)

                // Icon picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(_AlarmMetadata.Icon.allCases, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                HapticManager.shared.light()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: icon.rawValue)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedIcon == icon ? Theme.background : Theme.accent)
                                        .frame(width: 50, height: 50)
                                        .background(selectedIcon == icon ? Theme.accent : Theme.surfaceElevated)
                                        .cornerRadius(12)

                                    Text(icon.title)
                                        .font(Theme.caption())
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }

    var repeatSection: some View {
        VStack(spacing: 16) {
            Text("Repeat")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Weekday buttons
                HStack(spacing: 8) {
                    ForEach([Locale.Weekday.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday], id: \.self) { weekday in
                        Button(action: {
                            if selectedWeekdays.contains(weekday) {
                                selectedWeekdays.remove(weekday)
                            } else {
                                selectedWeekdays.insert(weekday)
                            }
                            HapticManager.shared.light()
                        }) {
                            Text(weekdayShortName(weekday))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedWeekdays.contains(weekday) ? Theme.background : Theme.accent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(selectedWeekdays.contains(weekday) ? Theme.accent : Theme.surfaceElevated)
                                .cornerRadius(10)
                        }
                    }
                }

                // Smart suggestions
                HStack(spacing: 8) {
                    Button(action: {
                        selectedWeekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                        HapticManager.shared.light()
                    }) {
                        Text("Weekdays")
                            .font(Theme.caption())
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        selectedWeekdays = [.saturday, .sunday]
                        HapticManager.shared.light()
                    }) {
                        Text("Weekend")
                            .font(Theme.caption())
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        selectedWeekdays = []
                        HapticManager.shared.light()
                    }) {
                        Text("Once")
                            .font(Theme.caption())
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(8)
                    }

                    Spacer()
                }

                // Display selected pattern
                if !selectedWeekdays.isEmpty {
                    Text(repeatPatternDescription())
                        .font(Theme.body())
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
        }
    }

    var challengesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Challenges")
                    .font(Theme.headline())
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                Text("\(challenges.count)")
                    .font(Theme.caption())
                    .foregroundColor(Theme.textTertiary)
            }

            VStack(spacing: 12) {
                if challenges.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "puzzlepiece")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary)

                        Text("No challenges yet")
                            .font(Theme.body())
                            .foregroundColor(Theme.textSecondary)

                        Text("Add challenges to make waking up more interactive")
                            .font(Theme.caption())
                            .foregroundColor(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    // Challenges list
                    ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                        HStack(spacing: 12) {
                            // Order number
                            ZStack {
                                Circle()
                                    .fill(Theme.accent.opacity(0.2))
                                    .frame(width: 32, height: 32)

                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.accent)
                            }

                            // Challenge info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(challenge.type.rawValue)
                                    .font(Theme.subheadline())
                                    .foregroundColor(Theme.textPrimary)

                                Text(challenge.displayName)
                                    .font(Theme.caption())
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            // Delete button
                            Button(action: {
                                withAnimation(Theme.SpringConfig.gentle) {
                                    challenges.remove(at: index)
                                }
                                HapticManager.shared.light()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Theme.textSecondary)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding()
                        .background(Theme.surfaceElevated)
                        .cornerRadius(12)
                    }
                }

                // Add Challenge Button
                Button(action: {
                    showingChallengePicker = true
                    HapticManager.shared.light()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.accent)

                        Text("Add Challenge")
                            .font(Theme.body())
                            .foregroundColor(Theme.textPrimary)

                        Spacer()
                    }
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(12)
                }
            }
        }
    }

    var wakeUpCheckSection: some View {
        VStack(spacing: 16) {
            Text("Wake-Up Verification")
                .font(Theme.headline())
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                // Enable toggle
                Toggle(isOn: $wakeUpCheckEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Wake-Up Check")
                            .font(Theme.body())
                            .foregroundColor(Theme.textPrimary)

                        Text("Get a notification later to confirm you're awake")
                            .font(Theme.caption())
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))

                if wakeUpCheckEnabled {
                    VStack(spacing: 16) {
                        Divider()
                            .background(Theme.border)

                        // Delay picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Check after (minutes)")
                                .font(Theme.caption())
                                .foregroundColor(Theme.textSecondary)

                            Picker("Delay", selection: $wakeUpDelayMinutes) {
                                ForEach(WakeUpCheckConfig.delayOptions, id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)
                        }

                        // Response time picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response time (minutes)")
                                .font(Theme.caption())
                                .foregroundColor(Theme.textSecondary)

                            Picker("Response Time", selection: $wakeUpResponseMinutes) {
                                ForEach(WakeUpCheckConfig.responseTimeOptions, id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.accent)
                        }

                        Text("If you don't respond within \(wakeUpResponseMinutes) minutes, the alarm will re-trigger")
                            .font(Theme.caption())
                            .foregroundColor(Theme.textTertiary)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
            .background(Theme.surface)
            .cornerRadius(16)
        }
        .animation(Theme.SpringConfig.gentle, value: wakeUpCheckEnabled)
    }

    var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveAlarm) {
                HStack {
                    if showingSaveSuccess {
                        Image(systemName: "checkmark")
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text(isEditMode ? "Save Changes" : "Create Alarm")
                            .font(Theme.headline())
                    }
                }
            }
            .buttonStyle(GradientButtonStyle())

            Button(action: {
                HapticManager.shared.light()
                dismiss()
            }) {
                Text("Cancel")
                    .font(Theme.body())
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    // MARK: - Logic

    private func loadExistingAlarm() {
        guard let alarm = existingAlarm else { return }

        if let scheduledTime = alarm.scheduledTime {
            selectedHour = scheduledTime.hour
            selectedMinute = scheduledTime.minute
        }
        label = alarm.title
        selectedIcon = alarm.icon
        selectedWeekdays = alarm.scheduledWeekdays ?? []
        challenges = alarm.challenges
        wakeUpCheckEnabled = alarm.wakeUpCheck.isEnabled
        wakeUpDelayMinutes = alarm.wakeUpCheck.delayMinutes
        wakeUpResponseMinutes = alarm.wakeUpCheck.responseTimeMinutes
    }

    private func saveAlarm() {
        HapticManager.shared.medium()

        let wakeUpConfig = WakeUpCheckConfig(
            isEnabled: wakeUpCheckEnabled,
            delayMinutes: wakeUpDelayMinutes,
            responseTimeMinutes: wakeUpResponseMinutes
        )

        var metadata = _AlarmMetadata(
            icon: selectedIcon,
            title: label.isEmpty ? "Alarm" : label
        )
        metadata.challenges = challenges
        metadata.wakeUpCheck = wakeUpConfig

        Task {
            do {
                if let existing = existingAlarm {
                    // Update existing alarm - would need to implement update method
                    print("Update alarm - to be implemented")
                } else {
                    // Create new alarm
                    try await alarmManager.addAlarm(
                        time: Alarm.Schedule.Relative.Time(hour: selectedHour, minute: selectedMinute),
                        repeats: selectedWeekdays.isEmpty ? nil : selectedWeekdays,
                        metadata: metadata
                    )
                }

                withAnimation(Theme.SpringConfig.snappy) {
                    showingSaveSuccess = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                print("❌ Failed to save alarm: \(error)")
            }
        }
    }

    // MARK: - Helper Functions

    private func weekdayShortName(_ weekday: Locale.Weekday) -> String {
        switch weekday {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    private func repeatPatternDescription() -> String {
        let sorted = selectedWeekdays.sorted { weekdayOrder($0) < weekdayOrder($1) }

        if sorted == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Every weekday"
        } else if sorted == [.saturday, .sunday] {
            return "Every weekend"
        } else if sorted.count == 7 {
            return "Every day"
        } else {
            return "Every " + sorted.map { weekdayFullName($0) }.joined(separator: ", ")
        }
    }

    private func weekdayFullName(_ weekday: Locale.Weekday) -> String {
        switch weekday {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    private func weekdayOrder(_ weekday: Locale.Weekday) -> Int {
        switch weekday {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }
}
