import SwiftUI

/// Un groupe de réglages comme dans Monocode : titre et phrase au-dessus, lignes dans une carte.
struct SettingsGroup<Content: View>: View {
    let title: String
    var hint: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHeader(title: title, hint: hint)
            SettingsCard { content }
        }
    }
}

struct SettingsHeader: View {
    let title: String
    var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Ink.text)
                .accessibilityAddTraits(.isHeader)
            if let hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.hint)
                    .lineSpacing(3)
            }
        }
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Ink.card, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Ink.border) }
        .clipShape(.rect(cornerRadius: 12))
    }
}

/// Une ligne : le nom et une phrase à gauche, le contrôle à droite, aligné en haut, et au besoin
/// un contenu sur toute la largeur dessous.
struct SettingsRow<Control: View, Below: View>: View {
    let title: String
    let hint: String
    var isLast = false
    @ViewBuilder let control: Control
    @ViewBuilder let below: Below

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            below
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Ce qui se replie dessous reste dans la ligne pendant qu'elle rétrécit.
        .clipped()
        .overlay(alignment: .bottom) {
            if !isLast { Ink.rowRule.frame(height: 1) }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.text)
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.hint)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            control
        }
    }
}

extension SettingsRow where Below == EmptyView {
    init(title: String, hint: String, isLast: Bool = false, @ViewBuilder control: () -> Control) {
        self.init(title: title, hint: hint, isLast: isLast, control: control, below: { EmptyView() })
    }
}

/// Une ligne étroite : le nom, une phrase, puis le contrôle dessous, pour une colonne à côté
/// d'une autre.
struct SettingsStackedRow<Control: View>: View {
    let title: String
    var hint: String?
    var isLast = false
    @ViewBuilder let control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.text)
                if let hint {
                    Text(hint)
                        .font(.system(size: 12))
                        .foregroundStyle(Ink.hint)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            control
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast { Ink.rowRule.frame(height: 1) }
        }
    }
}
