import SwiftUI

struct ContentView: View {
    @StateObject private var engine = EchoAudioEngine()

    var body: some View {
        VStack(spacing: 24) {
            Text("Echo Cancellation Test")
                .font(.title2)
                .bold()

            LevelMeter(level: engine.level)
                .frame(height: 24)

            Toggle("Echo Cancellation (AEC)", isOn: Binding(
                get: { engine.isAECEnabled },
                set: { engine.setAECEnabled($0) }
            ))

            VStack(alignment: .leading) {
                Text("Delay: \(engine.delaySeconds, specifier: "%.2f")s")
                Slider(value: $engine.delaySeconds, in: 0...2)
            }

            Button(engine.isRunning ? "Stop" : "Start") {
                engine.isRunning ? engine.stop() : engine.start()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let error = engine.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct LevelMeter: View {
    let level: Float

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                RoundedRectangle(cornerRadius: 4)
                    .fill(level > 0.85 ? .red : .green)
                    .frame(width: geo.size.width * CGFloat(level))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
    }
}
