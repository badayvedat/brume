import CoreGraphics

/// Une fenêtre comme Muxy : découpée en zones, chacune avec sa barre d'onglets.
/// Un onglet est un terminal ; diviser crée une zone, pas un volet dans l'onglet.
public struct WindowLayout<Area: Hashable & Sendable, Tab: Hashable & Sendable>: Hashable, Sendable {
    /// Un onglet glissé hors de sa barre, et où il ira si on le lâche.
    public struct Drop: Hashable, Sendable {
        public enum Target: Hashable, Sendable {
            /// Sur la barre ou le centre d'une autre zone : il rejoint ses onglets.
            case area(Area)
            /// Près d'un bord : une zone neuve s'ouvre de ce côté.
            case split(Area, SplitDirection)
        }

        public let tab: Tab
        public let target: Target
        /// Ce que prendra l'onglet, à montrer pendant le glisser.
        public let highlight: CGRect
    }

    public private(set) var tree: SplitTree<Area>
    public private(set) var areas: [Area: TabList<Tab>]
    public private(set) var focusedArea: Area

    public init(area: Area, tab: Tab) {
        tree = .pane(area)
        areas = [area: TabList(tab)]
        focusedArea = area
    }

    public var focusedTab: Tab {
        areas[focusedArea]!.selected
    }

    /// Dans l'ordre de lecture : zone par zone, puis dans l'ordre de chaque barre.
    public var tabs: [Tab] {
        tree.panes.flatMap { areas[$0]?.tabs ?? [] }
    }

    public func area(of tab: Tab) -> Area? {
        areas.first { $0.value.tabs.contains(tab) }?.key
    }

    public func isShown(_ tab: Tab) -> Bool {
        area(of: tab).map { areas[$0]?.selected == tab } ?? false
    }

    /// Dans la zone qui a le focus, juste après l'onglet affiché.
    public func addingTab(_ tab: Tab) -> WindowLayout {
        var layout = self
        layout.areas[focusedArea] = areas[focusedArea]?.inserting(tab)
        return layout
    }

    /// Une zone neuve à côté de celle qui a le focus, avec un onglet, et le focus.
    public func splitting(toward direction: SplitDirection, area: Area, tab: Tab) -> WindowLayout {
        var layout = self
        layout.tree = tree.inserting(.pane(area), beside: focusedArea, toward: direction)
        layout.areas[area] = TabList(tab)
        layout.focusedArea = area
        return layout
    }

    public func selecting(_ tab: Tab) -> WindowLayout {
        guard let area = area(of: tab) else { return self }
        var layout = self
        layout.areas[area] = areas[area]?.selecting(tab)
        layout.focusedArea = area
        return layout
    }

    /// Cmd+1 à Cmd+8 dans l'ordre de lecture de toute la fenêtre, Cmd+9 le dernier.
    public func selecting(number: Int) -> WindowLayout {
        let all = tabs
        let index = number == 9 ? all.count - 1 : number - 1
        guard all.indices.contains(index) else { return self }
        return selecting(all[index])
    }

    /// Onglet précédent ou suivant dans la zone qui a le focus.
    public func selecting(offset: Int) -> WindowLayout {
        var layout = self
        layout.areas[focusedArea] = areas[focusedArea]?.selecting(offset: offset)
        return layout
    }

    public func focusing(_ area: Area) -> WindowLayout {
        guard areas[area] != nil else { return self }
        var layout = self
        layout.focusedArea = area
        return layout
    }

    public func shortcutNumber(of tab: Tab) -> Int? {
        let all = tabs
        guard let index = all.firstIndex(of: tab) else { return nil }
        if index == all.count - 1, index >= 8 { return 9 }
        return index < 8 ? index + 1 : nil
    }

    /// Une zone vidée disparaît, sa voisine prend la place. Nil quand plus rien ne reste.
    public func removing(_ tab: Tab) -> WindowLayout? {
        guard let area = area(of: tab), let list = areas[area] else { return self }
        var layout = self
        if let remaining = list.removing(tab) {
            layout.areas[area] = remaining
            return layout
        }
        let order = tree.panes
        guard let tree = tree.removing(area) else { return nil }
        layout.tree = tree
        layout.areas[area] = nil
        if focusedArea == area, let index = order.firstIndex(of: area) {
            layout.focusedArea = tree.panes[max(index - 1, 0)]
        }
        return layout
    }

    /// Réordonner dans sa barre.
    public func moving(_ tab: Tab, to index: Int) -> WindowLayout {
        guard let area = area(of: tab) else { return self }
        var layout = self
        layout.areas[area] = areas[area]?.moving(tab, to: index)
        return layout
    }

    /// Lâché sur la barre d'une autre zone : il la rejoint, en dernier.
    public func moving(_ tab: Tab, into target: Area) -> WindowLayout {
        guard area(of: tab) != target, areas[target] != nil, let layout = removing(tab),
              let list = layout.areas[target] else { return self }
        var moved = layout
        moved.areas[target] = list.appending(tab)
        moved.focusedArea = target
        return moved
    }

    /// Lâché sur le bord d'une zone : il y ouvre une zone neuve, de ce côté.
    public func moving(_ tab: Tab, beside target: Area, toward direction: SplitDirection, area: Area) -> WindowLayout {
        guard canMove(tab, beside: target), let layout = removing(tab) else { return self }
        var moved = layout
        moved.tree = layout.tree.inserting(.pane(area), beside: target, toward: direction)
        moved.areas[area] = TabList(tab)
        moved.focusedArea = area
        return moved
    }

    /// Seul dans sa zone, un onglet ne peut pas se poser à côté de lui-même.
    public func canMove(_ tab: Tab, beside target: Area) -> Bool {
        guard let source = area(of: tab), areas[target] != nil else { return false }
        return source != target || (areas[source]?.tabs.count ?? 0) > 1
    }

    /// Où irait `tab` lâché en `point`, la fenêtre occupant `bounds`, chaque zone coiffée de sa barre.
    /// Nil : rien à proposer à cet endroit.
    public func drop(of tab: Tab, at point: CGPoint, in bounds: CGRect, barHeight: CGFloat) -> Drop? {
        guard let (area, frame) = tree.frames(in: bounds).first(where: { $0.value.contains(point) }) else { return nil }
        let content = frame.divided(atDistance: barHeight, from: .minYEdge).remainder
        let direction = SplitDirection.nearestEdge(to: point, in: content)
        let isOwnArea = self.area(of: tab) == area
        // Ailleurs, le centre et la barre servent à rejoindre la zone. Dans la sienne, où il est
        // déjà, toute la surface propose un split : le repère ne disparaît jamais en route.
        let nearEdge = content.contains(point) && direction.half(of: direction.half(of: content)).contains(point)
        if isOwnArea || nearEdge, canMove(tab, beside: area) {
            return Drop(tab: tab, target: .split(area, direction), highlight: direction.half(of: content))
        }
        return isOwnArea ? nil : Drop(tab: tab, target: .area(area), highlight: content)
    }

    /// `newArea` sert si le dépôt ouvre une zone.
    public func dropping(_ drop: Drop, newArea: Area) -> WindowLayout {
        switch drop.target {
        case let .area(area): moving(drop.tab, into: area)
        case let .split(area, direction): moving(drop.tab, beside: area, toward: direction, area: newArea)
        }
    }

    public func settingRatio(_ ratio: CGFloat, at path: [Int]) -> WindowLayout {
        var layout = self
        layout.tree = tree.settingRatio(ratio, at: path)
        return layout
    }

    public func equalized() -> WindowLayout {
        var layout = self
        layout.tree = tree.equalized()
        return layout
    }
}
