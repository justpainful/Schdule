import Foundation
import Testing
import UserNotifications
import SchduleModel
import SchduleStore

private let boardID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

private func request(
    kind: ReminderRequest.Kind,
    hour: Int = 20,
    weekdays: Set<Int> = [],
    isInverted: Bool = false
) -> ReminderRequest {
    ReminderRequest(
        boardID: boardID,
        boardName: "Workout",
        kind: kind,
        hour: hour,
        weekdays: weekdays,
        isInverted: isInverted
    )
}

@Suite("Reminder triggers")
struct ReminderTriggerTests {

    @Test("No weekdays means one daily trigger")
    func everyDay() {
        let triggers = ReminderBuilder.triggers(for: request(kind: .daily))
        #expect(triggers.count == 1)
        #expect(triggers[0].dateComponents.hour == 20)
        #expect(triggers[0].dateComponents.weekday == nil)
        #expect(triggers[0].repeats)
    }

    @Test("Selected weekdays become one trigger each")
    func perWeekday() {
        // UNCalendarNotificationTrigger matches a single set of components, so
        // "Mondays and Thursdays" is two triggers rather than one with two.
        let triggers = ReminderBuilder.triggers(for: request(kind: .daily, weekdays: [2, 5]))
        #expect(triggers.count == 2)
        #expect(triggers.compactMap(\.dateComponents.weekday).sorted() == [2, 5])
    }

    @Test("The recap fires on the first of the month, not on a weekday")
    func monthlyRecap() {
        let triggers = ReminderBuilder.triggers(for: request(kind: .monthlyRecap, hour: 9))
        #expect(triggers.count == 1)
        #expect(triggers[0].dateComponents.day == 1)
        #expect(triggers[0].dateComponents.hour == 9)
        #expect(triggers[0].dateComponents.weekday == nil)
    }

    @Test("Every request gets a unique identifier per trigger")
    func uniqueIdentifiers() {
        let requests = ReminderBuilder.requests(for: request(kind: .daily, weekdays: [1, 3, 6]))
        #expect(Set(requests.map(\.identifier)).count == 3)
        #expect(requests.allSatisfy { $0.identifier.hasPrefix(boardID.uuidString) })
    }
}

@Suite("Reminder content")
struct ReminderContentTests {

    @Test("Reminders stay at the active level so a Focus is never pierced")
    func interruptionLevel() {
        for kind in [ReminderRequest.Kind.daily, .streakAtRisk, .monthlyRecap] {
            let content = ReminderBuilder.content(for: request(kind: kind))
            #expect(content.interruptionLevel == .active)
        }
    }

    @Test("An anti-habit is worded differently from a habit")
    func polarityWording() {
        let habit = ReminderBuilder.content(for: request(kind: .daily, isInverted: false))
        let avoid = ReminderBuilder.content(for: request(kind: .daily, isInverted: true))
        #expect(habit.body != avoid.body)
    }

    @Test("The board id rides along so the action knows what to log")
    func carriesBoardID() {
        let content = ReminderBuilder.content(for: request(kind: .daily))
        #expect(content.userInfo["boardID"] as? String == boardID.uuidString)
    }

    @Test("The recap is silent; nobody needs a chime on the first of the month")
    func recapIsSilent() {
        let content = ReminderBuilder.content(for: request(kind: .monthlyRecap))
        #expect(content.sound == nil)
    }

    @Test("The category offers logging and skipping straight from the banner")
    func categoryActions() {
        let identifiers = ReminderBuilder.category.actions.map(\.identifier)
        #expect(identifiers.contains(ReminderBuilder.Action.log))
        #expect(identifiers.contains(ReminderBuilder.Action.skip))
    }
}
