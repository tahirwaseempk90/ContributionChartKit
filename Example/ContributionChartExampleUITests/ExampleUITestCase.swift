import XCTest

/// Shared setup for the example app's UI tests.
///
/// Tests find elements by accessibility identifier and compare positions relative to each
/// other, never against exact coordinates, so they survive different devices and layouts.
@MainActor
class ExampleUITestCase: XCTestCase {
    let timeout: TimeInterval = 15

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    /// Launches directly on a scenario using the app's launch arguments.
    @discardableResult
    func launch(
        scenario: String? = nil,
        appearance: String? = nil,
        arguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var launchArguments = arguments
        if let scenario { launchArguments += ["-scenario", scenario] }
        if let appearance { launchArguments += ["-appearance", appearance] }
        app.launchArguments = launchArguments
        app.launch()
        return app
    }

    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Waits for an element to appear, and fails the test if it does not.
    @discardableResult
    func require(
        _ identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let found = element(identifier, in: app)
        XCTAssertTrue(found.waitForExistence(timeout: timeout), "Missing element \(identifier)", file: file, line: line)
        return found
    }

    /// Activates a control. On macOS a tap doesn't select a sidebar row, so this clicks instead.
    func press(_ target: XCUIElement) {
        #if os(macOS)
        target.click()
        #else
        target.tap()
        #endif
    }

    /// Chooses a segment of a segmented picker, which macOS exposes as radio buttons.
    func selectSegment(_ name: String, of picker: XCUIElement) {
        #if os(macOS)
        picker.radioButtons[name].click()
        #else
        picker.buttons[name].tap()
        #endif
    }

    /// Scrolls until an element is on screen. Elements in a `ScrollView` exist while they are off
    /// screen, but only on-screen ones can be compared to the visible frame. On macOS, a `List`
    /// doesn't create its rows at all until they are near the visible area.
    func scrollIntoView(
        _ target: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 20
    ) {
        #if os(macOS)
        let page = app.scrollViews.containing(.any, identifier: "chart.responsive.resizable").firstMatch
        let scrollView = page.exists ? page : app.scrollViews.element(boundBy: app.scrollViews.count - 1)
        for _ in 0..<maximumSwipes where !(target.exists && target.isHittable) {
            scrollView.scroll(byDeltaX: 0, deltaY: -250)
        }
        #else
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<maximumSwipes where !target.isHittable {
            scrollView.swipeUp(velocity: .slow)
        }
        #endif
    }

    /// Attaches a screenshot of the app. On macOS this is only the app's window, because a
    /// screenshot of the screen would capture whatever else is open on the machine, and result
    /// bundles can get uploaded.
    func attachScreenshot(named name: String, of app: XCUIApplication = XCUIApplication()) {
        #if os(macOS)
        let screenshot = app.windows.firstMatch.screenshot()
        #else
        let screenshot = XCUIScreen.main.screenshot()
        #endif
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
