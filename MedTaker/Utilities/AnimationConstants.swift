import SwiftUI

// MARK: - 動畫常數

struct AnimationConstants {
    // MARK: - 動畫時長

    /// 快速動畫（0.2 秒）
    static let quick: Double = 0.2

    /// 一般動畫（0.3 秒）
    static let normal: Double = 0.3

    /// 慢速動畫（0.5 秒）
    static let slow: Double = 0.5

    // MARK: - 彈簧動畫參數

    /// 彈簧響應時間
    static let springResponse: Double = 0.3

    /// 彈簧阻尼
    static let springDamping: Double = 0.7

    // MARK: - 預設動畫

    /// 預設緩動動畫
    static let `default` = Animation.easeInOut(duration: normal)

    /// 彈簧動畫
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)

    /// 快速彈簧動畫
    static let quickSpring = Animation.spring(response: 0.2, dampingFraction: 0.8)

    /// 平滑彈簧動畫
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.9)

    // MARK: - 特殊動畫

    /// 淡入動畫
    static func fadeIn(duration: Double = normal) -> Animation {
        .easeIn(duration: duration)
    }

    /// 淡出動畫
    static func fadeOut(duration: Double = normal) -> Animation {
        .easeOut(duration: duration)
    }

    /// 縮放動畫
    static func scale(duration: Double = normal) -> Animation {
        .easeInOut(duration: duration)
    }

    /// 延遲動畫
    static func delayed(_ delay: Double, animation: Animation = .default) -> Animation {
        animation.delay(delay)
    }
}

// MARK: - View 動畫修飾符

extension View {
    /// 按鈕按下縮放效果
    func pressableScale(scale: CGFloat = 0.95) -> some View {
        self.modifier(PressableScaleModifier(scale: scale))
    }

    /// 卡片點擊效果
    func cardTapAnimation() -> some View {
        self.modifier(CardTapModifier())
    }

    /// 淡入動畫
    func fadeIn(duration: Double = AnimationConstants.normal, delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(duration: duration, delay: delay))
    }

    /// 滑入動畫
    func slideIn(edge: Edge = .bottom, distance: CGFloat = 50, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(edge: edge, distance: distance, delay: delay))
    }

    /// 縮放進入動畫
    func scaleIn(delay: Double = 0) -> some View {
        self.modifier(ScaleInModifier(delay: delay))
    }

    /// 彈跳動畫
    func bounceEffect(trigger: some Equatable) -> some View {
        self.modifier(BounceEffectModifier(trigger: trigger))
    }

    /// 震動效果
    func shakeEffect(trigger: Int) -> some View {
        self.modifier(ShakeEffectModifier(shakes: trigger))
    }

    /// 閃爍效果
    func pulseEffect(active: Bool = true) -> some View {
        self.modifier(PulseEffectModifier(active: active))
    }
}

// MARK: - 按鈕按下縮放修飾符

struct PressableScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.quickSpring, value: isPressed)
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {}
            )
    }
}

// MARK: - 卡片點擊修飾符

struct CardTapModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(.quickSpring, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - 淡入修飾符

struct FadeInModifier: ViewModifier {
    let duration: Double
    let delay: Double
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - 滑入修飾符

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let distance: CGFloat
    let delay: Double
    @State private var offset: CGFloat
    @State private var opacity: Double = 0

    init(edge: Edge, distance: CGFloat, delay: Double) {
        self.edge = edge
        self.distance = distance
        self.delay = delay
        self._offset = State(initialValue: distance)
    }

    func body(content: Content) -> some View {
        let offsetX = edge == .leading ? -offset : (edge == .trailing ? offset : 0)
        let offsetY = edge == .top ? -offset : (edge == .bottom ? offset : 0)

        return content
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - 縮放進入修飾符

struct ScaleInModifier: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    scale = 1.0
                    opacity = 1
                }
            }
    }
}

// MARK: - 彈跳效果修飾符

struct BounceEffectModifier<T: Equatable>: ViewModifier {
    let trigger: T
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - 震動效果修飾符

struct ShakeEffectModifier: ViewModifier {
    let shakes: Int
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: shakes) { _, _ in
                withAnimation(.linear(duration: 0.1).repeatCount(3, autoreverses: true)) {
                    offset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    offset = 0
                }
            }
    }
}

// MARK: - 閃爍效果修飾符

struct PulseEffectModifier: ViewModifier {
    let active: Bool
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                if active {
                    startPulsing()
                }
            }
            .onChange(of: active) { _, newValue in
                if newValue {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            scale = 1.1
            opacity = 0.7
        }
    }

    private func stopPulsing() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
    }
}

// MARK: - 載入視圖

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

            Text("載入中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 骨架屏視圖

struct SkeletonView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat

    init(height: CGFloat = 50, cornerRadius: CGFloat = 8) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .overlay(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                }
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - 成功動畫視圖

struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 80, height: 80)
                .scaleEffect(scale)

            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkmarkScale)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1
                rotation = 360
            }
        }
    }
}
