//
//  ENRedButton.swift
//  Block-Jack
//

import SwiftUI

struct ENRedButton: View {
    var localizableText = "localizableText"
    var btnWidth: CGFloat? = nil
    var buttonFillColor: Color = ThemeColors.neonPink
    var buttonDisabledColor: Color = ThemeColors.locked
    var buttonDisabledTextColor: Color = ThemeColors.textMuted
    var lineWidth: CGFloat = 0
    var strokeColor: Color = .white
    var textColor: Color = .white
    var frameHeight: CGFloat = 45
    var radius: CGFloat = 8
    var txtPadding: CGFloat = 12.0
    var mainFont: Font = .setCustomFont(name: .InterSemiBold, size: 17)
    var enabled: () -> Bool = { true }
    @State private var isDisabled = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
            if !isDisabled {
                isDisabled = true
                HapticManager.shared.play(.buttonTap)
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isDisabled = false
                }
            }
        }) {
            HStack {
                Text(localizableText)
                    .font(mainFont)
                    .foregroundColor(enabled() ? textColor : buttonDisabledTextColor)
                    .padding(.trailing, txtPadding)
                    .padding(.leading, txtPadding)
            }
            .frame(maxWidth: btnWidth ?? .infinity)
            .frame(height: frameHeight)
            .background(enabled() ? buttonFillColor : buttonDisabledColor)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
        }
        .disabled(!enabled() || isDisabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        ENRedButton(localizableText: "Oyna", action: {})
        ENRedButton(localizableText: "Disabled", enabled: { false })
    }
    .padding()
    .background(ThemeColors.cosmicBlack)
}
