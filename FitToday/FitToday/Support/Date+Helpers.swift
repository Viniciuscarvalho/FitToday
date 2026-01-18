//
//  Date+Helpers.swift
//  FitToday
//
//  Created by Claude on 18/01/26.
//

import Foundation

extension Date {
    /// Returns the start of the week (Monday at 00:00:00) for the current date.
    /// Uses the user's current calendar and timezone.
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2 (Sunday = 1)

        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the start of the month (1st day at 00:00:00) for the current date.
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the start of the day (00:00:00) for the current date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns true if this date is on the same day as the other date.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Returns true if this date is yesterday relative to the other date.
    func isYesterday(relativeTo other: Date) -> Bool {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: other.startOfDay) else {
            return false
        }
        return calendar.isDate(self, inSameDayAs: yesterday)
    }

    /// Returns the number of days between this date and another date.
    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }
}
