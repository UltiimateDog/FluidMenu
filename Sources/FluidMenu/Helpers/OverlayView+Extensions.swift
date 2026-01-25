//
//  OverlayView+Extensions.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 14/01/26.
//

import Foundation
import SwiftUI

/// Convenience view extensions for presenting overlay-based UI.
///
/// These helpers provide ergonomic access to the overlay system,
/// allowing any view to:
/// - present a custom overlay-backed context menu, or
/// - be embedded inside an `OverlayHost` with minimal boilerplate.
///
/// All APIs defined here assume that an `OverlayHost` exists
/// somewhere above the view hierarchy.
public extension View {
    
    // MARK: - Context Menu
    /// Attaches a custom overlay-backed context menu to the view.
    ///
    /// This modifier presents its menu content using the app-wide
    /// overlay system instead of SwiftUI’s native `.contextMenu`,
    /// enabling:
    /// - Precise geometry-based placement
    /// - Custom transitions and animations
    /// - Matched geometry effects
    /// - Advanced visual styling (e.g. liquid glass)
    ///
    /// The menu is typically triggered via a long-press gesture,
    /// and its presentation state is controlled externally through
    /// the provided binding.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls whether the menu is visible.
    ///   - namespace: Namespace used for matched geometry animations.
    ///   - backgroundColor: Optional background color for the dismissable
    ///     overlay layer. Falls back to `OverlayConstants.backgroundColor`.
    ///   - glassTint: Optional tint applied to the menu’s glass effect.
    ///     Falls back to `OverlayConstants.menuGlassTint`.
    ///   - content: The content displayed inside the overlay menu.
    ///
    /// - Important:
    /// This modifier requires an `OverlayHost` to be present above the
    /// view hierarchy in order to function correctly.
    func fluidContextMenu<MenuContent: View>(
        isPresented: Binding<Bool>,
        namespace: Namespace.ID,
        backgroundColor: Color? = nil,
        glassTint: Color? = nil,
        @ViewBuilder content: @escaping () -> MenuContent
    ) -> some View {
        modifier(
            FluidContextMenuModifier(
                isPresented: isPresented,
                namespace: namespace,
                backgroundColor: backgroundColor,
                glassTint: glassTint,
                menuContent: content
            )
        )
    }
        
    // MARK: - Containarize View in Overlay Host
    /// Wraps the view in an `OverlayHost`.
    ///
    /// This is a convenience helper intended for previews or
    /// simple hierarchies, allowing overlay functionality to
    /// work without manually adding an `OverlayHost` at the
    /// app or scene root.
    ///
    /// In production code, `OverlayHost` is typically placed
    /// once near the root of the view hierarchy.
    func containerizedInOverlayHost() -> some View {
        OverlayHost {
            self
        }
    }
    
}
