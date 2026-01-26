//
//  OverlayHost.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 03/01/26.
//

import SwiftUI

/// A container view responsible for hosting and rendering overlay content
/// above the main application UI.
///
/// `OverlayHost` is intended to wrap the root (or a high-level container)
/// of the application. It observes a shared `OverlayManager` instance and
/// renders any active overlay above its content using a dedicated overlay layer.
///
/// This view acts as the **bridge** between overlay state (`OverlayManager`)
/// and actual rendering, but intentionally avoids making decisions about
/// layout or overlay content.
///
/// ## Responsibilities
/// - Inject a shared `OverlayManager` into the environment
/// - Observe overlay state changes and render overlays above content
/// - Establish a named coordinate space for overlay layout
/// - Capture and publish layout bounds used for overlay placement
///
/// ## Non-Responsibilities
/// - Calculating overlay placement
/// - Managing overlay animations or transitions
/// - Handling overlay dismissal logic
/// - Supporting multiple or stacked overlays
///
/// ## Design Notes
/// - Uses a `ZStack` to ensure overlays are always rendered above content
/// - Applies a very high `zIndex` to guarantee top-most rendering
/// - Uses a named coordinate space to allow precise geometry calculations
/// - Publishes layout bounds to `OverlayManager` for downstream placement logic
///
/// ## Usage
/// ```swift
/// OverlayHost {
///     ContentView()
/// }
/// ```
public struct OverlayHost<Content: View>: View {

    /// The shared overlay manager instance.
    ///
    /// Stored locally to guarantee a stable reference that is both
    /// observed and injected into the environment for the lifetime
    /// of the host.
    private var manager = OverlayManager.shared

    /// The main application content rendered beneath overlays.
    let content: Content

    /// Creates an overlay host wrapping the provided content.
    ///
    /// - Parameter content: The root or container view to be displayed
    ///   beneath any active overlays.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            // Main application content
            content

            // Overlay rendering layer
            if let overlay = manager.overlay {
                overlay
                    .zIndex(999)
                    // Overlay transitions are intentionally disabled.
                    // Animation and transition decisions are expected to be
                    // handled by the overlay content itself or future extensions.
                    .transition(manager.overlayTransition)
            }
        }
        // Make the overlay manager available to all descendants.
        .environment(\.overlayManager, manager)
        // Establish a coordinate space for geometry-based placement.
        .coordinateSpace(name: OverlayConstants.coordinateSpace)
        // Capture layout bounds for overlay placement calculations.
        .modifier(OverlayGeometryPublisher(manager: manager))
    }
}

/// A view modifier responsible for capturing geometry information required
/// for overlay layout and publishing it to an `OverlayManager`.
///
/// `OverlayGeometryPublisher` measures the bounds and safe area insets of the
/// view hierarchy in which it is applied, using a named coordinate space
/// defined by `OverlayConstants.coordinateSpace`.
///
/// The captured values are forwarded to the provided `OverlayManager`,
/// enabling downstream overlay placement logic without tightly coupling
/// layout measurement to overlay rendering.
///
/// ## Responsibilities
/// - Measure the host view’s frame within the overlay coordinate space
/// - Observe safe area inset changes
/// - Publish geometry updates to `OverlayManager`
///
/// ## Design Notes
/// - Uses `Color.clear` in the background to avoid affecting layout
/// - Relies on `onGeometryChange` to react to size and inset changes
/// - Intentionally does not perform any calculations or transformations
///   on the measured values
///
/// ## Scope
/// This modifier is an implementation detail of `OverlayHost` and is not
/// intended to be applied directly by consumers.
private struct OverlayGeometryPublisher: ViewModifier {

    /// The overlay manager that receives geometry updates.
    let manager: OverlayManager

    func body(content: Content) -> some View {
        content.background {
            Color.clear
                .onGeometryChange(
                    for: CGRect.self,
                    of: { proxy in
                        proxy.frame(in: .named(OverlayConstants.coordinateSpace))
                    },
                    action: { newBounds in
                        OverlayLog.host.debug(
                            "Overlay bounds updated: \(String(describing: newBounds), privacy: .public)"
                        )

                        manager.overlayBounds = newBounds
                    }
                )
                .onGeometryChange(
                    for: EdgeInsets.self,
                    of: { proxy in
                        proxy.safeAreaInsets
                    },
                    action: { newInsets in
                        OverlayLog.host.debug(
                            "Safe area insets updated: \(String(describing: newInsets), privacy: .public)"
                        )

                        manager.safeAreaInsets = newInsets
                    }
                )
        }

    }
}


