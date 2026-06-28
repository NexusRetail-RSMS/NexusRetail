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
    
    @State private var selectedWeekOffset: Int = 0
    @State private var selectedMonthOffset: Int = 0
    @State private var selectedYearOffset: Int = 0
    
    func week(offset: Int) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let targetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfWeek) else {
            return []
        }
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetStart)
        }
    }
    
    func months(offset: Int) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let monthComponent = calendar.component(.month, from: today)
        let isSecondHalf = monthComponent > 6
        
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)),
              let targetStart = calendar.date(byAdding: .month, value: (isSecondHalf ? 6 : 0) + (offset * 6), to: startOfYear) else {
            return []
        }
        return (0..<6).compactMap { mOffset in
            calendar.date(byAdding: .month, value: mOffset, to: targetStart)
        }
    }
    
    func years(offset: Int) -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)),
              let targetStart = calendar.date(byAdding: .year, value: offset * 5, to: startOfYear) else {
            return []
        }
        return (0..<5).compactMap { yOffset in
            calendar.date(byAdding: .year, value: yOffset, to: targetStart)
        }
    }
    
    private func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if case .weekly = selectedRange {
                selectedWeekOffset -= 1
            } else if case .monthly = selectedRange {
                selectedMonthOffset -= 1
            } else {
                selectedYearOffset -= 1
            }
        }
    }
    
    private func goForward() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if case .weekly = selectedRange {
                if selectedWeekOffset < 0 { selectedWeekOffset += 1 }
            } else if case .monthly = selectedRange {
                if selectedMonthOffset < 0 { selectedMonthOffset += 1 }
            } else {
                if selectedYearOffset < 0 { selectedYearOffset += 1 }
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Left chevron — tappable button
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(RSMSColors.secondaryText)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Group {
                if case .weekly(_) = selectedRange {
                    weeklyPager
                } else if case .monthly(_) = selectedRange {
                    monthlyPager
                } else {
                    yearlyPager
                }
            }
            
            // Right chevron — tappable button
            Button(action: goForward) {
                Image(systemName: "chevron.right")
                    .foregroundColor(RSMSColors.secondaryText)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .background(Color.clear)
    }
    
    private var weeklyPager: some View {
        TabView(selection: $selectedWeekOffset) {
            ForEach(-50...0, id: \.self) { offset in
                VStack(spacing: 10) {
                    // Day name headers inside TabView so they swipe too
                    HStack {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(RSMSColors.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    HStack {
                        ForEach(week(offset: offset), id: \.self) { date in
                            Text(String(Calendar.current.component(.day, from: date)))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(RSMSColors.primaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 55)
        .onChange(of: selectedWeekOffset) { _, newOffset in
            if let targetDate = week(offset: newOffset).first {
                selectedRange = .weekly(targetDate)
            }
        }
    }
    
    private var monthlyPager: some View {
        TabView(selection: $selectedMonthOffset) {
            ForEach(-50...0, id: \.self) { offset in
                HStack {
                    ForEach(months(offset: offset), id: \.self) { date in
                        Text(formattedMonth(date))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(RSMSColors.primaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 30)
        .onChange(of: selectedMonthOffset) { _, newOffset in
            if let targetDate = months(offset: newOffset).first {
                selectedRange = .monthly(targetDate)
            }
        }
    }
    
    private var yearlyPager: some View {
        TabView(selection: $selectedYearOffset) {
            ForEach(-20...0, id: \.self) { offset in
                HStack {
                    ForEach(years(offset: offset), id: \.self) { date in
                        Text(formattedYear(date))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(RSMSColors.primaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 30)
        .onChange(of: selectedYearOffset) { _, newOffset in
            if let targetDate = years(offset: newOffset).first {
                selectedRange = .yearly(targetDate)
            }
        }
    }
    
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formattedYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}
