import SwiftUI

@main
struct MasarifiApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.layoutDirection, store.settings.lang == .ar ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: store.settings.lang == .ar ? "ar" : "en"))
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if store.onboarded {
                MainTabs().transition(.opacity)
            } else {
                WelcomeView().transition(.opacity)
            }
            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.06)))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.onboarded)
        .task {
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        }
        .onChange(of: store.persisted) { store.save() }
    }
}

/// Loading screen: only the bare logo, centred on the navy gradient.
struct SplashView: View {
    @State private var breathe = false

    var body: some View {
        ZStack {
            Palette.screen.ignoresSafeArea()
            LogoMark(size: 150, animated: true)
                .scaleEffect(breathe ? 1.04 : 1)
                .shadow(color: Color(hex: 0x3CC6D4, opacity: 0.3), radius: 30, y: 14)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.9)) { breathe = true }
                }
        }
    }
}

struct MainTabs: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        let t = store.t
        TabView(selection: $store.tab) {
            Tab(t.home, systemImage: "creditcard", value: AppTab.home) { HomeView() }
            Tab(t.transactions, systemImage: "arrow.up.arrow.down", value: AppTab.tx) { TransactionsView() }
            Tab(t.stats, systemImage: "chart.pie", value: AppTab.stats) { StatsView() }
            Tab(t.voice, systemImage: "mic", value: AppTab.voice) { VoiceView() }
            Tab(t.settings, systemImage: "square.grid.2x2", value: AppTab.settings) { SettingsView() }
        }
        .minimizeTabBarOnScroll()
        .modifier(QuickAddAccessory())
        .sensoryFeedback(.selection, trigger: store.tab)
        .sheet(item: $store.sheet) { sheet in
            switch sheet {
            case let .add(type, editID, prefill):
                AddSheet(initialType: type, editID: editID, prefill: prefill)
            case .month:
                MonthSheet().presentationDetents([.medium])
            case .notifications:
                NotificationsSheet().presentationDetents([.medium])
            case .voice:
                VoiceView(asSheet: true).presentationDetents([.large])
            }
        }
    }
}

/// Like Music's mini player: a glass bar above the tab bar to add an expense
/// by voice or by hand from any tab (iOS 26). It tucks in beside the tab bar
/// when the bar minimizes.
private struct QuickAddAccessory: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabViewBottomAccessory {
                HStack(spacing: 12) {
                    Button {
                        store.sheet = .voice
                    } label: {
                        Label(store.t.quickAdd, systemImage: "waveform")
                            .labelStyle(.titleAndIcon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button {
                        store.sheet = .add(.expense, editID: nil, prefill: nil)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .accessibilityLabel(store.t.withdraw)
                }
                .padding(.horizontal, 16)
                .foregroundStyle(Palette.ink)
            }
        } else {
            content
        }
    }
}
