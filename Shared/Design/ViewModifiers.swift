import SwiftUI

// MARK: - Modern Card Modifier

struct ModernCardModifier: ViewModifier {
    var elevation: Theme.Elevation = .light

    func body(content: Content) -> some View {
        let shadow = elevation.shadow
        return content
            .background(Theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func modernCard(elevation: Theme.Elevation = .light) -> some View {
        self.modifier(ModernCardModifier(elevation: elevation))
    }

    func mainBackground() -> some View {
        self.background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.background))
            } else {
                configuration.label
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .foregroundColor(Theme.background)
        .background(Theme.accentGradient)
        .cornerRadius(16)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(Theme.SpringConfig.snappy, value: configuration.isPressed)
        .onChange(of: configuration.isPressed) { oldValue, newValue in
            if newValue {
                HapticManager.shared.medium()
            }
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    var hapticStyle: HapticManager.HapticStyle = .light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Theme.SpringConfig.snappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    switch hapticStyle {
                    case .light:
                        HapticManager.shared.light()
                    case .medium:
                        HapticManager.shared.medium()
                    case .heavy:
                        HapticManager.shared.heavy()
                    }
                }
            }
    }
}

// MARK: - Floating Text Field

struct FloatingTextField: View {
    let label: String
    @Binding var text: String
    var isError: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isFocused || !text.isEmpty {
                Text(label)
                    .font(Theme.caption())
                    .foregroundColor(isError ? Theme.error : (isFocused ? Theme.accent : Theme.textSecondary))
                    .transition(.opacity)
            }

            TextField(isFocused || !text.isEmpty ? "" : label, text: $text)
                .font(Theme.body())
                .foregroundColor(Theme.textPrimary)
                .focused($isFocused)
                .padding(.bottom, 8)

            Rectangle()
                .fill(isError ? Theme.error : (isFocused ? Theme.accent : Theme.border))
                .frame(height: 2)
                .shadow(color: isFocused ? Theme.accent.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .animation(Theme.SpringConfig.snappy, value: isFocused)
        .animation(Theme.SpringConfig.snappy, value: isError)
        .onChange(of: isFocused) { oldValue, newValue in
            if newValue {
                HapticManager.shared.light()
            }
        }
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    var minOpacity: Double = 0.7
    var maxOpacity: Double = 1.0
    var duration: Double = 2.0

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? maxOpacity : minOpacity)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(minOpacity: Double = 0.7, maxOpacity: Double = 1.0, duration: Double = 2.0) -> some View {
        self.modifier(PulseModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
}

// MARK: - Shake Animation

struct ShakeModifier: ViewModifier {
    @Binding var shake: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: shake) { oldValue, newValue in
                if newValue {
                    performShake()
                }
            }
    }

    private func performShake() {
        let animation = Animation.spring(response: 0.3, dampingFraction: 0.3)

        withAnimation(animation) {
            offset = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animation) {
                offset = -10
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation) {
                offset = 5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(animation) {
                offset = -5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                offset = 0
                shake = false
            }
        }
    }
}

extension View {
    func shake(_ shake: Binding<Bool>) -> some View {
        self.modifier(ShakeModifier(shake: shake))
    }
}
