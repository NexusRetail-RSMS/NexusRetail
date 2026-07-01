import SwiftUI

enum StoreChartTimeRange: Equatable {
    case weekly(Date)
    case monthly(Date)
    case yearly(Date)
    
    var rawValue: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        switch self {
        case .weekly(let date):
            return "W:\(formatter.string(from: date))"
        case .monthly(let date):
            return "M:\(formatter.string(from: date))"
        case .yearly(let date):
            return "Y:\(formatter.string(from: date))"
        }
    }
    
    var isWeekly: Bool {
        if case .weekly = self { return true }
        return false
    }
    var isMonthly: Bool {
        if case .monthly = self { return true }
        return false
    }
    var isYearly: Bool {
        if case .yearly = self { return true }
        return false
    }
}

struct SwipeableCalendarView: View {
    @Binding var selectedRange: StoreChartTimeRange

    // Current page offsets — 0 = today/this week/this month/this year
    @State private var weekOffset:  Int = 0
    @State private var monthOffset: Int = 0
    @State private var yearOffset:  Int = 0

    private let calendar = Calendar.current

    // MARK: - Date helpers

    /// Start date of the week at `offset` weeks from today's week
    private func weekStart(offset: Int) -> Date {
        let today = Date()
        let startOfThisWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        return calendar.date(byAdding: .weekOfYear, value: offset, to: startOfThisWeek) ?? today
    }

    /// First day of the month at `offset` months from today's month
    private func monthStart(offset: Int) -> Date {
        let today = Date()
        let startOfThisMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: today)
        ) ?? today
        return calendar.date(byAdding: .month, value: offset, to: startOfThisMonth) ?? today
    }

    /// First day of the year at `offset` years from today's year
    private func yearStart(offset: Int) -> Date {
        let today = Date()
        let startOfThisYear = calendar.date(
            from: calendar.dateComponents([.year], from: today)
        ) ?? today
        return calendar.date(byAdding: .year, value: offset, to: startOfThisYear) ?? today
    }

    /// All 7 dates in the week starting at `weekStart(offset:)`
    private func weekDays(offset: Int) -> [Date] {
        let start = weekStart(offset: offset)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    // MARK: - Navigation

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedRange {
            case .weekly:
                weekOffset -= 1
                selectedRange = .weekly(weekStart(offset: weekOffset))
            case .monthly:
                monthOffset -= 1
                selectedRange = .monthly(monthStart(offset: monthOffset))
            case .yearly:
                yearOffset -= 1
                selectedRange = .yearly(yearStart(offset: yearOffset))
            }
        }
    }

    private func goForward() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedRange {
            case .weekly:
                guard weekOffset < 0 else { return }
                weekOffset += 1
                selectedRange = .weekly(weekStart(offset: weekOffset))
            case .monthly:
                guard monthOffset < 0 else { return }
                monthOffset += 1
                selectedRange = .monthly(monthStart(offset: monthOffset))
            case .yearly:
                guard yearOffset < 0 else { return }
                yearOffset += 1
                selectedRange = .yearly(yearStart(offset: yearOffset))
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(RSMSColors.secondaryText)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Group {
                switch selectedRange {
                case .weekly:  weeklyPager
                case .monthly: monthlyPager
                case .yearly:  yearlyPager
                }
            }

            Button(action: goForward) {
                Image(systemName: "chevron.right")
                    .foregroundColor(canGoForward ? RSMSColors.secondaryText : RSMSColors.secondaryText.opacity(0.3))
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }

    private var canGoForward: Bool {
        switch selectedRange {
        case .weekly:  return weekOffset < 0
        case .monthly: return monthOffset < 0
        case .yearly:  return yearOffset < 0
        }
    }

    // MARK: - Pagers

    /// Weekly: show 7 day buttons, swipe left/right to change week
    private var weeklyPager: some View {
        TabView(selection: $weekOffset) {
            ForEach(-52...0, id: \.self) { offset in
                HStack(spacing: 0) {
                    ForEach(weekDays(offset: offset), id: \.self) { date in
                        VStack(spacing: 3) {
                            Text(dayLetter(date))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(RSMSColors.secondaryText)
                            Text(String(calendar.component(.day, from: date)))
                                .font(.system(size: 15, weight: isToday(date) ? .bold : .regular))
                                .foregroundColor(isToday(date) ? RSMSColors.burgundy : RSMSColors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 52)
        .onChange(of: weekOffset) { _, newOffset in
            selectedRange = .weekly(weekStart(offset: newOffset))
        }
    }

    /// Monthly: one month per page, show month+year label
    private var monthlyPager: some View {
        TabView(selection: $monthOffset) {
            ForEach(-120...0, id: \.self) { offset in
                Text(formattedMonthYear(monthStart(offset: offset)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(RSMSColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 30)
        .onChange(of: monthOffset) { _, newOffset in
            selectedRange = .monthly(monthStart(offset: newOffset))
        }
    }

    /// Yearly: one year per page
    private var yearlyPager: some View {
        TabView(selection: $yearOffset) {
            ForEach(-20...0, id: \.self) { offset in
                Text(formattedYear(yearStart(offset: offset)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(RSMSColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 30)
        .onChange(of: yearOffset) { _, newOffset in
            selectedRange = .yearly(yearStart(offset: newOffset))
        }
    }

    // MARK: - Formatting helpers

    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"   // single-letter day name
        return f.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func formattedMonthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func formattedYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f.string(from: date)
    }
}
