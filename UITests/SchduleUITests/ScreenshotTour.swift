import XCTest

/// Drives the app through its states and photographs each one.
///
/// These run on the simulator rather than through `ImageRenderer` on purpose:
/// `ImageRenderer` cannot reproduce `.glassEffect`, because glass works by
/// sampling the backdrop it is composited over and an offscreen renderer has no
/// backdrop. Any screen with Liquid Glass on it has to be photographed for real.
///
/// Configuration is baked into one test method per combination rather than read
/// from the environment. An earlier round tried `TEST_RUNNER_`-prefixed
/// variables; they never reached the runner process, and both matrix legs
/// silently produced identical English screenshots — a failure mode that looks
/// exactly like success until you read the filenames.
final class ScreenshotTour: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTourArabicDark() { runTour(language: "ar", appearance: "dark") }
    func testTourArabicLight() { runTour(language: "ar", appearance: "light") }
    func testTourEnglishDark() { runTour(language: "en", appearance: "dark") }
    func testTourEnglishLight() { runTour(language: "en", appearance: "light") }

    // MARK: - Tour

    private func runTour(language: String, appearance: String) {
        let prefix = "\(language)-\(appearance)"
        let app = launch(language: language, appearance: appearance)

        // 1. Today — the screen the app opens to and the one used most.
        let today = app.collectionViews["today-list"]
        XCTAssertTrue(today.waitForExistence(timeout: 90), "Today list never appeared")
        capture(app, named: "\(prefix)-01-today")

        // 2. The day editor, reached by tapping a row. This is where a forgotten
        //    Tuesday or an eleven-times day gets fixed.
        //
        //    `.firstMatch` rather than a plain subscript: an accessibility
        //    identifier set on a composite row propagates to its descendants, so
        //    the query resolves to several elements and tapping the subscript
        //    fails with "Multiple matching elements found".
        let row = app.descendants(matching: .any)
            .matching(identifier: "today-row-TikTok")
            .firstMatch
        if row.waitForExistence(timeout: 10) {
            row.tap()
            let done = app.buttons["day-editor-done"].firstMatch
            if done.waitForExistence(timeout: 10) {
                capture(app, named: "\(prefix)-02-day-editor")
                done.tap()
            }
        }

        // 3. Boards — the Notes-style folder browser.
        tapTab(app, index: 1)
        XCTAssertTrue(
            app.descendants(matching: .any)["board-list"].waitForExistence(timeout: 15),
            "Board list never appeared"
        )
        capture(app, named: "\(prefix)-03-boards")

        // 4. A board's month, with the glass bar over real content.
        let firstBoard = app.collectionViews["board-list"].cells.firstMatch
        if firstBoard.waitForExistence(timeout: 10) {
            firstBoard.tap()
            if app.otherElements["month-grid"].waitForExistence(timeout: 15) {
                capture(app, named: "\(prefix)-04-board-month")
                app.swipeUp()
                capture(app, named: "\(prefix)-05-glass-over-content")
            }
        }

        // 5. Insights.
        tapTab(app, index: 2)
        let insights = app.descendants(matching: .any)
            .matching(identifier: "insights")
            .firstMatch
        if insights.waitForExistence(timeout: 15) {
            capture(app, named: "\(prefix)-06-insights")
        }

        // 6. Settings, which is also where the privacy claims are made in words.
        tapTab(app, index: 0)
        let settings = app.buttons["open-settings"].firstMatch
        if settings.waitForExistence(timeout: 10) {
            settings.tap()
            let form = app.descendants(matching: .any)
                .matching(identifier: "settings")
                .firstMatch
            if form.waitForExistence(timeout: 10) {
                capture(app, named: "\(prefix)-07-settings")
            }
        }
    }

    /// The locked-board state, which needs biometrics to be refused rather than
    /// granted, so it gets its own launch.
    func testLockedBoardEnglishDark() {
        let app = launch(language: "en", appearance: "dark", denyBiometrics: true)
        XCTAssertTrue(app.collectionViews["today-list"].waitForExistence(timeout: 90))

        tapTab(app, index: 1)
        guard app.collectionViews["board-list"].waitForExistence(timeout: 15) else { return }

        let locked = app.collectionViews["board-list"].cells.containing(
            .staticText, identifier: "Smoking"
        ).firstMatch
        if locked.waitForExistence(timeout: 10) {
            locked.tap()
            let state = app.descendants(matching: .any)
                .matching(identifier: "locked-state")
                .firstMatch
            if state.waitForExistence(timeout: 10) {
                capture(app, named: "en-dark-08-locked-board")
            }
        }
    }

    // MARK: - Helpers

    private func launch(
        language: String,
        appearance: String,
        denyBiometrics: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = [
            "-UITestMode",
            "-UITestAppearance", appearance,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "ar" ? "ar_SA" : "en_US",
        ]
        if denyBiometrics { arguments.append("-UITestDenyBiometrics") }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    /// Tab bars mirror under RTL, so tabs are picked by position in the
    /// accessibility tree rather than by screen coordinates or localized title.
    private func tapTab(_ app: XCUIApplication, index: Int) {
        let bar = app.tabBars.firstMatch
        guard bar.waitForExistence(timeout: 15) else { return }
        let button = bar.buttons.element(boundBy: index)
        if button.exists { button.tap() }
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        // Let animations settle so frames are not caught mid-transition.
        Thread.sleep(forTimeInterval: 1.2)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
