import SwiftData
import SwiftUI

struct ScheduleView: View {
    let currentUser: UserAccount

    @Environment(\.modelContext) private var context
    @Query(sort: \UserAccount.username) private var users: [UserAccount]
    @Query private var slots: [DutySlot]
    @Query private var ratings: [RatingRecord]

    @State private var weekStart = WeekCalendar.startOfWeek(for: Date())
    @State private var editor: DutyEditor?
    @State private var ratingTarget: RatingTarget?
    @State private var dishText = ""
    @State private var selectedDay = 1
    @State private var stars = 5
    @State private var comment = ""
    @State private var formError: String?

    private var weekKey: Int { WeekCalendar.weekKey(for: weekStart) }

    private var weekSlots: [DutySlot] {
        slots.filter { $0.weekKey == weekKey }.sorted { $0.weekday < $1.weekday }
    }

    private var mySlot: DutySlot? {
        DutyService.mySlot(weekKey: weekKey, userID: currentUser.userID, in: weekSlots)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KitchenTheme.cream.ignoresSafeArea()
                VStack(spacing: 0) {
                    weekSwitcher
                    myDutyBanner
                    List {
                        ForEach(1...7, id: \.self) { day in
                            dayRow(day: day)
                                .listRowBackground(Color.white)
                                .contentShape(Rectangle())
                                .onTapGesture { handleTap(day: day) }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Дежурства")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Мой день") {
                        openEditor(day: mySlot?.weekday ?? firstFreeDay())
                    }
                }
            }
            .onAppear {
                DutyService.clearPlaceholderWeekIfNeeded(weekKey: weekKey, slots: weekSlots, context: context)
            }
            .sheet(item: $editor) { item in
                dutyEditor(for: item)
            }
            .sheet(item: $ratingTarget) { target in
                ratingSheet(for: target)
            }
        }
    }

    private var weekSwitcher: some View {
        HStack {
            Button {
                weekStart = WeekCalendar.calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
            }

            VStack(spacing: 2) {
                Text(WeekCalendar.formatWeek(weekStart))
                    .font(.headline)
                if weekKey == WeekCalendar.weekKey(for: Date()) {
                    Text("текущая неделя")
                        .font(.caption)
                        .foregroundStyle(KitchenTheme.orange)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                weekStart = WeekCalendar.calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(KitchenTheme.orange)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var myDutyBanner: some View {
        if let mySlot, let dayName = WeekCalendar.weekdayNames[safe: mySlot.weekday - 1] {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "fork.knife")
                    .foregroundStyle(KitchenTheme.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Вы дежурите: \(dayName)")
                        .font(.subheadline.bold())
                    Text(mySlot.dish.isEmpty ? "Добавьте блюдо — его увидят все" : mySlot.dish)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        } else {
            Text("Выберите свободный день и напишите блюдо — остальные увидят ваше дежурство.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func dayRow(day: Int) -> some View {
        let date = WeekCalendar.dayDate(weekStart: weekStart, weekday: day)
        let slot = DutyService.slot(weekKey: weekKey, weekday: day, in: weekSlots)
        let person = users.first { $0.userID == slot?.userID }
        let isToday = WeekCalendar.isSameDay(date, Date())
        let isMine = person?.userID == currentUser.userID
        let dish = slot?.dish.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dayRatings = ratings.filter {
            $0.weekKey == weekKey && $0.weekday == day && $0.toUserID == (person?.userID ?? UUID())
        }
        let average = dayRatings.isEmpty
            ? 0
            : Double(dayRatings.map(\.stars).reduce(0, +)) / Double(dayRatings.count)

        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(WeekCalendar.weekdayShort[day - 1])
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? .white : KitchenTheme.orange)
                Text(dayNumber(date))
                    .font(.headline)
                    .foregroundStyle(isToday ? .white : KitchenTheme.brown)
            }
            .frame(width: 52, height: 52)
            .background(
                isToday ? KitchenTheme.orange : KitchenTheme.cream,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(WeekCalendar.weekdayNames[day - 1])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let person {
                    Text(person.displayName)
                        .font(.headline)
                    Text(dish.isEmpty ? "Блюдо пока не указано" : dish)
                        .font(.subheadline)
                        .foregroundStyle(KitchenTheme.brown)
                    if isMine {
                        Text("Ваше дежурство · нажмите, чтобы изменить")
                            .font(.caption)
                            .foregroundStyle(KitchenTheme.deepOrange)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                            Text(dayRatings.isEmpty ? "нажмите, чтобы оценить" : String(format: "%.1f · %d", average, dayRatings.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Свободно")
                        .font(.headline)
                    Text("Нажмите, чтобы выбрать этот день")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func dutyEditor(for item: DutyEditor) -> some View {
        NavigationStack {
            Form {
                Section("День недели") {
                    if selectableDays.isEmpty {
                        Text("На этой неделе свободных дней нет.")
                    } else {
                        Picker("День", selection: $selectedDay) {
                            ForEach(selectableDays, id: \.self) { day in
                                Text(WeekCalendar.weekdayNames[day - 1]).tag(day)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                Section("Блюдо") {
                    TextField("Например: борщ и пирожки", text: $dishText, axis: .vertical)
                        .lineLimit(2...5)
                    Text("Это блюдо увидят все в расписании.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let formError {
                    Section {
                        Text(formError).foregroundStyle(.red)
                    }
                }
                if mySlot != nil {
                    Section {
                        Button("Снять себя с дежурства", role: .destructive) {
                            try? DutyService.cancelDuty(
                                weekKey: weekKey,
                                userID: currentUser.userID,
                                slots: weekSlots,
                                context: context
                            )
                            editor = nil
                        }
                    }
                }
            }
            .navigationTitle("Моё дежурство")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { editor = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveDuty() }
                }
            }
        }
        .onAppear {
            selectedDay = item.day
            dishText = mySlot?.dish ?? ""
            formError = nil
        }
        .presentationDetents([.medium, .large])
    }

    private func ratingSheet(for target: RatingTarget) -> some View {
        NavigationStack {
            Form {
                Section("Дежурство") {
                    Text(target.person.displayName)
                    Text(WeekCalendar.weekdayNames[target.weekday - 1])
                        .foregroundStyle(.secondary)
                    Text(target.dish.isEmpty ? "Блюдо не указано" : target.dish)
                }
                Section("Ваша оценка") {
                    HStack {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                stars = value
                            } label: {
                                Image(systemName: value <= stars ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    TextField("Комментарий к блюду (необязательно)", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let formError {
                    Section {
                        Text(formError).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Оценить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { ratingTarget = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveRating(target) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func handleTap(day: Int) {
        let slot = DutyService.slot(weekKey: weekKey, weekday: day, in: weekSlots)
        if let slot, let person = users.first(where: { $0.userID == slot.userID }) {
            if person.userID == currentUser.userID {
                openEditor(day: day)
            } else {
                openRating(person: person, weekday: day, dish: slot.dish)
            }
        } else {
            openEditor(day: day)
        }
    }

    private func openEditor(day: Int) {
        selectedDay = day
        dishText = mySlot?.dish ?? ""
        formError = nil
        editor = DutyEditor(day: day)
    }

    private func openRating(person: UserAccount, weekday: Int, dish: String) {
        formError = nil
        if let existing = DutyService.rating(
            from: currentUser.userID,
            to: person.userID,
            weekKey: weekKey,
            weekday: weekday,
            in: ratings
        ) {
            stars = existing.stars
            comment = existing.comment
        } else {
            stars = 5
            comment = ""
        }
        ratingTarget = RatingTarget(person: person, weekday: weekday, dish: dish)
    }

    private func saveDuty() {
        formError = nil
        do {
            try DutyService.saveDuty(
                weekKey: weekKey,
                weekday: selectedDay,
                dish: dishText,
                user: currentUser,
                slots: weekSlots,
                context: context
            )
            editor = nil
        } catch {
            formError = error.localizedDescription
        }
    }

    private func saveRating(_ target: RatingTarget) {
        formError = nil
        do {
            try DutyService.saveRating(
                from: currentUser,
                to: target.person,
                weekKey: weekKey,
                weekday: target.weekday,
                stars: stars,
                comment: comment,
                ratings: ratings,
                context: context
            )
            ratingTarget = nil
        } catch {
            formError = error.localizedDescription
        }
    }

    private var selectableDays: [Int] {
        (1...7).filter { day in
            let taken = DutyService.slot(weekKey: weekKey, weekday: day, in: weekSlots)
            return taken == nil || taken?.userID == currentUser.userID
        }
    }

    private func firstFreeDay() -> Int {
        selectableDays.first ?? 1
    }

    private func dayNumber(_ date: Date) -> String {
        String(WeekCalendar.calendar.component(.day, from: date))
    }
}

private struct DutyEditor: Identifiable {
    let day: Int
    var id: Int { day }
}

private struct RatingTarget: Identifiable {
    let person: UserAccount
    let weekday: Int
    let dish: String
    var id: String { "\(person.userID.uuidString)-\(weekday)" }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
