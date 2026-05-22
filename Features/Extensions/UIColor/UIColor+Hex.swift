//
//  UIColor+Hex.swift
//  NFSportApp
//
//  Created by Willy Hsu on 2026/5/22.
//

import UIKit

extension UIColor {

    var hexString: String? {
        guard let components = rgbaComponents else {
            return nil
        }

        let red = Int(round(components.red * 255))
        let green = Int(round(components.green * 255))
        let blue = Int(round(components.blue * 255))

        if components.alpha < 1 {
            let alpha = Int(round(components.alpha * 255))
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        }

        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    convenience init?(hex: String, alpha: CGFloat = 1) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }

        guard !sanitized.isEmpty else {
            return nil
        }

        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else {
            return nil
        }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let resolvedAlpha: CGFloat

        switch sanitized.count {
        case 3:
            red = CGFloat((value & 0xF00) >> 8 | (value & 0xF00) >> 4) / 255
            green = CGFloat((value & 0x0F0) >> 4 | (value & 0x0F0)) / 255
            blue = CGFloat((value & 0x00F) | (value & 0x00F) << 4) / 255
            resolvedAlpha = alpha
        case 6:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            resolvedAlpha = alpha
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            resolvedAlpha = CGFloat(value & 0x000000FF) / 255
        default:
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: resolvedAlpha)
    }

    private var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }

        guard let components = cgColor.components else {
            return nil
        }

        switch components.count {
        case 2:
            return (components[0], components[0], components[0], components[1])
        case 3:
            return (components[0], components[1], components[2], cgColor.alpha)
        case 4:
            return (components[0], components[1], components[2], components[3])
        default:
            return nil
        }
    }
}
