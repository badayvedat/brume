import BrumeCore
import Testing

struct InheritedEnvironmentTests {
    @Test func claudeCodeVariablesAreExcluded() {
        let names = ["CLAUDECODE", "CLAUDE_CODE_CHILD_SESSION", "CLAUDE_CODE_SESSION_ID"]
        #expect(InheritedEnvironment.excluded(from: names) == names)
    }

    @Test func otherVariablesAreKept() {
        let names = ["PATH", "LANG", "TERM", "CLAUDE_CONFIG_DIR", "MY_CLAUDECODE", "CLAUDECODE_X"]
        #expect(InheritedEnvironment.excluded(from: names).isEmpty)
    }
}
