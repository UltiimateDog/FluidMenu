//
//  OverlayContextMenu.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 04/01/26.
//

import Foundation
import SwiftUI

// MARK: - Modifier
/// A custom context menu modifier that presents menu content
/// using the app-wide overlay system.
///
/// Unlike SwiftUI’s native `.contextMenu`, this modifier renders
/// its menu inside an overlay layer managed by `OverlayManager`,
/// allowing for:
/// - Precise placement relative to the source view
/// - Custom animations and transitions
/// - Matched geometry effects
/// - Advanced visual styling (e.g. liquid glass backgrounds)
///
/// The menu is presented via a long-press gesture and positioned
/// using geometry captured from a named coordinate space provided
/// by `OverlayHost`.
///
/// > Important:
/// This modifier requires an `OverlayHost` to be present somewhere
/// above the view hierarchy. Without it, overlays will not render
/// correctly.
///
/// Presentation state is driven externally via a binding, allowing
/// the menu to be dismissed both internally (tap outside) and
/// externally by the owning view.
internal struct FluidContextMenuModifier<MenuContent: View>: ViewModifier {
    // MARK: - ATTRIBUTES
    
    /// Shared overlay manager used to coordinate menu presentation.
    @Environment(\.overlayManager) private var overlayManager
    
    /// The frame of the source view that triggered the context menu,
    /// captured in the overlay coordinate space.
    ///
    /// This frame is used as the anchor point for calculating
    /// overlay placement via `OverlayService`.
    @State private var sourceFrame: CGRect = .zero
    
    /// Controls whether the overlay menu is currently presented.
    @Binding var isPresented: Bool
    
    /// Namespace used for matched geometry effects between
    /// the source view and the overlay menu.
    let namespace: Namespace.ID
        
    /// Optional background color used for the dismissable overlay layer.
    /// Falls back to `OverlayConstants.backgroundColor` when `nil`.
    let backgroundColor: Color?
    
    /// Optional tint color applied to the liquid glass background.
    /// Falls back to `OverlayConstants.menuGlassTint` when `nil`.
    let glassTint: Color?
    
    @ViewBuilder let menuContent: () -> MenuContent

    // MARK: - BODY
    func body(content: Content) -> some View {
        content
        // MARK: - Position
            .onGeometryChange(for: CGRect.self) { geometry in
                geometry.frame(in: .named(OverlayConstants.coordinateSpace))
            } action: { newFrame in
                sourceFrame = newFrame
            }
        // MARK: - Long Press
            // Presents the context menu using a long-press gesture.
            // The overlay transition is configured before presentation to ensure consistent animation behavior.
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation(.bouncy) {
                    isPresented = true
                    
                    overlayManager.overlayTransition = OverlayConstants.contextMenuTransition
                    
                    overlayManager.show {
                        FluidContextMenu(
                            isPresented: $isPresented,
                            namespace: namespace,
                            backgroundColor: backgroundColor,
                            glassTint: glassTint,
                            sourceFrame: sourceFrame,
                            content: menuContent
                        )
                    }//: Context Menu
                }
            }//: Long Press
    }
}

// MARK: - Actual Menu
/// A private view responsible for rendering a context menu
/// inside the overlay layer.
///
/// This view handles:
/// - Menu placement relative to a source frame
/// - Overflow detection and scroll behavior
/// - Dismissal via background interaction
/// - Matched geometry animations
/// - Liquid glass visual styling
///
/// Layout decisions (placement and overflow detection) are
/// delegated to `OverlayService`, while rendering and interaction
/// remain local to this view.
///
/// This type is intentionally private and should only be
/// constructed by `CustomContextMenuModifier`.
private struct FluidContextMenu<Content: View>: View {
    // MARK: - ATTRIBUTES
    @Environment(\.overlayManager) private var overlayManager
    
    @State private var menuSize: CGSize = .zero
    @State private var showMenuContent: Bool = false
    
    @Binding var isPresented: Bool
    let namespace: Namespace.ID
        
    let backgroundColor: Color
    let glassTint: Color
    let sourceFrame: CGRect
    
    @ViewBuilder let content: Content
    
    // MARK: - Computed Properties
    /// The calculated center point where the menu should be positioned.
    ///
    /// The placement dynamically adapts to vertical overflow by
    /// expanding the menu to the full available height when needed,
    /// while maintaining a fixed width.
    private var placement: CGPoint {
        OverlayService.placement(sourceFrame: sourceFrame,
                                 overlaySize: CGSize(width: OverlayConstants.menuWidth,
                                                     height: yOverflow ?
                                                        overlayManager.overlayBounds.height :
                                                        menuSize.height),
                                 bounds: overlayManager.overlayBounds)
    }
    
    /// Indicates whether the menu content exceeds the available
    /// vertical bounds.
    ///
    /// When `true`, scrolling is enabled and the menu height is
    /// clamped to the overlay bounds.
    private var yOverflow: Bool {
        OverlayService.overflow(overlaySize: menuSize,
                                bounds: overlayManager.overlayBounds).yOverflow
    }
    
    // MARK: - Init
    init(
        isPresented: Binding<Bool>,
        namespace: Namespace.ID,
        backgroundColor: Color?,
        glassTint: Color?,
        sourceFrame: CGRect,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.namespace = namespace
        self.backgroundColor = backgroundColor ?? OverlayConstants.backgroundColor
        self.glassTint = glassTint ?? OverlayConstants.menuGlassTint
        self.sourceFrame = sourceFrame
        self.content = content()
    }
    
    // MARK: - BODY
    var body: some View {
        ZStack {
            dismissableBackground()
                .ignoresSafeArea()
            
            liquidGlassBox()
            
            menuContent()
        }
        // MARK: - Behaviours
        // Animates the menu content appearance after the container
        // has been laid out to avoid visual jumps during placement
        // and matched geometry transitions.
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                showMenuContent = true
            }
        }
        // Ensures menu content fades out smoothly before the
        // overlay is fully removed.
        .onDisappear {
            withAnimation(.easeOut(duration: 0.5)) {
                showMenuContent = false
            }
        }
    }
    
    // MARK: - Menu Content
    /// Builds the scrollable menu content.
    ///
    /// Scrolling is enabled only when the menu exceeds the available
    /// vertical space. The content is masked and animated using a
    /// matched geometry effect to maintain visual continuity with
    /// the background container.
    private func menuContent() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
                .frame(minHeight: OverlayConstants.menuMinHeight)
            // MARK: - Context Menu Size
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                menuSize = geometry.size
                            }
                    }
                }
        }
        .scrollDisabled(!yOverflow)
        .frame(width: OverlayConstants.menuWidth,
               height: yOverflow ?
                overlayManager.overlayBounds.height :
                menuSize.height)
        .position(placement)
        .opacity(showMenuContent ? 1 : 0)
        .mask {
            RoundedRectangle(cornerRadius: OverlayConstants.menuCornerRadius)
                .matchedGeometryEffect(
                    id: OverlayConstants.menuSpaceName,
                    in: namespace
                )
        }
    }
    
    // MARK: - Dismissable Background
    /// A full-screen background layer that dismisses the menu
    /// when tapped.
    ///
    /// This layer allows tap-outside dismissal while preserving
    /// full control over animation timing and overlay teardown.
    private func dismissableBackground() -> some View {
        Button {
            withAnimation {
                overlayManager.hide()
                
                isPresented = false
            }
        } label: {
            backgroundColor
        }
    }
    
    // MARK: - Liquid Glass Background
    /// Renders the liquid glass background container for the menu.
    ///
    /// A dedicated container is required to ensure the matched
    /// geometry effect animates from the correct final position.
    /// Without this, the view would animate placement and geometry
    /// separately, resulting in unintended visual artifacts.
    private func liquidGlassBox() -> some View {
        Group {
            RoundedRectangle(cornerRadius: OverlayConstants.menuCornerRadius)
                .fill(.clear)
                .glassEffect(.regular.tint(glassTint).interactive(),
                             in: .rect(cornerRadius: 40))
                .matchedGeometryEffect(id: OverlayConstants.menuSpaceName,
                                       in: namespace)
        }
        .frame(width: OverlayConstants.menuWidth,
               height: yOverflow ?
                overlayManager.overlayBounds.height :
                menuSize.height)
        .position(placement)
    }
}
