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
    
    /// Controls whether source view frames should be corrected to remove
    /// an implicit safe area offset introduced by certain SwiftUI containers.
    ///
    /// This flag does **not** change how overlays are laid out or rendered.
    /// It exists solely to reconcile coordinate space inconsistencies when
    /// measuring source frames for overlay placement.
    ///
    /// ## Default Behavior (`false`)
    /// - The overlay coordinate space is **safe-area-aware**
    /// - `(0,0)` corresponds to the **safe area’s top-left**
    /// - Placement logic already assumes safe-area-relative coordinates
    ///
    /// This is the **correct and expected configuration** when source frames
    /// are measured from views that correctly report their position within
    /// the named overlay coordinate space (most container hierarchies).
    ///
    /// ## When set to `true`
    /// - Source frames are assumed to include an **undesired safe area offset**
    /// - The overlay system compensates by translating frames back into
    ///   safe-area-relative coordinates
    ///
    /// This mode is required when measuring geometry inside containers
    /// such as `NavigationStack`, where SwiftUI may report frames that
    /// already include safe area insets *even though the coordinate space
    /// itself is safe-area-relative*.
    ///
    /// ## NavigationStack Caveat
    /// When a view is embedded inside a `NavigationStack`, geometry proxies
    /// queried using the same named coordinate space may return frames whose
    /// origin has been shifted by the safe area insets.
    ///
    /// This results in a **double application of safe area offsets**, causing
    /// overlays to be positioned too far from their source view.
    ///
    /// Enabling `ignoreSafeAreaInsets` removes this extra offset and restores
    /// correct spatial alignment.
    ///
    /// ## Design Notes
    /// - This flag compensates for SwiftUI container behavior, not layout intent
    /// - It should only be enabled when such misreporting is observed
    /// - Incorrect usage may shift overlays outside the visible safe area
    public var ignoreSafeAreaInsets: Bool = false
    
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
    internal var overlay: AnyView? = nil
    
    /// Transition to apply when presenting/dismissing the overlay.
    /// Stored as AnyTransition to match View.transition(_:) requirements.
    internal var overlayTransition: AnyTransition = .identity
    
    /// The corrective origin applied when normalizing source view geometry.
    ///
    /// This value represents the offset that must be subtracted from a
    /// measured source frame when SwiftUI reports geometry that already
    /// includes safe area insets, despite the overlay coordinate space
    /// being safe-area-relative.
    ///
    /// ## Behavior
    /// - When `ignoreSafeAreaInsets` is `false`, no correction is applied
    ///   and the origin resolves to `.zero`
    /// - When `ignoreSafeAreaInsets` is `true`, the origin reflects the
    ///   overlay host’s bounds origin and is used to remove the extra
    ///   safe area offset from the source frame
    ///
    /// ## Usage
    /// This value is intended to be applied **at the moment a source frame
    /// is captured**, ensuring that all geometry passed into placement
    /// services is already normalized.
    ///
    /// Placement and overflow logic assumes:
    /// - `(0,0)` is the safe area’s top-left
    /// - No additional coordinate reconciliation is required
    ///
    /// ## Design Notes
    /// - Exists specifically to correct SwiftUI geometry inconsistencies
    /// - Keeps layout services pure and container-agnostic
    /// - Centralizes safe area correction in one place
    internal var origin: CGPoint {
        ignoreSafeAreaInsets ? overlayBounds.origin : .zero
    }
    
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
    internal private(set) var showGeometry: Bool = false

}
