//
//  OverlayManager.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 03/01/26.
//

import Foundation
import SwiftUI

/// A centralized manager responsible for presenting overlay content
/// above the main application UI.
///
/// `OverlayManager` maintains a single, currently active overlay
/// as an `AnyView`, allowing callers to present arbitrary SwiftUI views
/// without coupling to a concrete overlay type or presentation style.
///
/// The manager itself does **not** handle layout, animation, or rendering.
/// Instead, it acts as a source of truth that an `OverlayHost` (or similar
/// container view) observes and renders accordingly.
///
/// ## Responsibilities
/// - Store the currently presented overlay view
/// - Expose a simple API for showing and hiding overlays
/// - Provide layout bounds used by overlay placement logic
///
/// ## Non-Responsibilities
/// - Performing layout calculations
/// - Managing animations or transitions
/// - Handling user interaction rules (e.g. blocking touches)
/// - Supporting multiple overlays or stacking
///
/// ## Design Notes
/// - Uses `@Observable` so SwiftUI updates automatically when overlay state changes
/// - Stores overlays as `AnyView` to keep callers decoupled from implementation details
/// - Designed to be minimal and extensible
///
/// ## Possible Future Extensions
/// - Overlay stacking or prioritization
/// - Configurable dismissal rules (tap-outside, timeout, etc.)
/// - Centralized animation configuration
/// - Interaction blocking or passthrough behavior
///
/// ## Usage inside a View
/// ```swift
/// struct ExampleView: View {
///     @Environment(\.overlayManager) private var overlayManager
///
///     var body: some View {
///         Button("Show Overlay") {
///             overlayManager.show {
///                 VStack {
///                     Text("Hello Overlay")
///
///                     Button("Dismiss") {
///                         overlayManager.hide()
///                     }
///                 }
///                 .padding()
///                 .background(.ultraThinMaterial)
///                 .cornerRadius(12)
///             }
///         }
///     }
/// }
/// ```
@Observable
public final class OverlayManager {

    /// Shared global instance used by the application.
    ///
    /// This is intentionally a singleton, as overlays are treated as
    /// application-wide UI elements rather than view-local state.
    @MainActor static let shared: OverlayManager = .init()

    private init() { }
    
    // MARK: - Public
    
    /// Presents a new overlay.
    ///
    /// Calling this method replaces any currently visible overlay.
    ///
    /// - Parameter content: A view builder that returns the overlay content.
    public func show<Content: View>(@ViewBuilder _ content: () -> Content) {
        overlay = AnyView(content())
    }

    /// Dismisses the currently presented overlay.
    ///
    /// If no overlay is visible, this method has no effect.
    public func hide() {
        overlay = nil
    }
    
    // MARK: - Public, read-only state

    /// The available layout bounds for overlays.
    ///
    /// This typically represents the safe area or container bounds
    /// used by overlay placement logic. The value is expected to be
    /// updated by the hosting view when layout changes.
    public internal(set) var overlayBounds: CGRect = .zero
    
    /// The current safe area insets of the overlay host.
    ///
    /// This value represents the safe area information (top, bottom, leading,
    /// trailing) provided by the hosting container and can be used by overlay
    /// placement logic to avoid system UI such as the notch, status bar,
    /// or home indicator.
    ///
    /// The manager itself does not compute these insets. Instead, they are
    /// expected to be supplied and kept up to date by the `OverlayHost`
    /// whenever the layout environment changes (e.g. rotation, multitasking,
    /// size class changes).
    ///
    /// ## Design Notes
    /// - Stored separately from `overlayBounds` to allow finer-grained layout decisions
    /// - Enables overlays to opt into or out of safe-area-aware positioning
    /// - Keeps layout concerns centralized while remaining rendering-agnostic
    public internal(set) var safeAreaInsets: EdgeInsets = .init()
    
    // MARK: - Internal-only state
    
    /// The currently presented overlay view.
    ///
    /// When this value is non-`nil`, the `OverlayHost` is expected
    /// to render the overlay above the main application content.
    ///
    /// Setting a new value replaces any existing overlay.
    var overlay: AnyView? = nil
    
    /// Transition to apply when presenting/dismissing the overlay.
    /// Stored as AnyTransition to match View.transition(_:) requirements.
    var overlayTransition: AnyTransition = .identity
    
    // MARK: - DEBUG
    
    /// Controls whether diagnostic geometry information is rendered by the overlay host.
    ///
    /// When enabled, the hosting container (such as `OverlayHost`) may render
    /// visual debugging aids that illustrate overlay bounds, safe area insets,
    /// and other layout-related geometry information.
    ///
    /// This flag is intended strictly for development and debugging purposes.
    /// It does **not** influence overlay behavior, placement logic, animations,
    /// or interaction rules.
    ///
    /// ## Access Control
    /// - Readable within the module
    /// - Writable only by `OverlayManager`
    ///
    /// This ensures that diagnostic state remains centrally managed and cannot
    /// be mutated arbitrarily by consumers of the overlay infrastructure.
    ///
    /// ## Design Notes
    /// - Observed by the host, not acted upon internally by the manager
    /// - Does not affect production behavior unless explicitly enabled
    /// - Can later be surfaced via explicit debug APIs if needed
    internal private(set) var showGeometry: Bool = true

}
