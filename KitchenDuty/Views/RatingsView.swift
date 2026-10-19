import SwiftData
import SwiftUI

struct RatingsView: View {
    let currentUser: UserAccount

    @Environment(\.modelContext) private var context
    @Query(sort: \UserAccount.displayName) private var users: [UserAccount]
    @Query(sort: \RatingRecord.createdAt, order: .reverse) private var ratings: [RatingRecord]
    @Query private var slots: [DutySlot]

    @State private var selectedSlot: DutySlot?
    @State private var stars = 5
    @State private var comment = ""
    @State private var saveError: String?

    private var thisWeek: Int {
        WeekCalendar.weekKey(for: Date())
    }

    private var visibleDuties: [DutySlot] {
        slots
            .filter { $0.weekKey == thisWeek && $0.userID != currentUser.userID }
            .sorted { $0.weekday < $1.weekday }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KitchenTheme.cream.ignoresSafeArea()
                Group {
                    if visibleDuties.isEmpty {
                        ContentUnavailableView(
                            "Пока некого оценивать",
                            systemImage: "fork.knife",
                            description: Text("Когда кто-то выберет день и напишет блюдо, вы увидите это здесь.")
                        )
                    } else {
                        List(visibleDuties, id: \.slotID) { slot in
                            Button {
                                openRating(for: slot)
                            } label: {
                                dutyRow(slot)
                            }
                            .listRowBackground(Color.white)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Оценки")
            .sheet(isPresented: Binding(
                get: { selectedSlot != nil },
                set: { if !$0 { selectedSlot = nil } }
            )) {
                if let selectedSlot, let person = users.first(where: { $0.userID == selectedSlot.userID }) {
                    ratingSheet(slot: selectedSlot, person: person)
                }
            }
        }
    }

    private func dutyRow(_ slot: DutySlot) -> some View {
        let person = users.first { $0.userID == slot.userID }
        let received = ratings.filter {
            $0.toUserID == slot.userID && $0.weekKey == thisWeek && $0.weekday == slot.weekday
        }
        let average = received.isEmpty ? 0 : Double(received.map(\.stars).reduce(0, +)) / Double(received.count)
        let mine = DutyService.rating(
            from: currentUser.userID,
            to: slot.userID,
            weekKey: thisWeek,
            weekday: slot.weekday,
            in: ratings
        )
        let dish = slot.dish.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .top, spacing: 12) {
            avatar(person?.displayName ?? "?")
            VStack(alignment: .leading, spacing: 4) {
                Text(person?.displayName ?? "Дежурный")
                    .font(.headline)
                    .foregroundStyle(KitchenTheme.brown)
                Text(WeekCalendar.weekdayNames[slot.weekday - 1])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dish.isEmpty ? "Блюдо не указано" : dish)
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(received.isEmpty ? "нет оценок" : String(format: "%.1f · %d", average, received.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(mine == nil ? "Оценить" : "\(mine?.stars ?? 0) ★")
                    .font(.subheadline.bold())
                    .foregroundStyle(KitchenTheme.orange)
                Text("блюдо")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func ratingSheet(slot: DutySlot, person: UserAccount) -> some View {
        NavigationStack {
            Form {
                Section("Дежурство") {
                    Text(person.displayName)
                    Text(WeekCalendar.weekdayNames[slot.weekday - 1])
                        .foregroundStyle(.secondary)
                    Text(slot.dish.isEmpty ? "Блюдо не указано" : slot.dish)
                }
                Section("Оценка блюда") {
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
                    TextField("Комментарий (необязательно)", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let saveError {
                    Section {
                        Text(saveError).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Оценить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { selectedSlot = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save(slot: slot, person: person) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func openRating(for slot: DutySlot) {
        selectedSlot = slot
        saveError = nil
        if let existing = DutyService.rating(
            from: currentUser.userID,
            to: slot.userID,
            weekKey: thisWeek,
            weekday: slot.weekday,
            in: ratings
        ) {
            stars = existing.stars
            comment = existing.comment
        } else {
            stars = 5
            comment = ""
        }
    }

    private func save(slot: DutySlot, person: UserAccount) {
        saveError = nil
        do {
            try DutyService.saveRating(
                from: currentUser,
                to: person,
                weekKey: thisWeek,
                weekday: slot.weekday,
                stars: stars,
                comment: comment,
                ratings: ratings,
                context: context
            )
            selectedSlot = nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func avatar(_ name: String) -> some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(KitchenTheme.orange, in: Circle())
    }
}
