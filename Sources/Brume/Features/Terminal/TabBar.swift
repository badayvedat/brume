import BrumeCore
import GhosttyTerminal
import SwiftUI

/// Barre d'onglets maison, à la place de la barre de titre, comme Muxy : onglets
/// arrondis, à côté des boutons de la fenêtre.
struct TabBar: View {
    let tabs: TerminalTabs

    @State private var titlebar = WindowTitlebar()

    private let spacing: CGFloat = 4
    private let tabWidth: ClosedRange<CGFloat> = 110 ... 220

    var body: some View {
        GeometryReader { geometry in
            let width = cellWidth(available: geometry.size.width)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(tabs.tabs) { workspace in
                        TabCell(
                            state: workspace.focused,
                            isSelected: workspace === tabs.selected,
                            onSelect: { tabs.select(workspace.id) },
                            onClose: { tabs.close(workspace.id) }
                        )
                        .frame(width: width)
                    }
                    BarButton(icon: "plus", label: "\(L10n.text(.newTab)) (⌘T)", action: tabs.newTab)
                }
                .frame(maxHeight: .infinity)
                .frame(minWidth: geometry.size.width, alignment: .leading)
                .background(WindowDragArea())
            }
        }
        .padding(.leading, titlebar.isFullScreen ? 8 : titlebar.buttonsWidth + 14)
        .padding(.trailing, 8)
        .frame(height: titlebar.buttonsCenterY * 2)
        .background(WindowDragArea())
        .background(WindowReader { titlebar.attach(to: $0) })
    }

    /// Parts égales, sans dépasser `tabWidth` : au-delà, la barre défile.
    private func cellWidth(available: CGFloat) -> CGFloat {
        let count = CGFloat(tabs.tabs.count)
        let free = available - BarButton.size - spacing * count
        return min(max(free / count, tabWidth.lowerBound), tabWidth.upperBound)
    }
}

private struct TabCell: View {
    @ObservedObject var state: TerminalViewState
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)
            CloseButton(action: onClose)
                .opacity(isSelected || isHovered ? 1 : 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .frame(height: 26)
        // Le trait d'accent court sur toute la largeur et suit l'arrondi des coins.
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                background
                if isSelected {
                    Color.accentColor.frame(height: 2)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
        }
        .contentShape(.rect(cornerRadius: 8))
        .onTapGesture(perform: onSelect)
        .accessibilityAction(.default, onSelect)
        .onHover { isHovered = $0 }
        .help(title)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: L10n.text(.closeTab), onClose)
    }

    private var title: String {
        state.title.isEmpty ? L10n.text(.terminal) : state.title
    }

    private var background: Color {
        if isSelected { return .primary.opacity(0.12) }
        return isHovered ? .primary.opacity(0.06) : .clear
    }
}

private struct CloseButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image("xmark", size: 9, weight: .bold)
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 18, height: 18)
                .background(isHovered ? Color.primary.opacity(0.12) : .clear, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(.closeTab))
        .help(L10n.text(.closeTab))
        .onHover { isHovered = $0 }
    }
}

private struct BarButton: View {
    static let size: CGFloat = 26

    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            SystemSymbol.image(icon, size: 13, weight: .medium)
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: Self.size, height: Self.size)
                .background(isHovered ? Color.primary.opacity(0.1) : .clear, in: .rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
        .onHover { isHovered = $0 }
    }
}
