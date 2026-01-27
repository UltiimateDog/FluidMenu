# FluidMenu

A lightweight, extensible overlay infrastructure for SwiftUI, designed to support **fluid context menus**, popovers, and other floating UI elements with precise placement, custom animations, and advanced visual styling.

<div align="center">
<img src="Assets/FluidMenuPackageIcon.png" width="25%" />
</div>

---

## Motivation

SwiftUI’s built-in presentation tools (e.g. `.contextMenu`, `.popover`) are convenient but restrictive when you need:

* Geometry-aware placement relative to a source view
* Full control over animations and transitions
* Custom visual effects (e.g. liquid glass, materials)
* Decoupling presentation from view hierarchy constraints
* Customization of menu visuals, such as:
  - Liquid glass color/tint
  - Arbitrary images/icons in menu rows
  - Per-item text colors and fonts

This overlay system addresses those needs by introducing a centralized overlay layer that can host arbitrary SwiftUI views while remaining layout- and animation-agnostic. You own the visuals and content — including images and text colors — and we provide placement, hosting, and lifecycle.

---

## Architecture Overview

FluidMenu is composed of a small number of focused components, each with a clearly defined responsibility.

### 1. `OverlayManager`

The single source of truth for overlay presentation state.

**Responsibilities**

- Stores the currently active overlay (`AnyView?`)
- Exposes simple APIs to show and hide overlays
- Publishes layout bounds and safe area information for placement logic

**Non-responsibilities**

- Layout calculations
- Animations or transitions
- Interaction rules

`OverlayManager` is intentionally implemented as a singleton, as overlays are treated as **application-wide UI elements** rather than view-local state.

---

### 2. `OverlayHost`

A container view that bridges overlay state to rendering.

**Responsibilities**

- Injects `OverlayManager` into the SwiftUI environment
- Renders the active overlay above main content
- Establishes a named coordinate space for geometry capture
- Publishes layout bounds and safe area insets to the manager

`OverlayHost` should be placed once near the root of the view hierarchy.

---

### 3. `OverlayService`

A stateless layout service responsible for overlay placement and overflow detection.

**Responsibilities**

- Calculates overlay placement relative to a source frame
- Detects horizontal and vertical overflow conditions
- Provides predictable fallback behavior when space is constrained

This service is pure (aside from debug logging) and does not modify UI state.

---

### 4. Fluid Context Menu System

FluidMenu’s custom context menu implementation builds directly on the overlay infrastructure:

- `.fluidContextMenu` (view modifier)
- `FluidContextMenu` (private rendering view)
- `FluidMenu` (higher-level convenience component)

Together, these provide:

- Long-press–triggered presentation
- Geometry-aware placement
- Matched geometry animations
- Scroll handling for overflow content
- Liquid glass–style visual treatment

---

## Usage

### Basic Setup

Place an `OverlayHost` near the root of your view hierarchy:

```swift
OverlayHost {
    ContentView()
}
```

---

### Attaching a Custom Context Menu

```swift
@Namespace private var namespace
@State private var isPresented = false

Text("Options")
    .fluidContextMenu(
        isPresented: $isPresented,
        namespace: namespace
    ) {
        VStack {
            Button("Edit") { }
            Button("Delete") { }
        }
        .padding()
    }
```

---

### Using `FluidMenu`

`FluidMenu` is a compact, reusable control that bundles a trigger label with an overlay-backed menu:

```swift
FluidMenu {
    VStack {
        Text("Item 1")
        Text("Item 2")
    }
} label: {
    Image(systemName: "ellipsis")
}
```

---

## Design Principles

* **Single Overlay Layer**: Only one overlay is presented at a time.
* **Decoupled Responsibilities**: State, layout, rendering, and styling are separated.
* **Explicit Geometry**: All placement is based on measured frames in a named coordinate space.
* **Minimal Assumptions**: Animations and interactions are owned by overlay content, not the manager.

---

## Current Limitations

* Only a single overlay can be presented at a time
* No built-in stacking or prioritization
* Limited accessibility support (WIP)
* `FluidMenu` is intentionally minimal and unfinished

---

## Future Directions

Potential extensions include:

* Overlay stacking or prioritization
* Configurable dismissal rules
* Centralized animation configuration
* Accessibility improvements
* Additional overlay types (tooltips, popovers)

---

## Summary

This overlay system provides a flexible foundation for advanced UI presentation in SwiftUI, without over-committing to a specific interaction or visual style. It is designed to scale gradually as application needs evolve.
