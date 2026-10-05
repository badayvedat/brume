import BrumeCore
import Testing

struct SecureInputGateTests {
    @Test func turnsOnOnceWhileATerminalAsks() {
        var gate = SecureInputGate<Int>(isAppActive: true)
        #expect(gate.set(1, isAsking: true) == .enable)
        #expect(gate.set(1, isAsking: true) == nil)
        #expect(gate.set(2, isAsking: true) == nil)
        #expect(gate.secured == [1, 2])
        #expect(gate.set(1, isAsking: false) == nil)
        #expect(gate.set(2, isAsking: false) == .disable)
        #expect(gate.set(2, isAsking: false) == nil)
        #expect(gate.secured.isEmpty)
    }

    @Test func onlyWhileBrumeIsInFront() {
        var gate = SecureInputGate<Int>(isAppActive: false)
        #expect(gate.set(1, isAsking: true) == nil)
        #expect(gate.secured.isEmpty)
        #expect(gate.setAppActive(true) == .enable)
        #expect(gate.secured == [1])
        #expect(gate.setAppActive(true) == nil)
        #expect(gate.setAppActive(false) == .disable)
        #expect(gate.setAppActive(false) == nil)
    }

    @Test func quittingTurnsItOff() {
        var gate = SecureInputGate<Int>(isAppActive: true)
        #expect(gate.removeAll() == nil)
        _ = gate.set(1, isAsking: true)
        #expect(gate.removeAll() == .disable)
        #expect(!gate.isEnabled)
    }

    /// macOS compte les appels : jamais deux activations de suite, et tout se referme.
    @Test func callsStayBalanced() {
        var gate = SecureInputGate<Int>(isAppActive: false)
        var generator = SystemRandomNumberGenerator()
        var count = 0
        for _ in 0 ..< 10000 {
            let change: SecureInputGate<Int>.Switch? = switch Int.random(in: 0 ..< 3, using: &generator) {
            case 0: gate.setAppActive(.random(using: &generator))
            case 1: gate.set(.random(in: 0 ..< 4, using: &generator), isAsking: .random(using: &generator))
            default: gate.set(.random(in: 0 ..< 4, using: &generator), isAsking: false)
            }
            switch change {
            case .enable: count += 1
            case .disable: count -= 1
            case nil: break
            }
            #expect(count == (gate.isEnabled ? 1 : 0))
        }
        if gate.removeAll() == .disable { count -= 1 }
        #expect(count == 0)
    }
}
