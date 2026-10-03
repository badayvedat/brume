// Repris de Muxy (Views/Components/Interaction/WindowDragView.swift).
// MIT License, Copyright (c) 2026 Muxy.

import AppKit
import SwiftUI

/// Fond de la barre du haut : glisser déplace la fenêtre, double-cliquer suit le réglage
/// macOS (agrandir ou réduire).
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func isAccessibilityElement() -> Bool {
            false
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                if UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") == "Minimize" {
                    window?.miniaturize(nil)
                } else {
                    window?.zoom(nil)
                }
                return
            }
            // Attendre le délai du double-clic : un glissé lancé tout de suite avalerait le second clic.
            let next = window?.nextEvent(
                matching: [.leftMouseUp, .leftMouseDown, .leftMouseDragged],
                until: Date(timeIntervalSinceNow: NSEvent.doubleClickInterval),
                inMode: .eventTracking,
                dequeue: true
            )
            switch next?.type {
            case nil, .leftMouseDragged:
                window?.performDrag(with: event)
            case .leftMouseDown:
                mouseDown(with: next!)
            default:
                break
            }
        }
    }
}
