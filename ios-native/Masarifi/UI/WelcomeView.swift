import PhotosUI
import SwiftUI

/// First run: logo, name, starting balance. Same steps as the Android welcome.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var balance = ""
    @State private var photo: Data?
    @State private var picked: PhotosPickerItem?
    @Namespace private var glass

    var body: some View {
        let t = store.t
        ZStack {
            Palette.screen.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(store.settings.lang == .ar ? "English" : "العربية") {
                        withAnimation(.snappy) { store.settings.lang = store.settings.lang == .ar ? .en : .ar }
                    }
                    .glassButton()
                    .tint(.white)
                }
                .padding(.horizontal, 20)

                Spacer()
                VStack(spacing: 18) {
                    LogoMark(size: step == 0 ? 120 : 88, animated: true)
                        .padding(22)
                        .liquidGlass(RoundedRectangle(cornerRadius: 40, style: .continuous), clear: true)
                    Text(t.appName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                    Text(t.tagline)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: step)
                Spacer()

                card(t)
            }
        }
        .onChange(of: picked) {
            Task {
                if let data = try? await picked?.loadTransferable(type: Data.self) { photo = PhotoTools.square(data) }
            }
        }
    }

    private func card(_ t: Strings) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(i <= step ? Palette.ink : Color(hex: 0xD9DADD))
                        .frame(width: i == step ? 22 : 7, height: 7)
                }
            }
            Group {
                switch step {
                case 0:
                    VStack(spacing: 8) {
                        Text(t.welcome).font(.title2.weight(.semibold))
                        Text(t.allSetHint).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    }
                case 1:
                    VStack(spacing: 14) {
                        Text(t.yourName).font(.title3.weight(.semibold))
                        HStack(spacing: 10) {
                            PhotosPicker(selection: $picked, matching: .images) {
                                Group {
                                    if let photo, let img = UIImage(data: photo) {
                                        Image(uiImage: img).resizable().scaledToFill()
                                    } else {
                                        Image(systemName: "camera").foregroundStyle(Palette.muted)
                                    }
                                }
                                .frame(width: 52, height: 52)
                                .background(Palette.tile)
                                .clipShape(Circle())
                            }
                            .accessibilityLabel(t.addPhoto)
                            TextField(t.namePlaceholder, text: $name)
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                case 2:
                    VStack(spacing: 10) {
                        Text(t.startingBalance).font(.title3.weight(.semibold))
                        Text(t.startingHint).font(.subheadline).foregroundStyle(Palette.muted)
                        HStack {
                            TextField("0", text: $balance)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 28, weight: .medium).monospacedDigit())
                                .multilineTextAlignment(.center)
                            Text(Currency.symbol(store.settings.currency, store.settings.lang))
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 64)
                        .background(Palette.tile, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                default:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Palette.ink, in: Circle())
                            .transition(.scale)
                        Text(name.isEmpty ? t.allSet : "\(t.allSet)\(t.lang == .ar ? "،" : ",") \(name)")
                            .font(.title3.weight(.semibold))
                    }
                }
            }
            .frame(minHeight: 140)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
            .id(step)

            GlassGroup(spacing: 12) {
                HStack(spacing: 10) {
                    if step > 0 && step < 3 {
                        Button(t.back) { go(step - 1) }
                            .font(.headline)
                            .frame(maxWidth: 110)
                            .controlSize(.large)
                            .glassButton()
                            .tint(Palette.ink)
                            .glassID("back", in: glass)
                    }
                    Button(step == 0 ? t.start : step == 3 ? t.letsGo : t.next) {
                        step < 3 ? go(step + 1) : finish()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                    .glassButton(prominent: true)
                    .tint(Palette.ink)
                    .glassID("next", in: glass)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .background(.white, in: UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
        .clipped()
    }

    private func go(_ next: Int) {
        Haptic.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = next }
    }

    private func finish() {
        Haptic.success()
        let value = Double(balance.replacingOccurrences(of: ",", with: ".")) ?? 0
        store.profile = Profile(
            name: name.trimmingCharacters(in: .whitespaces),
            photo: photo,
            openingBalance: Currency.toNew(value, store.settings.currency, rate: store.settings.usdRate)
        )
        withAnimation { store.onboarded = true }
    }
}

enum PhotoTools {
    /// Square-crops and shrinks a picked photo for the avatar.
    static func square(_ data: Data, size: CGFloat = 192) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let side = min(image.size.width, image.size.height)
        let crop = CGRect(x: (image.size.width - side) / 2, y: (image.size.height - side) / 2, width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let out = renderer.image { _ in
            image.draw(in: CGRect(x: -crop.minX * size / side, y: -crop.minY * size / side,
                                  width: image.size.width * size / side, height: image.size.height * size / side))
        }
        return out.jpegData(compressionQuality: 0.85)
    }
}
