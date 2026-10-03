/// Les onglets d'une fenêtre, dans l'ordre de la barre, et celui affiché.
public struct TabList<Tab: Hashable & Sendable>: Hashable, Sendable {
    public private(set) var tabs: [Tab]
    public private(set) var selected: Tab

    public init(_ first: Tab) {
        tabs = [first]
        selected = first
    }

    /// Juste après l'onglet affiché, comme Ghostty, et l'affiche.
    public func inserting(_ tab: Tab) -> TabList {
        var list = self
        let index = tabs.firstIndex(of: selected).map { $0 + 1 } ?? tabs.endIndex
        list.tabs.insert(tab, at: index)
        list.selected = tab
        return list
    }

    /// En bout de barre, et l'affiche : un onglet venu d'une autre zone.
    public func appending(_ tab: Tab) -> TabList {
        var list = self
        list.tabs.append(tab)
        list.selected = tab
        return list
    }

    public func selecting(_ tab: Tab) -> TabList {
        guard tabs.contains(tab) else { return self }
        var list = self
        list.selected = tab
        return list
    }

    /// Fait le tour : après le dernier vient le premier.
    public func selecting(offset: Int) -> TabList {
        guard let index = tabs.firstIndex(of: selected) else { return self }
        let count = tabs.count
        return selecting(tabs[((index + offset) % count + count) % count])
    }

    public func moving(_ tab: Tab, to destination: Int) -> TabList {
        guard let index = tabs.firstIndex(of: tab) else { return self }
        var list = self
        list.tabs.remove(at: index)
        list.tabs.insert(tab, at: min(max(destination, 0), list.tabs.count))
        return list
    }

    /// Fermer l'onglet affiché montre son voisin de droite, ou de gauche au bout.
    /// Nil quand c'était le dernier : la fenêtre doit se fermer.
    public func removing(_ tab: Tab) -> TabList? {
        guard let index = tabs.firstIndex(of: tab) else { return self }
        guard tabs.count > 1 else { return nil }
        var list = self
        list.tabs.remove(at: index)
        if selected == tab {
            list.selected = list.tabs[min(index, list.tabs.count - 1)]
        }
        return list
    }
}

extension TabList: Codable where Tab: Codable {}
