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
    /// Ce que ferme la croix, dit à VoiceOver et dans l'infobulle.
    var closeLabel = L10n.text(.closeTab)
    /// Nil : pas de croix.
    let onClose: (() -> Void)?

    var body: some View {
        ZStack {
            if isHovered, let onClose {
                CloseButton(label: closeLabel, action: onClose)
            } else if let progress {
                ProgressDot(progress: progress)
            } else if hasActivity {
                Dot(color: nil)
            }
        }
        .frame(width: 20, height: 20)
        // Seule la pastille s'anime. La croix paraît d'un coup au survol, comme dans un
        // navigateur : en fondu, elle se mêlait à la pastille et traînait sous un onglet qui glisse.
        .animation(Ink.feedback, value: hasActivity)
    }

    /// Ce que montre la pastille, en mots : pour l'infobulle de l'onglet et VoiceOver.
    static func text(progress: TerminalProgress?, hasActivity: Bool) -> String? {
        guard let progress else { return hasActivity ? L10n.text(.newActivity) : nil }
        switch progress.state {
        case .error: return L10n.text(.progressError)
        case .pause: return L10n.text(.progressPaused)
        default:
            guard let percent = progress.percent else { return L10n.text(.inProgress) }
            return L10n.text(.inProgressPercent, (Double(percent) / 100).formatted(.percent.locale(L10n.language.locale)))
        }
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
    let label: String
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
        .accessibilityLabel(label)
        .tooltip(label)
        .onHover { isHovered = $0 }
        .animation(Ink.feedback, value: isHovered)
    }
}
