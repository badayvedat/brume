import AppKit
import BrumeCore
import SwiftUI

/// Barre native posée sur le terminal, comme Ghostty : le moteur ne dessine que la vue,
/// la barre reflète sa position et la renvoie quand on la glisse.
struct ScrollbarOverlay: NSViewRepresentable {
    let position: ScrollbarPosition?
    let isDark: Bool
    let onScroll: (NSEvent) -> Void
    let onScrollToRow: (Int) -> Void

    func makeNSView(context: Context) -> ScrollbarOverlayView {
        ScrollbarOverlayView()
    }

    func updateNSView(_ view: ScrollbarOverlayView, context: Context) {
        view.onScroll = onScroll
        view.onScrollToRow = onScrollToRow
        view.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        view.update(position)
    }
}

final class ScrollbarOverlayView: NSView {
    var onScroll: (NSEvent) -> Void = { _ in }
    var onScrollToRow: (Int) -> Void = { _ in }

    private let scrollView = ForwardingScrollView()
    private var position: ScrollbarPosition?
    private var isDragging = false
    private var lastSentRow: Int?
    // Une barre cachée resterait cliquable et volerait la sélection au bord droit :
    // elle ne prend les clics que le temps où elle est affichée.
    private var clickableUntil = Date.distantPast
    nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init() {
        super.init(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.documentView = NSView()
        scrollView.onScroll = { [weak self] in self?.onScroll($0) }
        addSubview(scrollView)

        observe(NSScrollView.willStartLiveScrollNotification, of: scrollView) { $0.isDragging = true }
        observe(NSScrollView.didEndLiveScrollNotification, of: scrollView) {
            $0.isDragging = false
            $0.keepClickable()
        }
        observe(NSScrollView.didLiveScrollNotification, of: scrollView) { $0.sendDraggedRow() }
        // « Toujours afficher les barres » mettrait une barre opaque sur le texte : Ghostty force l'overlay.
        observe(NSScroller.preferredScrollerStyleDidChangeNotification, of: nil) {
            $0.scrollView.scrollerStyle = .overlay
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func update(_ new: ScrollbarPosition?) {
        if let new, new.hasScrolled(from: position) {
            keepClickable()
            scrollView.flashScrollers()
        }
        position = new
        synchronize()
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
        synchronize()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard isDragging || Date() < clickableUntil, let scroller = scrollView.verticalScroller else { return nil }
        return scroller.bounds.contains(scroller.convert(point, from: superview)) ? scroller : nil
    }

    private func synchronize() {
        guard let document = scrollView.documentView else { return }
        let height = scrollView.contentSize.height
        guard let position, position.isScrollable, height > 0 else {
            document.frame = CGRect(origin: .zero, size: scrollView.contentSize)
            return
        }
        document.frame = CGRect(x: 0, y: 0, width: bounds.width, height: position.documentHeight(viewport: height))
        if !isDragging {
            scrollView.contentView.scroll(to: CGPoint(x: 0, y: position.scrollOrigin(viewport: height)))
            lastSentRow = position.offset
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func sendDraggedRow() {
        guard let position, position.isScrollable else { return }
        let origin = scrollView.contentView.bounds.origin.y
        let row = position.row(atScrollOrigin: origin, viewport: scrollView.contentSize.height)
        guard row != lastSentRow else { return }
        lastSentRow = row
        onScrollToRow(row)
    }

    private func keepClickable() {
        clickableUntil = Date().addingTimeInterval(1.25)
    }

    private func observe(_ name: Notification.Name, of object: AnyObject?, _ handler: @escaping @MainActor @Sendable (ScrollbarOverlayView) -> Void) {
        observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                if let self { handler(self) }
            }
        })
    }
}

/// Le défilement reste celui du moteur, même quand la souris est sur la barre.
private final class ForwardingScrollView: NSScrollView {
    var onScroll: (NSEvent) -> Void = { _ in }

    override func scrollWheel(with event: NSEvent) {
        onScroll(event)
    }
}
