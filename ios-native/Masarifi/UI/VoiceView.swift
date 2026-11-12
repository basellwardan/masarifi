import SwiftUI

/// Voice entry: tap the glass mic, speak, and the app works out whether money
/// came in or went out, the amount, and keeps your exact words.
struct VoiceView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var asSheet = false

    @State private var listener = SpeechListener()
    @State private var result: ParsedVoice?
    @State private var message: String?
    @Namespace private var glass

    var body: some View {
        let t = store.t
        NavigationStack {
            ZStack {
                Palette.screen.ignoresSafeArea()
                VStack(spacing: 26) {
                    Spacer()
                    GlassGroup(spacing: 30) {
                        VStack(spacing: 30) {
                            micButton(t)
                            if let result, let amount = amountNew(result) {
                                resultCard(result, amount: amount, t: t)
                                    .glassID("result", in: glass)
                            }
                        }
                    }
                    status(t)
                    if result == nil && !listener.isListening {
                        examples(t)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, asSheet ? 20 : 90)
            }
            .navigationTitle(t.voice)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if asSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { listener.cancel(); dismiss() } label: { Image(systemName: "xmark") }
                    }
                }
            }
        }
        .onDisappear { listener.cancel() }
        .onChange(of: listener.failure) {
            switch listener.failure {
            case .denied: message = t.micDenied
            case .unavailable: message = t.micUnavailable
            case .failed: message = t.didntCatch
            case nil: break
            }
        }
    }

    private func micButton(_ t: Strings) -> some View {
        Button {
            if listener.isListening {
                listener.stop()
            } else {
                Haptic.tap()
                withAnimation(.snappy) { result = nil; message = nil }
                listener.start(lang: store.settings.lang) { text in handle(text) }
            }
        } label: {
            ZStack {
                // rings that swell with your voice
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .stroke(.white.opacity(listener.isListening ? 0.22 - Double(i) * 0.08 : 0), lineWidth: 1.5)
                        .scaleEffect(listener.isListening ? 1.12 + listener.level * (0.25 + CGFloat(i) * 0.2) : 1)
                        .animation(.easeOut(duration: 0.18), value: listener.level)
                }
                Image(systemName: listener.isListening ? "stop.fill" : "mic")
                    .font(.system(size: listener.isListening ? 34 : 46, weight: .light))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.white)
            }
            .frame(width: 176, height: 176)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .liquidGlass(Circle(), tint: listener.isListening ? Color(hex: 0x3CC6D4, opacity: 0.25) : nil, interactive: true, clear: true)
        .glassID("mic", in: glass)
        .scaleEffect(listener.isListening ? 1.05 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: listener.isListening)
        .accessibilityLabel(t.tapToSpeak)
    }

    private func status(_ t: Strings) -> some View {
        VStack(spacing: 8) {
            Text(listener.isListening ? (listener.transcript.isEmpty ? t.listening : "“\(listener.transcript)”")
                 : (result == nil ? t.tapToSpeak : ""))
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .contentTransition(.opacity)
            if let message {
                Text(message).font(.subheadline).foregroundStyle(Color(hex: 0xFFD2D2)).multilineTextAlignment(.center)
            } else if result == nil && !listener.isListening {
                Text(t.voiceHint).font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center)
            }
        }
        .animation(.snappy, value: listener.transcript)
    }

    private func examples(_ t: Strings) -> some View {
        GlassGroup(spacing: 10) {
            VStack(spacing: 8) {
                ForEach(t.voiceExamples, id: \.self) { example in
                    Button(example) { handle(example) }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .liquidGlass(Capsule(), interactive: true, clear: true)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func resultCard(_ r: ParsedVoice, amount: Double, t: Strings) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label(r.type == .expense ? t.expense : t.incomeOne,
                      systemImage: r.type == .expense ? "arrow.up.right" : "arrow.down.right")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: IconHints.symbol(for: r.note, type: r.type))
            }
            .foregroundStyle(.white.opacity(0.85))
            MoneyText(value: amount, size: 40, weight: .semibold, color: .white,
                      fracColor: .white.opacity(0.55), symbolColor: .white.opacity(0.75))
            Text(r.note)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button(t.edit) { edit(r, amount: amount) }
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                    .glassButton()
                    .tint(.white)
                Button(t.confirm) { confirm(r, amount: amount) }
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                    .glassButton(prominent: true)
                    .tint(Palette.blue)
            }
            .font(.headline)
        }
        .padding(20)
        .liquidGlass(RoundedRectangle(cornerRadius: 30, style: .continuous), clear: true)
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    private func amountNew(_ r: ParsedVoice) -> Double? {
        guard let a = r.amount else { return nil }
        return Currency.toNew(a, r.unit ?? store.settings.currency, rate: store.settings.usdRate)
    }

    private func handle(_ text: String) {
        guard !text.isEmpty else { return }
        let parsed = VoiceParser.parse(text)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            result = parsed
            message = parsed.amount == nil ? store.t.didntCatch : nil
        }
    }

    private func confirm(_ r: ParsedVoice, amount: Double) {
        Haptic.success()
        withAnimation { store.addTx(type: r.type, amount: amount, note: r.note) }
        result = nil
        if asSheet { dismiss() } else { store.tab = .home }
    }

    private func edit(_ r: ParsedVoice, amount: Double) {
        result = nil
        let sheet = ActiveSheet.add(r.type, editID: nil, prefill: .init(amount: amount, note: r.note))
        if asSheet {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { store.sheet = sheet }
        } else {
            store.sheet = sheet
        }
    }
}
