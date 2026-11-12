import SwiftUI

/// Voice entry, opened from the bar above the tab bar: tap the glass mic,
/// speak, and the app works out the amount and whether money came in or out.
struct VoiceSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var listener = SpeechListener()
    @State private var text = ""
    @State private var result: ParsedVoice?
    @State private var error = ""
    @Namespace private var glass

    var body: some View {
        let t = store.t
        let listening = listener.isListening
        let amount = result.flatMap { amountNew($0) }

        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    GlassEffectContainer(spacing: 30) {
                        VStack(spacing: 30) {
                            mic(listening, t)
                            if let result, let amount {
                                resultCard(result, amount: amount, t: t)
                                    .glassEffectID("result", in: glass)
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        Text(listening ? (text.isEmpty ? t.listening : "“\(text)”") : (!text.isEmpty ? "“\(text)”" : t.tapToSpeak))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .contentTransition(.opacity)
                        let sub = !error.isEmpty ? error : (text.isEmpty && !listening ? t.voiceHint : "")
                        if !sub.isEmpty {
                            Text(sub)
                                .font(.subheadline)
                                .foregroundStyle(!error.isEmpty ? Color(hex: 0xFFD2D2) : .white.opacity(0.7))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .animation(.snappy, value: text)

                    if !listening && amount == nil {
                        GlassEffectContainer(spacing: 8) {
                            FlowLayout(spacing: 8) {
                                ForEach(t.voiceExamples, id: \.self) { example in
                                    Button(example) { handle(example) }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                        .buttonStyle(.glass)
                                        .tint(.white.opacity(0.1))
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 30)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Palette.screen.ignoresSafeArea())
            .navigationTitle(t.voice)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        listener.cancel()
                        dismiss()
                    } label: { Image(systemName: "xmark") }
                }
            }
        }
        .tint(.white)
        .presentationDetents([.large])
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: amount != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: listening)
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

    private func mic(_ listening: Bool, _ t: Strings) -> some View {
        Button(action: toggle) {
            ZStack {
                // rings that swell with your voice
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(.white.opacity(listening ? 0.25 - Double(i) * 0.1 : 0), lineWidth: 1.5)
                        .scaleEffect(listening ? 1.1 + listener.level * (0.25 + CGFloat(i) * 0.2) : 1)
                        .animation(.easeOut(duration: 0.15), value: listener.level)
                }
                Image(systemName: listening ? "stop.fill" : "mic.fill")
                    .font(.system(size: listening ? 40 : 54, weight: .medium))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 176, height: 176)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(listening ? .clear.tint(Palette.teal.opacity(0.3)).interactive() : .clear.interactive(), in: .circle)
        .glassEffectID("mic", in: glass)
        .scaleEffect(listening ? 1.05 : 1)
        .sensoryFeedback(.start, trigger: listening) { _, new in new }
        .accessibilityLabel(t.tapToSpeak)
    }

    private func resultCard(_ r: ParsedVoice, amount: Double, t: Strings) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CategoryIcon(icon: IconHints.icon(for: r.note, type: r.type), size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.type == .expense ? t.expense : t.incomeOne)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(r.note)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MoneyText(amount, size: 40, weight: .bold, relativeTo: .largeTitle)
                .foregroundStyle(.white)
            HStack(spacing: 10) {
                Button { edit(r, amount: amount) } label: {
                    Text(t.edit).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .foregroundStyle(.white)
                Button { confirm(r, amount: amount) } label: {
                    Text(t.confirm).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(Palette.teal)
            }
            .font(.headline)
            .controlSize(.large)
        }
        .padding(20)
        .glassEffect(.clear.tint(.white.opacity(0.06)), in: .rect(cornerRadius: 32, style: .continuous))
        .transition(.scale(scale: 0.7).combined(with: .opacity))
    }

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
        Haptic.success()
        withAnimation(.snappy) { store.addTx(type: r.type, amount: amount, note: r.note) }
        store.showToast(store.t.saved)
        dismiss()
    }

    private func edit(_ r: ParsedVoice, amount: Double) {
        dismiss()
        let sheet = ActiveSheet.add(r.type, editID: nil, prefill: .init(amount: amount, note: r.note))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { store.openSheet(sheet, from: "voice") }
    }
}
