import XCTest

/// Drives the app through its states and photographs each one.
///
/// These run on the simulator rather than through `ImageRenderer` on purpose:
/// `ImageRenderer` cannot reproduce `.glassEffect`, because glass works by
/// sampling the backdrop it is composited over and an offscreen renderer has no
/// backdrop. Any screen with Liquid Glass on it has to be photographed for real.
///
/// Configuration arrives as `TEST_RUNNER_`-prefixed environment variables, which
/// xcodebuild strips the prefix from and forwards into the runner process.
final class ScreenshotTour: XCTestCase {

    private var appearance: String {
        ProcessInfo.processInfo.environment["SCHDULE_APPEARANCE"] ?? "light"
    }

    private var language: String {
        ProcessInfo.processInfo.environment["SCHDULE_LANGUAGE"] ?? "en"
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCaptureTour() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestMode",
            "-UITestAppearance", appearance,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "ar" ? "ar_SA" : "en_US",
        ]
        app.launch()

        let grid = app.otherElements["month-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 30), "Month grid never appeared")

        capture(app, named: "01-month-count-board")

        // The check-style board renders ticks instead of numerals; worth its own
        // frame so the two glyph treatments can be compared side by side.
        let picker = app.scrollViews["board-picker"]
        if picker.waitForExistence(timeout: 5) {
            let firstBoard = picker.buttons.element(boundBy: 0)
            if firstBoard.exists {
                firstBoard.tap()
                capture(app, named: "02-month-check-board")
            }
        }

        // An empty month proves the grid still lays out with no data at all, and
        // that the glass bar re-renders over a nearly blank backdrop.
        let next = app.buttons["month-next"]
        if next.waitForExistence(timeout: 5) {
            next.tap()
            capture(app, named: "03-empty-month")
        }
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        // Let animations settle so frames are not caught mid-transition.
        Thread.sleep(forTimeInterval: 1.0)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(language)-\(appearance)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
