import SwiftUI
import SwiftData

struct CalendarDrawerView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    @Binding var isExpanded: Bool

    let allEvents: [DoseEvent]

    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var monthStart: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: monthStart)!.count
    }

    private var firstWeekdayOffset: Int {
        Calendar.current.component(.weekday, from: monthStart) - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main panel — full width white
            VStack(spacing: 0) {
                dateBar

                if isExpanded {
                    VStack(spacing: 6) {
                        monthNav
                        weekdayHeader
                        calendarGrid
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(DDTheme.card)

            // Protruding tab — half-circle folder tab
            drawerTab
        }
    }

    // MARK: - Date bar (collapsed state)

    private var dateBar: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                syncMonthIfNeeded()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text(dateLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DDTheme.textPrimary)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                syncMonthIfNeeded()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today — \(selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))"
        }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    // MARK: - Month navigation

    private var monthNav: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: monthStart)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
            }

            Spacer()

            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.caption.weight(.bold))
                .foregroundStyle(DDTheme.textPrimary)

            Spacer()

            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
            }
        }
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DDTheme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear.aspectRatio(1, contentMode: .fit)
            }
            ForEach(1...daysInMonth, id: \.self) { day in
                let date = Calendar.current.date(byAdding: .day, value: day - 1, to: monthStart)!
                Button {
                    selectedDate = date
                } label: {
                    DayCellView(
                        date: date,
                        events: eventsFor(date),
                        isToday: Calendar.current.isDateInToday(date),
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Protruding folder tab

    private var drawerTab: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DDTheme.textTertiary)
            }
            .frame(width: 80, height: 28)
            .background(DDTheme.card)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 16,
                topTrailingRadius: 0
            ))
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 0
                )
                .strokeBorder(DDTheme.cardBorder, lineWidth: 1)
                // Mask away the top border so it's seamless with the panel
                .mask(
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 1)
                        Color.black
                    }
                )
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func eventsFor(_ date: Date) -> [DoseEvent] {
        allEvents.filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: date) }
    }

    private func syncMonthIfNeeded() {
        let cal = Calendar.current
        let selectedMonth = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate))!
        if selectedMonth != cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))! {
            displayedMonth = selectedMonth
        }
    }
}
