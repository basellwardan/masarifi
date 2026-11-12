import PhotosUI
import SwiftUI

/// First run: logo and tagline on the navy gradient, and a white card at the
/// bottom that walks through welcome → name and photo → starting balance →
/// all set. The language button cross-fades the text when switched.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var dir: CGFloat = 1
    @State private var name = ""
    @State private var balance = ""
    @State private var photo: Data?
    @State private var picking = false
    @State private var picked: PhotosPickerItem?
    @State private var appeared = false
    @State private var checkIn = false
    @FocusState private var focused: Bool

    private enum Ink {
        static let text = Color(hex: 0x0B1220)
        static let muted = Color(hex: 0x6B7280)
        static let tile = Color(hex: 0xF1F3F6)
        static let dot = Color(hex: 0xD9DCE1)
    }

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        VStack(spacing: 0) {
            HStack {
                Spacer()
                langButton(lang)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            hero(t, lang)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { focused = false }

            card(t, lang)
                .offset(y: appeared ? 0 : 400)
                .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.3), value: appeared)
        }
        .background(Palette.screen.ignoresSafeArea())
        .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
        .onChange(of: picked) {
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self) { photo = PhotoTools.square(data) }
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: top

    private func langButton(_ lang: Lang) -> some View {
        Button(action: switchLang) {
            ZStack {
                Text(lang == .ar ? "English" : "العربية")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .id(lang)
                    .transition(.blurFade)
            }
            .padding(.horizontal, 18)
            .frame(height: 42)
            .contentShape(Capsule())
        }
        .buttonStyle(PressStyle(scale: 0.92))
        .glassEffect(.clear.tint(Palette.navy.opacity(0.4)).interactive(), in: .capsule)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(0.4), value: appeared)
    }

    private func hero(_ t: Strings, _ lang: Lang) -> some View {
        let compact = focused || step > 0
        return VStack(spacing: 0) {
            LogoMark(size: 92, animated: true)
                .frame(width: 132, height: 132)
                .glassEffect(.clear.tint(.white.opacity(0.06)), in: .rect(cornerRadius: 40, style: .continuous))
                .scaleEffect(appeared ? (focused ? 0.55 : compact ? 0.72 : 1) : 0.7)
                .rotationEffect(.degrees(appeared ? 0 : -8))
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.68), value: appeared)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: compact)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: focused)
                .frame(height: focused ? 80 : 132)

            // keyed by language so switching cross-fades with a soft blur
            ZStack {
                VStack(spacing: 10) {
                    Text(t.appName)
                        .font(.system(size: 40, weight: .bold))
                        .tracking(-0.8)
                        .foregroundStyle(.white)
                    if !focused {
                        Text(t.tagline)
                            .font(.system(size: 16))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(maxWidth: 320)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .id(lang)
                .transition(.blurFade)
            }
            .padding(.top, focused ? 8 : 22)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.25), value: appeared)
        }
        .padding(.horizontal, 32)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: focused)
    }

    // MARK: white card

    private func card(_ t: Strings, _ lang: Lang) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Ink.text : Ink.dot)
                        .frame(width: i == step ? 22 : 7, height: 7)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
            .padding(.bottom, 24)

            ZStack {
                ZStack {
                    stepView(t, lang)
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .offset(x: 60 * dir * (lang == .ar ? -1 : 1)).combined(with: .opacity),
                            removal: .offset(x: -60 * dir * (lang == .ar ? -1 : 1)).combined(with: .opacity)
                        ))
                }
                .id(lang)
                .transition(.blurFade)
            }
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .top)

            HStack(spacing: 10) {
                if step > 0 && step < 3 {
                    Button { go(step - 1) } label: {
                        Text(t.back)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Ink.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Ink.tile, in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PressStyle())
                    .frame(width: 112)
                    .transition(.opacity.combined(with: .scale(scale: 0.6)))
                }
                Button { step < 3 ? go(step + 1) : finish() } label: {
                    Text(step == 0 ? t.start : step == 3 ? t.letsGo : t.next)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Ink.text, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(PressStyle())
            }
            .padding(.top, 18)
        }
        .padding(.top, 26)
        .padding(.horizontal, 22)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 44, topTrailingRadius: 44, style: .continuous)
                .fill(.white)
                .ignoresSafeArea(edges: .bottom)
        )
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private func stepView(_ t: Strings, _ lang: Lang) -> some View {
        switch step {
        case 0:
            VStack(spacing: 8) {
                Text(t.welcome)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Ink.text)
                Text(t.allSetHint)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(Ink.muted)
                    .frame(maxWidth: 300)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 10)
        case 1:
            VStack(spacing: 14) {
                Text(t.yourName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Ink.text)
                HStack(spacing: 10) {
                    Button { picking = true } label: {
                        ZStack {
                            if let photo, let img = UIImage(data: photo) {
                                Image(uiImage: img).resizable().scaledToFill()
                            } else {
                                Image(systemName: "camera")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundStyle(Ink.text)
                            }
                        }
                        .frame(width: 54, height: 54)
                        .background(Ink.tile)
                        .clipShape(Circle())
                    }
                    .buttonStyle(PressStyle(scale: 0.92))
                    .accessibilityLabel(t.addPhoto)
                    TextField("", text: $name, prompt: Text(t.namePlaceholder).foregroundStyle(Ink.muted))
                        .font(.system(size: 16))
                        .foregroundStyle(Ink.text)
                        .submitLabel(.done)
                        .focused($focused)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(Ink.tile, in: Capsule())
                }
            }
        case 2:
            VStack(spacing: 8) {
                Text(t.startingBalance)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Ink.text)
                Text(t.startingHint)
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.muted)
                ZStack(alignment: .trailing) {
                    TextField("", text: $balance, prompt: Text("0").foregroundStyle(Ink.muted))
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Ink.text)
                        .multilineTextAlignment(.center)
                        .focused($focused)
                        .frame(height: 64)
                        .background(Ink.tile, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .onChange(of: balance) {
                            let raw = SettingsView.clean(balance)
                            if raw != balance { balance = raw }
                        }
                    Text(Currency.symbol(store.settings.currency, lang))
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.muted)
                        .padding(.trailing, 18)
                        .allowsHitTesting(false)
                }
                .environment(\.layoutDirection, .leftToRight)
                .padding(.top, 6)
            }
            .multilineTextAlignment(.center)
        default:
            VStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Ink.text))
                    .scaleEffect(checkIn ? 1 : 0.01)
                    .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { checkIn = true } }
                    .onDisappear { checkIn = false }
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                Text(trimmed.isEmpty ? t.allSet : "\(t.allSet)\(lang == .ar ? "،" : ",") \(trimmed)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Ink.text)
            }
        }
    }

    // MARK: actions

    private func switchLang() {
        Haptic.tap()
        let next: Lang = store.settings.lang == .ar ? .en : .ar
        withAnimation(.smooth(duration: 0.5)) { store.settings.lang = next }
    }

    private func go(_ next: Int) {
        Haptic.tap()
        focused = false
        dir = next > step ? 1 : -1
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { step = next }
    }

    private func finish() {
        Haptic.success()
        let value = Double(balance) ?? 0
        store.profile = Profile(
            name: name.trimmingCharacters(in: .whitespaces),
            photo: photo,
            openingBalance: Currency.toNew(value, store.settings.currency, rate: store.settings.usdRate)
        )
        store.onboarded = true
    }
}

/// Shrinks a little while pressed.
struct PressStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Fade with a soft blur and slight scale, used when the language changes.
private struct BlurFade: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: active ? 8 : 0)
            .opacity(active ? 0 : 1)
            .scaleEffect(active ? 0.96 : 1)
    }
}

extension AnyTransition {
    static var blurFade: AnyTransition {
        .modifier(active: BlurFade(active: true), identity: BlurFade(active: false))
    }
}
