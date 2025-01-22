<a href="https://exyte.com/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/header-dark.png"><img src="https://raw.githubusercontent.com/exyte/media/master/common/header-light.png"></picture></a>

<a href="https://exyte.com/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/our-site-dark.png" width="80" height="16"><img src="https://raw.githubusercontent.com/exyte/media/master/common/our-site-light.png" width="80" height="16"></picture></a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://twitter.com/exyteHQ"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/twitter-dark.png" width="74" height="16"><img src="https://raw.githubusercontent.com/exyte/media/master/common/twitter-light.png" width="74" height="16">
</picture></a> <a href="https://exyte.com/contacts"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/get-in-touch-dark.png" width="128" height="24" align="right"><img src="https://raw.githubusercontent.com/exyte/media/master/common/get-in-touch-light.png" width="128" height="24" align="right"></picture></a>

<p><h1 align="left">Anchored Popup</h1></p>

<p><h4>Anchored Popup grows "out" of a trigger view, anchoring to a UnitPoint of the trigger, written with SwiftUI</h4></p>

![](https://img.shields.io/github/v/tag/exyte/anchoredPopup?label=Version)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fexyte%2FAnchoredPopup%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fexyte%2FAnchoredPopup%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![SPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](https://opensource.org/licenses/MIT)

# Usage

### Minimal example

```swift
import AnchoredPopup

Circle()
    .useAsPopupAnchor(id: "mainMenu", position: .anchorRelative(point: .bottomLeading)) {
         MainMenuView()
    }
```

### Required parameters - useAsPopupAnchor 
- `id` - A unique 'String' to store everything related to this animation (you can just pass 'UUID().uuidString'), you can use it to manually launch animations sith this func `AnchoredPopup.launchAnchoredAnimation`    
- `position` - a 'UnitPoint' to align with this part of anchor view. Could be an `anchorRelative` or `screenRelative` 'UnitPoint'
- `contentBuilder` - popup body builder

### Optional parameters
- `duration` - duration of growing animation

## Examples

To try AnchoredPopup examples:
- Clone the repo `https://github.com/exyte/AnchoredPopup.git`
- Open `AnchoredPopupExample/AnchoredPopupExample.xcodeproj`
- Try it!

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

```swift
dependencies: [
    .package(url: "https://github.com/exyte/AnchoredPopup.git")
]
```

## Requirements

* iOS 17.0+ 

## Our other open source SwiftUI libraries
[Grid](https://github.com/exyte/Grid) - The most powerful Grid container    
[ScalingHeaderScrollView](https://github.com/exyte/ScalingHeaderScrollView) - A scroll view with a sticky header which shrinks as you scroll  
[AnimatedTabBar](https://github.com/exyte/AnimatedTabBar) - A tabbar with number of preset animations         
[MediaPicker](https://github.com/exyte/mediapicker) - Customizable media picker     
[Chat](https://github.com/exyte/chat) - Chat UI framework with fully customizable message cells, input view, and a built-in media picker      
[ConcentricOnboarding](https://github.com/exyte/ConcentricOnboarding) - Animated onboarding flow    
[FloatingButton](https://github.com/exyte/FloatingButton) - Floating button menu    
[ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - A number of animated loading indicators    
[ProgressIndicatorView](https://github.com/exyte/ProgressIndicatorView) - A number of animated progress indicators    
[SVGView](https://github.com/exyte/SVGView) - SVG parser    
[LiquidSwipe](https://github.com/exyte/LiquidSwipe) - Liquid navigation animation    
[AnchoredPopup](https://github.com/exyte/AnchoredPopup) - Toasts, alerts and popups library written with SwiftUI    
