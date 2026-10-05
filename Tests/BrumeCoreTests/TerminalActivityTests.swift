import BrumeCore
import Testing

struct TerminalActivityTests {
    private func finished(_ exitCode: Int?, after seconds: Int = 1) -> TerminalEvent {
        .commandFinished(exitCode: exitCode, duration: .seconds(seconds))
    }

    @Test func failedCommandTurnsTheBadgeRed() {
        #expect(TerminalActivity.after(finished(1), from: nil) == .failed)
        #expect(TerminalActivity.after(finished(130), from: .new) == .failed)
    }

    @Test func successfulCommandMakesItNormalAgain() {
        #expect(TerminalActivity.after(finished(0), from: .failed) == .new)
        #expect(TerminalActivity.after(finished(0), from: nil) == .new)
    }

    @Test func otherEventsKeepAFailure() {
        for event in [TerminalEvent.bell, .progressEnded, .notification(title: "", body: "Waiting"), finished(nil)] {
            #expect(TerminalActivity.after(event, from: .failed) == .failed)
            #expect(TerminalActivity.after(event, from: nil) == .new)
        }
    }

    @Test func groupShowsItsWorstTerminal() {
        #expect([TerminalActivity.new, .failed, .new].max() == .failed)
        #expect([TerminalActivity.new].max() == .new)
    }

    @Test @MainActor func onlyLongCommandsAreNotified() {
        #expect(TerminalNotice(finished(0, after: 9)) == nil)
        #expect(TerminalNotice(finished(0, after: 10))?.body == L10n.text(.commandFinished))
        #expect(TerminalNotice(finished(nil, after: 60))?.body == L10n.text(.commandFinished))
    }

    @Test @MainActor func failureGivesItsExitCode() {
        #expect(TerminalNotice(finished(2, after: 12))?.body == L10n.text(.commandFailedWithCode, "2"))
        #expect(TerminalNotice(finished(2, after: 3)) == nil)
    }

    @Test @MainActor func programNotificationKeepsItsTitleAndText() {
        let notice = TerminalNotice(.notification(title: "Claude Code", body: "Claude is waiting for your input"))
        #expect(notice?.subtitle == "Claude Code")
        #expect(notice?.body == "Claude is waiting for your input")
        #expect(TerminalNotice(.notification(title: "", body: "Done")) == TerminalNotice(.notification(title: "Done", body: "")))
        #expect(TerminalNotice(.notification(title: "", body: "Done"))?.subtitle == "")
        #expect(TerminalNotice(.notification(title: "", body: "")) == nil)
    }

    @Test @MainActor func bellAndProgressAreNotNotified() {
        #expect(TerminalNotice(.bell) == nil)
        #expect(TerminalNotice(.progressEnded) == nil)
    }
}
