import SwiftUI

// MARK: — Typography scale
//
// Cormorant Garant must be bundled as OTF in the app target and registered in Info.plist
// under UIAppFonts:
//   - CormorantGarant-Light.otf
//   - CormorantGarant-Regular.otf
//   - CormorantGarant-LightItalic.otf
// Download free: https://fonts.google.com/specimen/Cormorant+Garant

extension Font {
    /// 48pt Light — AuthView hero title, course hero title
    /// TODO: replace with CormorantGarant-Light once font is bundled
    static let tantrikaDisplay = Font.system(size: 48, weight: .light, design: .serif)

    /// 24pt Regular — screen titles, lesson titles
    /// TODO: replace with CormorantGarant-Regular once font is bundled
    static let tantrikaHeading = Font.system(size: 24, weight: .regular, design: .serif)

    /// 24pt Light Italic — course subtitle, emphasis labels
    /// TODO: replace with CormorantGarant-LightItalic once font is bundled
    static let tantrikaHeadingItalic = Font.system(size: 24, weight: .light, design: .serif).italic()

    /// 17pt Semibold SF Pro Display — section headers, lesson count
    static let tantrikaSubhead = Font.system(size: 17, weight: .semibold, design: .default)

    /// 15pt Regular SF Pro Text — descriptions, course copy (line-height 1.6 via .lineSpacing)
    static let tantrikaBody = Font.system(size: 15, weight: .regular, design: .default)

    /// 13pt Regular SF Pro Text — duration, metadata, badge text
    static let tantrikaCaption = Font.system(size: 13, weight: .regular, design: .default)

    /// 16pt Semibold SF Pro Text — all CTAs
    static let tantrikaButton = Font.system(size: 16, weight: .semibold, design: .default)
}

// MARK: — Spacing constants

enum TantrikaSpacing {
    static let xxs: CGFloat = 4   // internal badge padding
    static let xs:  CGFloat = 8   // icon-to-text gaps, tight component internals
    static let sm:  CGFloat = 16  // between related elements, inner card padding
    static let md:  CGFloat = 24  // between components, list row internal padding
    static let lg:  CGFloat = 32  // horizontal screen margins, between sections
    static let xl:  CGFloat = 48  // between major screen sections
    static let xxl: CGFloat = 64  // hero padding, screen breathing room
}

// MARK: — Corner radius constants

enum TantrikaRadius {
    static let sm:   CGFloat = 8     // badges, small elements
    static let md:   CGFloat = 12    // buttons, inputs
    static let lg:   CGFloat = 16    // cards, lesson rows, sheets
    static let full: CGFloat = 9999  // pill badges, avatar
}
