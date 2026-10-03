import BrumeCore
import GhosttyTerminal
import SwiftUI

/// À droite d'un onglet : la croix au survol, sinon une pastille. Elle respire tant que le
/// programme annonce une progression (Claude Code qui travaille), se remplit en anneau s'il donne
/// un pourcentage, et reste pleine quand il s'est passé quelque chose dans l'onglet caché.
struct TabStatus: View {
    let isHovered: Bool
    let progress: TerminalProgress?
    let hasActivity: Bool
    let onClose: () -> Void

    var body: some View {
        ZStack {
            if isHovered {
                CloseButton(action: onClose)
            } else if let progress {
                ProgressDot(progress: progress)
            } else if hasActivity {
                Dot(color: nil)
            }
        }
        .frame(width: 20, height: 20)
        .animation(Ink.feedback, value: isHovered)
        .animation(Ink.feedback, value: hasActivity)
        .animation(Ink.feedback, value: progress == nil)
    }
}

private struct Dot: View {
    /// Nil : la couleur d'accent.
    let color: Color?

    @Environment(\.accent) private var accent

    var body: some View {
        Circle().fill(color ?? accent.color).frame(width: 7, height: 7)
    }
}

private struct ProgressDot: View {
    let progress: TerminalProgress

    @State private var isDim = false
    @Environment(\.accent) private var accent

    var body: some View {
        switch progress.state {
        case .error:
            Dot(color: Ink.warning)
        case .pause:
            Dot(color: Ink.muted)
        default:
            if let percent = progress.percent {
                ZStack {
                    Circle().stroke(Ink.border, lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(percent, 0), 100)) / 100)
                        .stroke(accent.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(Ink.slide, value: percent)
                }
                .frame(width: 10, height: 10)
            } else {
                Dot(color: nil)
                    .opacity(isDim ? 0.3 : 1)
                    .onAppear {
                        // Sans animation (« Réduire les animations »), la pastille reste pleine.
                        if let breathe = Ink.motion(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            withAnimation(breathe) { isDim = true }
                        }
                    }
            }
        }
    }
}

private struct CloseButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("xmark", size: 9, weight: .bold)
                .foregroundStyle(isHovered ? Ink.text : Ink.muted)
                .frame(width: 20, height: 20)
                .background(isHovered ? Ink.selection : .clear, in: .rect(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.closeTab))
        .tooltip(L10n.text(.closeTab))
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }
}
