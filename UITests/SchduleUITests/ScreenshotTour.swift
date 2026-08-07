import XCTest

/// Drives the app through its states and photographs each one.
///
/// These run on the simulator rather than through `ImageRenderer` on purpose:
/// `ImageRenderer` cannot reproduce `.glassEffect`, because glass works by
/// sampling the backdrop it is composited over and an offscreen renderer has no
/// backdrop. Any screen with Liquid Glass on it has to be photographed for real.
///
/// Configuration is baked into one test method per combination rather than read
/// from the environment. The first CI round tried `TEST_RUNNER_`-prefixed
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

    private func runTour(language: String, appearance: String) {
        let prefix = "\(language)-\(appearance)"
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestMode",
            "-UITestAppearance", appearance,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "ar" ? "ar_SA" : "en_US",
        ]
        app.launch()

        let grid = app.otherElements["month-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 60), "Month grid never appeared")
        capture(app, named: "\(prefix)-01-habit-board")

        // An anti-habit board: crosses instead of ticks, and a "days clean"
        // streak. Worth its own frame so the two readings sit side by side.
        let tiktok = app.buttons["board-chip-tiktok"]
        XCTAssertTrue(tiktok.waitForExistence(timeout: 10), "TikTok chip missing")
        tiktok.tap()
        capture(app, named: "\(prefix)-02-avoid-board")

        // Scrolled down, the grid passes *under* the floating bar. This is the
        // only frame that proves the glass is really sampling content rather
        // than sitting on flat background and looking like a white pill.
        app.swipeUp()
        capture(app, named: "\(prefix)-03-glass-over-content")

        // An empty month proves the grid still lays out with no data at all.
        let next = app.buttons["month-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10), "Next-month button missing")
        next.tap()
        capture(app, named: "\(prefix)-04-empty-month")
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        // Let animations settle so frames are not caught mid-transition.
        Thread.sleep(forTimeInterval: 1.0)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
