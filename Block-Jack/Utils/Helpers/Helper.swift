//
//  Helper.swift
//  Block-Jack
//

import Foundation
import SafariServices
import UIKit
import SwiftUI

/// Genel yardımcı metodlar ve yapılar.
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

/// ISO Tarih stringini DD/MM/YYYY formatına çevirir.
func generalShortDate2(isoDate: String) -> String {
    let isoFormatter = DateFormatter()
    isoFormatter.locale = Locale(identifier: "en_US_POSIX")
    isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    if let date = isoFormatter.date(from: isoDate) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"
        return outputFormatter.string(from: date)
    } else {
        return ""
    }
}

/// String içindeki sayısal değeri Double'a çevirir.
func formatAmount(amount: String) -> Double {
    return Double(amount) ?? 0.0
}

public extension NSObject {
    static var className: String {
        String(describing: self)
    }
    
    var className: String {
        String(describing: self)
    }
}

/// Uygulama ayarları sayfasını açar.
func openSystemAppSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString),
       UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
    }
}
