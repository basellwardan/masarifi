import SwiftUI

/// Voice entry: tap the glass mic, speak, and the app works out whether money
/// came in or went out, the amount, and keeps your exact words.
struct VoiceView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics

    @State private var listener = SpeechListener()
    @State private var text = ""
    @State private var result: ParsedVoice?
    @State private var error = ""
    @State private var micIn = false

    var body: some View {
        let t = store.t
        let listening = listener.isListening
        let amount = result.flatMap { amountNew($0) }
        let showSheet = amount != nil

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                GradHeader(title: t.voice)

                VStack(spacing: 26) {
                    mic(listening, t)
                    status(listening, t)
                        .frame(minHeight: 90, alignment: .top)
                    if !listening && !showSheet {
                        examples(t)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 28)
                .frame(maxHeight: .infinity)

                Color.clear.frame(height: metrics.bottom + 90)
            }

            if let result, let amount {
                resultSheet(result, amount: amount, t: t)
                    .transition(.move(edge: .bottom))
                    .zIndex(5)
            }
        }
        .background(Palette.screen)
        .animation(.framer(260, 30), value: showSheet)
        .animation(.easeOut(duration: 0.2), value: listening)
        .onDisappear { listener.cancel() }
        .onChange(of: listener.transcript) {
            if listener.isListening { text = listener.transcript }
        }
        .onChange(of: listener.failure) {
            switch listener.failure {
            case .denied: error = t.micDenied
            case .unavailable: error = t.micUnavailable
            case .failed: error = t.didntCatch
            case nil: break
            }
        }
    }

    // MARK: pieces

    private func mic(_ listening: Bool, _ t: Strings) -> some View {
        ZStack {
            if listening {
                ForEach(0..<3, id: \.self) { i in
                    PulseRing(delay: Double(i) * 0.8)
                }
            }
            Button(action: toggle) {
                ZStack {
                    if listening {
                        Icon(.square, size: 34, stroke: 1.4, filled: true)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    } else {
                        Icon(.mic, size: 46, stroke: 1.3)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 180, height: 180)
                .contentShape(Circle())
                .animation(.easeOut(duration: 0.18), value: listening)
            }
            .buttonStyle(PressStyle(scale: 0.94))
            .darkGlass(Circle(), fill: 0.12, interactive: true)
            .scaleEffect(micIn ? (listening ? 1.06 : 1) : 0.6)
            .opacity(micIn ? 1 : 0)
            .animation(.framer(220, 16), value: listening)
            .accessibilityLabel(t.tapToSpeak)
        }
        .frame(width: 180, height: 180)
        .onAppear { withAnimation(.framer(220, 16)) { micIn = true } }
    }

    private func status(_ listening: Bool, _ t: Strings) -> some View {
        let key = listening ? "l" : !text.isEmpty ? "tx" : !error.isEmpty ? "e" : "idle"
        return VStack(spacing: 8) {
            Text(listening ? (text.isEmpty ? t.listening : "“\(text)”") : !text.isEmpty ? "“\(text)”" : t.tapToSpeak)
                .ui(20, .semibold)
                .foregroundStyle(.white)
            let sub = !error.isEmpty ? error : (text.isEmpty && !listening ? t.voiceHint : "")
            if !sub.isEmpty {
                Text(sub)
                    .ui(14.5)
                    .foregroundStyle(!error.isEmpty ? Color(hex: 0xFFD2D2) : .white.opacity(0.65))
            }
        }
        .multilineTextAlignment(.center)
        .id(key)
        .transition(.asymmetric(insertion: .offset(y: 8).combined(with: .opacity),
                                removal: .offset(y: -8).combined(with: .opacity)))
        .animation(.easeOut(duration: 0.2), value: key)
    }

    private func examples(_ t: Strings) -> some View {
        GlassGroup {
            FlowLayout(spacing: 8) {
                ForEach(Array(t.voiceExamples.enumerated()), id: \.offset) { i, example in
                    Button { handle(example) } label: {
                        Text(example)
                            .ui(13.5)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PressStyle(scale: 0.95))
                    .darkGlass(Capsule(), interactive: true)
                    .modifier(Rise(index: i, distance: 10, delay: 0.15 + Double(i) * 0.07))
                }
            }
        }
    }

    private func resultSheet(_ r: ParsedVoice, amount: Double, t: Strings) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(r.type == .expense ? t.expense : t.incomeOne).ui(23, .semibold).foregroundStyle(Palette.ink)
                Spacer()
                Button(t.cancel) { result = nil }
                    .buttonStyle(.plain)
                    .ui(16)
                    .foregroundStyle(Palette.muted)
            }
            MoneyView(value: amount, style: .big(metrics.width))
                .padding(.top, 14)
                .padding(.bottom, 18)
            HStack(alignment: .top, spacing: 8) {
                Text(r.note)
                    .ui(15, .semibold)
                    .foregroundStyle(Palette.ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Icon(IconHints.icon(for: r.note, type: r.type), size: 18, stroke: 1.6)
                    .foregroundStyle(Palette.tileIcon)
            }
            .padding(16)
            .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
            GlassGroup {
                HStack(spacing: 8) {
                    PillButton { edit(r, amount: amount) } label: { Text(t.edit) }
                    PillButton(black: true) { confirm(r, amount: amount) } label: { Text(t.confirm) }
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, metrics.bottom + 92)
        .background(
            WhiteSheetShape()
                .fill(.white)
                .shadow(color: Color(hex: 0x050F33, opacity: 0.18), radius: 15, y: -8)
        )
    }

    // MARK: actions

    private func amountNew(_ r: ParsedVoice) -> Double? {
        guard let a = r.amount else { return nil }
        let v = Currency.toNew(a, r.unit ?? store.settings.currency, rate: store.settings.usdRate)
        return v > 0 ? v : nil
    }

    private func toggle() {
        if listener.isListening {
            listener.stop()
            return
        }
        Haptic.medium()
        result = nil
        error = ""
        text = ""
        listener.start(lang: store.settings.lang) { spoken in
            if !spoken.isEmpty { handle(spoken) }
        }
    }

    private func handle(_ spoken: String) {
        text = spoken
        let p = VoiceParser.parse(spoken)
        result = p
        error = p.amount == nil ? store.t.didntCatch : ""
    }

    private func confirm(_ r: ParsedVoice, amount: Double) {
        Haptic.medium()
        withAnimation(.framer(300, 30)) { store.addTx(type: r.type, amount: amount, note: r.note) }
        store.showToast(store.t.saved)
        result = nil
        text = ""
        store.setTab(.home)
    }

    private func edit(_ r: ParsedVoice, amount: Double) {
        store.openSheet(.add(r.type, editID: nil, prefill: .init(amount: amount, note: r.note)))
        result = nil
        text = ""
    }
}

/// Soft ring that swells out of the mic bubble while listening.
private struct PulseRing: View {
    let delay: Double
    @State private var go = false

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.white.opacity(0.2), .white.opacity(0.06)],
                                 center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: 90))
            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            .frame(width: 180, height: 180)
            .scaleEffect(go ? 1.9 : 1)
            .opacity(go ? 0 : 0.6)
            .onAppear {
                withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(delay)) { go = true }
            }
            .allowsHitTesting(false)
    }
}
