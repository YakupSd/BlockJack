//
//  UIFont+Extension.swift
//  TurkiyeKatılımSigorta
//
//  Created by ISMAIL PALALI on 5.06.2023.
//

import Foundation
import UIKit
import SwiftUI


public enum CustomFonts: String {
    case MavenBlack = "MavenPro-Black"
    case MavenBold = "MavenPro-Bold"
    case MavenExtraBold = "MavenPro-ExtraBold"
    case MavenMedium = "MavenPro-Medium"
    case MavenRegular = "MavenPro-Regular"
    case MavenSemiBold = "MavenPro-SemiBold"

    case InterBlack = "Inter-Black"
    case InterBlackItalic = "Inter-BlackItalic"
    case InterBold = "Inter-Bold"
    case InterBoldItalic = "Inter-BoldItalic"
    case InterExtraBold = "Inter-ExtraBold"
    case InterExtraBoldItalic = "Inter-ExtraBoldItalic"
    case InterExtraLight = "Inter-ExtraLight"
    case InterExtraLightItalic = "Inter-ExtraLightItalic"
    case InterItalic = "Inter-Italic"
    case InterLight = "Inter-Light"
    case InterLightItalic = "Inter-LightItalic"
    case InterMedium = "Inter-Medium"
    case InterMediumItalic = "Inter-MediumItalic"
    case InterRegular = "Inter-Regular"
    case InterSemiBold = "Inter-SemiBold"
    case InterSemiBoldItalic = "Inter-SemiBoldItalic"
    case InterThin = "Inter-Thin"
    case InterThinItalic = "Inter-ThinItalic"

    case ManropeBold = "Manrope-Bold"
    case ManropeExtraBold = "Manrope-ExtraBold"
    case ManropeMedium = "Manrope-Medium"
    case ManropeRegular = "Manrope-Regular"
    case ManropeSemiBold = "Manrope-SemiBold"
}
extension Font {
    public static func setCustomFont(name: CustomFonts, size: CGFloat = 14) -> Font {
        if let uiFont = UIFont(name: name.rawValue, size: size) {
            return Font(uiFont)
        } else {
            return Font.system(size: size, weight: .bold)
        }
    }

    /// Luminescent Design System: High-tracking headers
    public static func luminescentHeader(size: CGFloat = 22) -> Font {
        return setCustomFont(name: .ManropeExtraBold, size: size)
    }
}

extension View {
    func luminescentTracking() -> some View {
        self.tracking(1.5)
    }
}

extension UIFont {
    public static func setCustomUIFont(name: CustomFonts, size: CGFloat = 14) -> UIFont {
        return UIFont(name: name.rawValue, size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
}

