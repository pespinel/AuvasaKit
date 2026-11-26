import Foundation
import XCTest
@testable import AuvasaKit

final class CalendarTests: XCTestCase {
    /// Closure (not a func) so the return type is inferred:
    /// `Calendar` is ambiguous with Foundation's in type position.
    private let makeService = { (allDays: Bool, startDate: String, endDate: String) in
        Calendar(
            id: "SERVICE",
            monday: allDays,
            tuesday: allDays,
            wednesday: allDays,
            thursday: allDays,
            friday: allDays,
            saturday: allDays,
            sunday: allDays,
            startDate: startDate,
            endDate: endDate
        )
    }

    func testActiveDaysAllDays() {
        let service = makeService(true, "20260101", "20261231")

        XCTAssertEqual(
            service.activeDays,
            ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        )
    }

    func testActiveDaysNoDays() {
        XCTAssertTrue(makeService(false, "20260101", "20261231").activeDays.isEmpty)
    }

    func testActiveDaysWeekdaysOnly() {
        let service = Calendar(
            id: "WEEKDAYS",
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
            sunday: false,
            startDate: "20260101",
            endDate: "20261231"
        )

        XCTAssertEqual(service.activeDays, ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
    }

    func testRunsOnWeekday() {
        let service = makeService(true, "20260101", "20261231")

        for weekday in 1...7 {
            XCTAssertTrue(service.runsOn(weekday: weekday))
        }
        XCTAssertFalse(service.runsOn(weekday: 0))
        XCTAssertFalse(service.runsOn(weekday: 8))
    }

    func testRunsOnDateWithinRange() throws {
        let service = makeService(true, "20260101", "20261231")

        XCTAssertTrue(try service.runsOn(date: date("20260615")))
        XCTAssertFalse(try service.runsOn(date: date("20270101")))
    }

    func testRunsOnDateInactiveWeekday() throws {
        let service = makeService(false, "20260101", "20261231")

        XCTAssertFalse(try service.runsOn(date: date("20260615")))
    }

    private func date(_ string: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return try XCTUnwrap(formatter.date(from: string))
    }
}
