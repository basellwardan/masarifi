import SwiftUI

@main
struct MasarifiApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .modifier(AppDirection())
                .environment(store)
                .tint(Palette.brand)
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active { store.saveNow() }
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            if store.onboarded {
                // Rebuilt when the language changes: UIKit-backed lists keep
                // their old direction otherwise and draw their text mirrored.
                MainTabs()
                    .id(store.settings.lang)
                    .transition(.opacity)
            } else {
                WelcomeView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: store.onboarded)
        .animation(.easeInOut(duration: 0.3), value: store.settings.lang)
    }
}

/// Applies the app language's direction and locale (sheets get their own
/// hosting controller, so they need it again).
struct AppDirection: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, store.settings.lang == .ar ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: store.settings.lang == .ar ? "ar" : "en"))
    }
}

/// Three screens (Home, Transactions + Statistics, Settings) under a small
/// centred glass tab bar, with the "Say an expense…" bar above it.
struct MainTabs: View {
    @Environment(AppStore.self) private var store
    @Namespace private var zoom

    var body: some View {
        @Bindable var store = store
        ZStack {
            page(.home) { HomeView(zoom: zoom) }
            page(.activity) { ActivityTab(zoom: zoom) }
            page(.settings) { SettingsView() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                QuickAddBar(zoom: zoom)
                    .padding(.horizontal, 20)
                TabBarPill()
            }
            .padding(.bottom, 2)
        }
        .sensoryFeedback(.selection, trigger: store.tab)
        .sheet(item: $store.sheet) { sheet in
            Group {
                switch sheet {
                case let .add(type, editID, prefill):
                    AddSheet(initialType: type, editID: editID, prefill: prefill)
                case .month:
                    MonthSheet()
                case .notifications:
                    NotificationsSheet()
                case .voice:
                    VoiceSheet()
                }
            }
            .modifier(AppDirection())
            .navigationTransition(.zoom(sourceID: store.sheetSource, in: zoom))
        }
        .overlay(alignment: .top) { ToastView() }
    }

    /// Keeps every screen alive (scroll position, filters) and shows one.
    private func page<Content: View>(_ tab: AppTab, @ViewBuilder _ content: () -> Content) -> some View {
        let on = store.tab == tab
        return content()
            .opacity(on ? 1 : 0)
            .allowsHitTesting(on)
            .accessibilityHidden(!on)
            .zIndex(on ? 1 : 0)
    }
}

/// Centred Liquid Glass capsule with the three tabs; the selection slides
/// between them.
struct TabBarPill: View {
    @Environment(AppStore.self) private var store
    @Namespace private var pill

    var body: some View {
        let t = store.t
        HStack(spacing: 0) {
            item(.home, t.home, "creditcard.fill")
            item(.activity, t.transactions, "list.bullet.rectangle.portrait.fill")
            item(.settings, t.settings, "gearshape.fill")
        }
        .padding(4)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func item(_ tab: AppTab, _ title: String, _ symbol: String) -> some View {
        let on = store.tab == tab
        return Button {
            guard !on else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { store.tab = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .symbolEffect(.bounce.down, value: on)
                    .frame(height: 24)
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(on ? Palette.brandBright : Color.primary)
            .frame(width: 86, height: 54)
            .background {
                if on {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .matchedGeometryEffect(id: "selection", in: pill)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

/// "Say an expense…" glass bar above the tab bar.
struct QuickAddBar: View {
    @Environment(AppStore.self) private var store
    var zoom: Namespace.ID

    var body: some View {
        let t = store.t
        HStack(spacing: 12) {
            Button {
                Haptic.tap()
                store.openSheet(.voice, from: "voice")
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.brandBright)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeat(.periodic(delay: 2)))
                    Text(t.quickAdd)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: "voice", in: zoom)

            Button {
                Haptic.tap()
                store.openSheet(.add(.expense, editID: nil, prefill: nil), from: "quick-add")
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: "quick-add", in: zoom)
            .accessibilityLabel(t.withdraw)
        }
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .frame(height: 50)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
