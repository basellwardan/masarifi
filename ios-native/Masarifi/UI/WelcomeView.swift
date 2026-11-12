import PhotosUI
import SwiftUI

/// First run: logo, name and photo, starting balance, done. Same steps and
/// layout as the Android welcome.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @State private var step = 0
    @State private var dir: CGFloat = 1
    @State private var name = ""
    @State private var balance = ""
    @State private var photo: Data?
    @State private var picking = false
    @State private var picked: PhotosPickerItem?
    @State private var appeared = false
    @State private var checkIn = false

    var body: some View {
        let t = store.t
        let lang = store.settings.lang
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    store.settings.lang = lang == .ar ? .en : .ar
                } label: {
                    Text(lang == .ar ? "English" : "العربية")
                        .ui(13.5)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .contentShape(Capsule())
                }
                .buttonStyle(PressStyle(scale: 0.94))
                .darkGlass(Capsule(), interactive: true)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.4), value: appeared)
            }
            .padding(.horizontal, 20)
            .padding(.top, metrics.top + 10)

            VStack(spacing: 0) {
                LogoMark(size: 92, animated: true)
                    .frame(width: 132, height: 132)
                    .darkGlass(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .scaleEffect(appeared ? (step == 0 ? 1 : 0.72) : 0.7)
                    .rotationEffect(.degrees(appeared ? 0 : -8))
                    .opacity(appeared ? 1 : 0)
                    .animation(.framer(150, 16), value: appeared)
                    .animation(.framer(150, 16), value: step)
                Text(t.appName)
                    .ui(40, .bold)
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                    .modifier(Rise(index: 0, distance: 14, delay: 0.25))
                Text(t.tagline)
                    .ui(15.5)
                    .lineSpacing(15.5 * 0.6 - 4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: 300)
                    .modifier(Rise(index: 0, distance: 14, delay: 0.38))
            }
            .padding(.horizontal, 32)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { UIApplication.shared.endEditing() }

            card(t)
                .offset(y: appeared ? 0 : 300)
                .animation(.framer(170, 24).delay(0.3), value: appeared)
        }
        .background(Palette.screen.ignoresSafeArea())
        .ignoresSafeArea(.container)
        .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
        .onChange(of: picked) {
            guard let picked else { return }
            Task {
                if let data = try? await picked.loadTransferable(type: Data.self) { photo = PhotoTools.square(data) }
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: white card

    private func card(_ t: Strings) -> some View {
        let lang = store.settings.lang
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Color.black : Palette.grabber)
                        .frame(width: i == step ? 22 : 7, height: 7)
                }
            }
            .animation(.framer(400, 30), value: step)
            .padding(.bottom, 22)

            ZStack {
                stepView(t, lang)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .offset(x: 60 * dir * (lang == .ar ? -1 : 1)).combined(with: .opacity),
                        removal: .offset(x: -60 * dir * (lang == .ar ? -1 : 1)).combined(with: .opacity)
                    ))
            }
            .frame(minHeight: 150, alignment: .top)
            .animation(.framer(300, 30), value: step)

            GlassGroup {
                HStack(spacing: 8) {
                    if step > 0 && step < 3 {
                        PillButton(width: nil) { go(step - 1) } label: { Text(t.back) }
                            .frame(width: (metrics.width - 44 - 8) * 0.3)
                            .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
                    }
                    PillButton(black: true) {
                        step < 3 ? go(step + 1) : finish()
                    } label: {
                        Text(step == 0 ? t.start : step == 3 ? t.letsGo : t.next)
                    }
                }
                .animation(.framer(300, 30), value: step)
            }
            .padding(.top, 18)
        }
        .padding(.top, 28)
        .padding(.horizontal, 22)
        .padding(.bottom, metrics.bottom + 20)
        .frame(maxWidth: .infinity)
        .background(WhiteSheetShape().fill(.white).ignoresSafeArea(edges: .bottom))
        .clipped()
    }

    @ViewBuilder
    private func stepView(_ t: Strings, _ lang: Lang) -> some View {
        switch step {
        case 0:
            VStack(spacing: 6) {
                Text(lang == .ar ? "أهلاً فيك 👋" : "Welcome 👋").ui(23, .semibold).foregroundStyle(Palette.ink)
                Text(t.allSetHint)
                    .ui(14.5)
                    .lineSpacing(4)
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: 290)
            }
            .multilineTextAlignment(.center)
        case 1:
            VStack(spacing: 14) {
                Text(t.yourName).ui(22, .semibold).foregroundStyle(Palette.ink)
                HStack(spacing: 10) {
                    Button { picking = true } label: {
                        ZStack {
                            if let photo, let img = UIImage(data: photo) {
                                Image(uiImage: img).resizable().scaledToFill()
                            } else {
                                Icon(.camera, size: 20, stroke: 1.6).foregroundStyle(Palette.iconInk)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .background(Palette.iconBg)
                        .clipShape(Circle())
                    }
                    .buttonStyle(PressStyle(scale: 0.92))
                    .accessibilityLabel(t.addPhoto)
                    TextField("", text: $name, prompt: Text(t.namePlaceholder).foregroundStyle(Palette.muted))
                        .ui(15)
                        .submitLabel(.done)
                        .padding(.horizontal, 18)
                        .frame(height: 52)
                        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
                }
            }
        case 2:
            VStack(spacing: 10) {
                Text(t.startingBalance).ui(22, .semibold).foregroundStyle(Palette.ink)
                Text(t.startingHint).ui(12.5).foregroundStyle(Palette.muted)
                ZStack(alignment: .trailing) {
                    TextField("", text: $balance, prompt: Text("0").foregroundStyle(Palette.muted))
                        .keyboardType(.decimalPad)
                        .font(AppFont.num(28, .medium))
                        .multilineTextAlignment(.center)
                        .frame(height: 64)
                        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .circular))
                        .onChange(of: balance) {
                            let raw = SettingsView.clean(balance)
                            if raw != balance { balance = raw }
                        }
                    Text(Currency.symbol(store.settings.currency, lang))
                        .ui(12.5)
                        .foregroundStyle(Palette.muted)
                        .padding(.trailing, 18)
                        .allowsHitTesting(false)
                }
                .padding(.top, 6)
            }
            .multilineTextAlignment(.center)
        default:
            VStack(spacing: 10) {
                Icon(.check, size: 28, stroke: 2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.black))
                    .scaleEffect(checkIn ? 1 : 0.01)
                    .onAppear { withAnimation(.framer(260, 14).delay(0.1)) { checkIn = true } }
                    .onDisappear { checkIn = false }
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                Text(trimmed.isEmpty ? t.allSet : "\(t.allSet)، \(trimmed)")
                    .ui(22, .semibold)
                    .foregroundStyle(Palette.ink)
            }
        }
    }

    private func go(_ next: Int) {
        Haptic.tap()
        UIApplication.shared.endEditing()
        dir = next > step ? 1 : -1
        DispatchQueue.main.async { step = next }
    }

    private func finish() {
        Haptic.medium()
        let value = Double(balance) ?? 0
        store.profile = Profile(
            name: name.trimmingCharacters(in: .whitespaces),
            photo: photo,
            openingBalance: Currency.toNew(value, store.settings.currency, rate: store.settings.usdRate)
        )
        store.onboarded = true
    }
}

enum PhotoTools {
    /// Square-crops and shrinks a picked photo for the avatar.
    static func square(_ data: Data, size: CGFloat = 192) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let side = min(image.size.width, image.size.height)
        let crop = CGRect(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2, width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let out = renderer.image { _ in
            image.draw(in: CGRect(x: -crop.minX * size / side, y: -crop.minY * size / side,
                                  width: image.size.width * size / side, height: image.size.height * size / side))
        }
        return out.jpegData(compressionQuality: 0.85)
    }
}
