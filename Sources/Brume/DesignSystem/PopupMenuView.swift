import AppKit
import SwiftUI

/// Le contenu d'un panneau de `PopupMenu`, aux mesures de Monocode. Il s'ouvre comme leurs
/// popovers : un fondu, en grandissant depuis le coin du bouton.
struct PopupMenuView: View {
    let entries: [MenuEntry]
    let model: MenuModel
    let width: CGFloat
    let anchor: UnitPoint
    let onRow: (Int, Bool) -> Void

    @State private var isShown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(entries.indices, id: \.self) { index in
                switch entries[index] {
                case let .action(action):
                    row(index, action)
                case .separator:
                    Ink.border.frame(height: 1).padding(.vertical, 4)
                }
            }
        }
        .padding(4)
        .coordinateSpace(.named("menu"))
        .frame(width: width)
        .background {
            ZStack {
                MenuBlur()
                Ink.white(0.02)
            }
        }
        .clipShape(.rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.border) }
        .font(.system(size: 13))
        .environment(\.colorScheme, .dark)
        .scaleEffect(isShown ? 1 : 0.94, anchor: anchor)
        .offset(y: isShown ? 0 : -6)
        .opacity(isShown ? 1 : 0)
        .onAppear { withAnimation(Ink.open) { isShown = true } }
    }

    private func row(_ index: Int, _ action: MenuAction) -> some View {
        let isActive = action.isEnabled && model.highlighted == index
        let color: Color = action.isEnabled ? Ink.text : Ink.disabled
        return HStack(spacing: 12) {
            if let icon = action.icon {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                    .opacity(action.isEnabled ? 1 : 0.4)
            }
            if let swatch = action.swatch {
                Circle().fill(swatch).frame(width: 12, height: 12).frame(width: 16)
            }
            Text(action.title)
                .foregroundStyle(color)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let shortcut = action.shortcut {
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(Ink.meta)
            }
            if action.isChecked {
                SystemSymbol.image("checkmark", size: 11, weight: .semibold)
                    .foregroundStyle(Ink.text)
            }
            if action.submenu != nil {
                SystemSymbol.image("chevron.right", size: 10, weight: .semibold)
                    .foregroundStyle(Ink.muted)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(isActive ? Ink.selection : .clear, in: .rect(cornerRadius: 8))
        .contentShape(.rect)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("menu")) } action: { model.rowFrames[index] = $0 }
        .onHover { hovering in
            if hovering { onRow(index, false) }
        }
        .onTapGesture { onRow(index, true) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(action.isChecked ? [.isButton, .isSelected] : .isButton)
    }
}

private struct MenuBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
