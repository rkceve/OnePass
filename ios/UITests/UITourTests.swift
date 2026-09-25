// UI tour for the screen recording in .github/workflows/tour.yml (not a functional test suite).
// Walks every built screen of the OnePass app at a watchable pace using the in-memory
// fixtures behind the DEBUG-only `-OnePassTourFixtures` launch argument (ios/App/TourFixtures.swift).
//
// Runs only when the test runner has ONEPASS_TOUR=1 (xcodebuild strips the TEST_RUNNER_ prefix,
// so the workflow sets TEST_RUNNER_ONEPASS_TOUR=1). The OnePass app must already be installed
// on the simulator: this bundle's target application is OnePassProbe.
import XCTest

@MainActor
final class UITourTests: XCTestCase {
    /// Pause between steps so motion is visible in the recording.
    private let pace: TimeInterval = 1.2
    private var step = 0

    func testTour() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["ONEPASS_TOUR"] == "1",
            "UI tour runs only from the tour workflow (TEST_RUNNER_ONEPASS_TOUR=1)"
        )
        continueAfterFailure = false

        let app = XCUIApplication(bundleIdentifier: "io.github.rkceve.onepass")
        app.launchArguments = ["-OnePassTourFixtures"]
        app.launch()

        // Home list.
        let addButton = app.buttons["accounts.add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 30), "Home screen did not appear")
        pause("home")

        // Expand info@myshop.jp and show the server rows.
        let info = "info@myshop.jp"
        let infoExpand = app.buttons["account.\(info).expand"]
        XCTAssertTrue(infoExpand.waitForExistence(timeout: 10))
        infoExpand.tap()
        let reveal = app.buttons["account.\(info).password.reveal"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 10), "server rows did not appear")
        pause("info-expanded")

        // Reveal the password.
        reveal.tap()
        pause("password-revealed")

        // Collapse.
        infoExpand.tap()
        XCTAssertTrue(reveal.waitForNonExistence(timeout: 10))
        pause("info-collapsed")

        // Add: the sheet morphs out of the glass Add button.
        addButton.tap()
        let email = app.textFields["accountForm.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 10), "add sheet did not appear")
        pause("add-sheet")

        email.tap()
        email.typeText("hello@studio.co")
        pause("email-typed")

        tapWhenEnabled(app.buttons["accountForm.continue"])

        // IMAP form.
        let host = app.textFields["accountForm.host"]
        XCTAssertTrue(host.waitForExistence(timeout: 10), "IMAP form did not appear")
        pause("imap-form")

        host.tap()
        host.typeText("mail.studio.co")

        let port = app.textFields["accountForm.port"]
        port.tap()
        replaceText(in: port, with: "993")

        let username = app.textFields["accountForm.username"]
        username.tap()
        replaceText(in: username, with: "hello@studio.co")

        let password = app.secureTextFields["accountForm.password"]
        password.tap()
        password.typeText("tour-pass-123")
        pause("imap-filled")

        // Save: the new card appears.
        tapWhenEnabled(app.buttons["accountForm.save"])
        let newAddress = "hello@studio.co"
        let newExpand = app.buttons["account.\(newAddress).expand"]
        XCTAssertTrue(newExpand.waitForExistence(timeout: 10), "new account card did not appear")
        XCTAssertTrue(host.waitForNonExistence(timeout: 10), "sheet did not close")
        pause("new-card")

        // Expand it.
        if !newExpand.isHittable { app.swipeUp() }
        newExpand.tap()
        let delete = app.buttons["account.\(newAddress).delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 10))
        if !delete.isHittable { app.swipeUp() }
        pause("new-card-expanded")

        // Delete and confirm.
        delete.tap()
        let confirm = confirmDeleteButton(in: app, address: newAddress)
        XCTAssertTrue(confirm.waitForExistence(timeout: 10), "delete confirmation did not appear")
        pause("delete-confirm")
        confirm.tap()
        XCTAssertTrue(newExpand.waitForNonExistence(timeout: 10), "card was not deleted")
        pause("deleted")

        // Gear (no-op).
        let settings = app.buttons["header.settings"]
        if !settings.isHittable { app.swipeDown() }
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        pause("settings-tapped")

        // Plan tab.
        tabButton(in: app, label: "Plan").tap()
        let pro = app.buttons["plan.pro"]
        XCTAssertTrue(pro.waitForExistence(timeout: 10), "Plan screen did not appear")
        pause("plan")

        pro.tap()
        pause("pro-tapped")

        // Back to Home.
        tabButton(in: app, label: "Home").tap()
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        pause("home-again")
    }

    // MARK: Helpers

    /// Waits `pace`, then attaches a screenshot named after the step.
    private func pause(_ name: String) {
        Thread.sleep(forTimeInterval: pace)
        step += 1
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = String(format: "%02d-%@", step, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapWhenEnabled(_ button: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "\(button) missing")
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: button)
        wait(for: [enabled], timeout: timeout)
        button.tap()
    }

    /// Clears a focused text field and types `text`.
    private func replaceText(in field: XCUIElement, with text: String) {
        let current = field.value as? String ?? ""
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
        field.typeText(deletes + text)
    }

    /// The confirmation dialog's Delete button. SwiftUI may not carry the identifier into the
    /// system dialog, so fall back to the "Delete" button that is not the card's own.
    private func confirmDeleteButton(in app: XCUIApplication, address: String) -> XCUIElement {
        let byID = app.buttons["account.\(address).delete.confirm"]
        if byID.waitForExistence(timeout: 3) { return byID }
        let predicate = NSPredicate(
            format: "label == %@ AND identifier != %@",
            "Delete",
            "account.\(address).delete"
        )
        return app.buttons.matching(predicate).firstMatch
    }

    private func tabButton(in app: XCUIApplication, label: String) -> XCUIElement {
        let inTabBar = app.tabBars.buttons[label]
        if inTabBar.waitForExistence(timeout: 3) { return inTabBar }
        return app.buttons[label].firstMatch
    }
}
