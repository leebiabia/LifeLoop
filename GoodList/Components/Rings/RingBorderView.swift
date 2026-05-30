import SwiftUI

struct RingBorderView<Content: View>: View {
    let progress: Double        // 0...1
    let color: Color
    let ringWidth: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var animatedProgress: Double = 0

    var body: some View {
        content()
            .padding(ringWidth + 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20 + ringWidth / 2)
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(ringWidth / 2)
            )
            .padding(ringWidth)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = newValue
                }
            }
    }
}
