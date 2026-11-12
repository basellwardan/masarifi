import PhotosUI
import SwiftUI

/// First run, in the style of Apple's welcome screens: what the app does,
/// then your name and photo, then how much you have now.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var balance = ""
    @State private var photo: Data?
    @State private var picked: PhotosPickerItem?
    @State private var appeared = false
    @FocusState private var focused: Bool
    @Namespace private var glass

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    LogoMark(size: step == 0 ? 84 : 60, animated: true)
                        .padding(step == 0 ? 24 : 16)
                        .glassEffect(.clear, in: .rect(cornerRadius: step == 0 ? 36 : 26, style: .continuous))
                        .padding(.top, step == 0 ? 36 : 16)
                    Text(step == 0 ? t.appName : step == 1 ? t.yourName : t.startingBalance)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .contentTransition(.opacity)
                    if step == 2 {
                        Text(t.startingHint).font(.body).foregroundStyle(.white.opacity(0.7)).padding(.top, 6)
                    }

                    Group {
                        switch step {
                        case 0: features(t)
                        case 1: nameStep(t)
                        default: balanceStep(lang)
                        }
                    }
                    .padding(.top, 32)
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: lang == .ar ? .leading : .trailing).combined(with: .opacity),
                                            removal: .move(edge: lang == .ar ? .trailing : .leading).combined(with: .opacity)))
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.screen.ignoresSafeArea())
            .safeAreaBar(edge: .bottom) {
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        if step > 0 {
                            Button { go(step - 1) } label: {
                                Image(systemName: lang == .ar ? "chevron.right" : "chevron.left")
                                    .font(.headline)
                                    .frame(width: 30)
                            }
                            .buttonStyle(.glass)
                            .glassEffectID("back", in: glass)
                            .accessibilityLabel(t.back)
                        }
                        Button { step < 2 ? go(step + 1) : finish() } label: {
                            Text(step == 0 ? t.continueTitle : step == 2 ? t.letsGo : t.next)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .glassEffectID("next", in: glass)
                    }
                    .controlSize(.extraLarge)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang == .ar ? "English" : "العربية") {
                        withAnimation(.snappy) { store.settings.lang = lang == .ar ? .en : .ar }
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(Palette.brand)
        .onChange(of: picked) {
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self) { photo = PhotoTools.square(data) }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) { appeared = true } }
    }

    // MARK: steps

    private func features(_ t: Strings) -> some View {
        VStack(alignment: .leading, spacing: 26) {
            feature("waveform", Palette.teal, t.feat1, t.feat1Sub)
            feature("banknote.fill", .green, t.feat2, t.feat2Sub)
            feature("lock.iphone", .orange, t.feat3, t.feat3Sub)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feature(_ symbol: String, _ color: Color, _ title: String, _ sub: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(sub).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func nameStep(_ t: Strings) -> some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $picked, matching: .images) {
                ZStack {
                    if let photo, let img = UIImage(data: photo) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .glassEffect(.clear.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t.addPhoto)
            TextField("", text: $name, prompt: Text(t.namePlaceholder).foregroundStyle(.white.opacity(0.5)))
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .focused($focused)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .glassEffect(.clear, in: .capsule)
        }
    }

    private func balanceStep(_ lang: Lang) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            TextField("", text: $balance, prompt: Text("0").foregroundStyle(.white.opacity(0.4)))
                .keyboardType(.decimalPad)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .focused($focused)
                .fixedSize()
                .onChange(of: balance) {
                    let raw = SettingsView.clean(balance)
                    if raw != balance { balance = raw }
                }
            Text(Currency.symbol(store.settings.currency, lang))
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassEffect(.clear, in: .rect(cornerRadius: 28, style: .continuous))
    }

    private func go(_ next: Int) {
        Haptic.tap()
        focused = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = next }
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
