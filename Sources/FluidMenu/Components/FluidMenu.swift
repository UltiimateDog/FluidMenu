//
//  OverlayMenu.swift
//  Virtus Fitness Journey
//
//  Created by Ultiimate Dog on 10/01/26.
//

import SwiftUI

#warning("Finish component")

/// A compact, reusable overlay-backed menu component.
///
/// `OverlayMenu` provides a small, tappable (or long-pressable) control
/// that presents its content using the custom overlay context menu system.
/// It acts as a higher-level convenience wrapper around
/// `CustomContextMenuModifier`, bundling:
/// - a trigger label,
/// - matched geometry animation,
/// - and glass-style visual treatment.
///
/// This component is intentionally minimal and currently focused on
/// **presentation and interaction**, not configuration breadth.
///
/// > Note:
/// This component is a work in progress. Additional configuration
/// options (e.g. placement control, trigger type, accessibility,
/// sizing) are expected to be added in future iterations.
public struct FluidMenu<MenuContent: View, Label: View>: View {
    // MARK: - ATTRIBUTES
    /// Shared overlay manager used to coordinate menu presentation.
    @Environment(\.overlayManager) private var overlayManager
    
    /// Namespace used for matched geometry animations between
    /// the menu trigger and the overlay menu.
    @Namespace private var namespace
    
    /// Controls whether the overlay menu is currently presented.
    @State private var isPresented: Bool = false
    
    /// Tint color applied to both the trigger and the menu’s
    /// liquid glass background.
    let glassTint: Color
    
    /// The content displayed inside the overlay menu.
    @ViewBuilder let content: MenuContent
    
    /// The visual label used as the menu trigger.
    @ViewBuilder let label: Label
    
    // MARK: - Init
    /// Creates an overlay menu with the given content and trigger label.
    ///
    /// - Parameters:
    ///   - glassTint: Optional tint applied to the glass effect. If `nil`,
    ///     `OverlayConstants.menuGlassTint` is used.
    ///   - content: The menu content presented in the overlay.
    ///   - label: The visual trigger for presenting the menu.
    public init(glassTint: Color? = nil,
         @ViewBuilder content: () -> MenuContent,
         @ViewBuilder label: () -> Label) {
        self.glassTint = glassTint ?? OverlayConstants.menuGlassTint
        self.content = content()
        self.label = label()
    }
    
    // MARK: - BODY
    /// Renders the menu trigger and conditionally presents the overlay menu.
    ///
    /// The trigger is hidden while the menu is presented to allow the
    /// overlay menu to fully own the matched geometry animation.
    public var body: some View {
        ZStack {
            // The trigger is removed while the menu is visible to prevent
            // duplicate geometry sources during matched geometry animations.
            if !isPresented {
                Circle()
                    .fill(.clear)
                    .frame(width: 30, height: 30)
                    .contentShape(.circle)
                    .fluidContextMenu(isPresented: $isPresented,
                                       namespace: namespace,
                                       glassTint: glassTint) {
                        content
                    }
                    .overlay {
                        label
                    }
                // Applies a liquid glass appearance to the trigger to visually
                // match the overlay menu background.
                    .glassEffect(.regular.tint(glassTint).interactive())
                // Enables a seamless transition between the trigger and the
                // overlay menu using matched geometry.
                    .matchedGeometryEffect(id: OverlayConstants.menuSpaceName,
                                           in: namespace)
            }
        }//: ZStack
        .frame(width: 30, height: 30)
    }
}

/// Preview demonstrating an overlay menu with scrollable content.
#Preview {
    ScrollView {
        ForEach(0...10, id:\.self) { _ in
            HStack {
                Spacer()
                
                FluidMenu {
                    VStack {
                        ForEach(1...7, id: \.self) { i in
                            Text("Test text for menu item \(i)")
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 15)
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19, height: 19)
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
            .padding()
        }
    }
    .containerizedInOverlayHost()
    .onAppear {
        OverlayManager.shared.ignoreSafeAreaInsets = false
    }
}

#Preview {
    NavigationStack {
        
        ScrollView {
            ForEach(0...10, id:\.self) { _ in
                HStack {
                    Spacer()
                    
                    FluidMenu {
                        VStack {
                            ForEach(1...7, id: \.self) { i in
                                Text("Test text for menu item \(i)")
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 15)
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19, height: 19)
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
            }
        }
    }
    .containerizedInOverlayHost()
    .onAppear {
        OverlayManager.shared.ignoreSafeAreaInsets = true
    }
}
