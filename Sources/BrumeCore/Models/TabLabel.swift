/// Ce qu'on choisit pour reconnaître un onglet ou un split : un nom, une couleur, une icône.
public struct TabLabel: Codable, Hashable, Sendable {
    public var title: String?
    public var color: TabColor?
    public var icon: TabIcon?

    public init(title: String? = nil, color: TabColor? = nil, icon: TabIcon? = nil) {
        self.title = title
        self.color = color
        self.icon = icon
    }

    public var isEmpty: Bool {
        title == nil && color == nil && icon == nil
    }

    /// Ce qui manque ici, pris à `other`.
    public func filled(with other: TabLabel?) -> TabLabel {
        TabLabel(title: title ?? other?.title, color: color ?? other?.color, icon: icon ?? other?.icon)
    }
}

/// Les noms, couleurs et icônes d'une fenêtre. Un onglet seul porte le sien ; divisé, il devient
/// un groupe (« Groupe 1 » sans nom choisi) et chaque split porte le sien. Ils suivent le
/// terminal qu'on a nommé quand les splits se divisent, se séparent ou se regroupent.
public struct WindowLabels<Tab: Hashable & Sendable, Pane: Hashable & Sendable>: Hashable, Sendable {
    public var tabs: [Tab: TabLabel]
    public var panes: [Pane: TabLabel]
    /// Le numéro de chaque groupe, pour le nommer tant qu'on ne l'a pas renommé.
    public var groupNumbers: [Tab: Int]

    public init(tabs: [Tab: TabLabel] = [:], panes: [Pane: TabLabel] = [:], groupNumbers: [Tab: Int] = [:]) {
        self.tabs = tabs
        self.panes = panes
        self.groupNumbers = groupNumbers
    }

    /// Après le passage de `old` à `new` : un onglet qu'on divise donne son nom à son premier
    /// split, un split qui part seul reprend le sien en onglet, un onglet lâché dans un groupe
    /// le garde en split. Les groupes neufs prennent le plus petit numéro libre.
    public func reconciled(from old: WindowLayout<Tab, Pane>, to new: WindowLayout<Tab, Pane>) -> WindowLabels {
        let oldTabOfPane = old.tabOfPane
        var result = WindowLabels(groupNumbers: groupNumbers.filter { new.isSplit($0.key) })
        for tab in new.tabs {
            let panes = new.panes(of: tab)
            guard panes.count > 1 else {
                // Un groupe réduit à un split : le nom du terminal passe avant celui du groupe.
                let pane = panes[0]
                let label = (self.panes[pane] ?? TabLabel()).filled(with: tabs[tab]).filled(with: soloLabel(of: pane, in: old, oldTabOfPane))
                if !label.isEmpty { result.tabs[tab] = label }
                continue
            }
            if let label = tabs[tab], !old.isSplit(tab), old.splits[tab] != nil {
                // L'onglet qu'on vient de diviser : son nom passe à son terminal d'origine.
                let origin = old.panes(of: tab)[0]
                result.panes[origin] = (self.panes[origin] ?? TabLabel()).filled(with: label)
            } else if let label = tabs[tab] {
                result.tabs[tab] = label
            }
            for pane in panes where result.panes[pane] == nil {
                let label = (self.panes[pane] ?? TabLabel()).filled(with: soloLabel(of: pane, in: old, oldTabOfPane))
                if !label.isEmpty { result.panes[pane] = label }
            }
            if result.groupNumbers[tab] == nil {
                let used = Set(result.groupNumbers.values)
                result.groupNumbers[tab] = (1...).first { !used.contains($0) }
            }
        }
        return result
    }

    /// Le nom d'un onglet seul d'avant, qui n'existe plus : celui lâché dans un groupe.
    private func soloLabel(of pane: Pane, in old: WindowLayout<Tab, Pane>, _ oldTabOfPane: [Pane: Tab]) -> TabLabel? {
        guard let tab = oldTabOfPane[pane], !old.isSplit(tab) else { return nil }
        return tabs[tab]
    }
}
