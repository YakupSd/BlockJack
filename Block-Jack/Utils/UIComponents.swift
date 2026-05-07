//
//  UIComponents.swift
//  Block-Jack
//

import SwiftUI

// MARK: - Visual Effect Blur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemUltraThinMaterialLight
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Grid Pattern Shape
struct GridPattern: Shape {
    var spacing: CGFloat = 40
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: 0, through: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, through: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

// MARK: - Pulsing Circle (Compatible with older iOS)
struct PulsingCircle: View {
    @State private var animate = false
    var color: Color
    var size: CGFloat
    
    var body: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 1)
            .frame(width: size, height: size)
            .scaleEffect(animate ? 1.2 : 1.0)
            .opacity(animate ? 0 : 1.0)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

// MARK: - Common Geometric Shapes
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        let hx = w * 0.5, hy = h * 0.5, sideX = hx * 0.5
        path.move(to: CGPoint(x: cx - hx + sideX, y: cy - hy))
        path.addLine(to: CGPoint(x: cx + hx - sideX, y: cy - hy))
        path.addLine(to: CGPoint(x: cx + hx, y: cy))
        path.addLine(to: CGPoint(x: cx + hx - sideX, y: cy + hy))
        path.addLine(to: CGPoint(x: cx - hx + sideX, y: cy + hy))
        path.addLine(to: CGPoint(x: cx - hx, y: cy))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
