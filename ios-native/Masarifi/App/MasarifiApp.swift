import SwiftUI

@main
struct MasarifiApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.appLang, store.settings.lang)
                .environment(\.layoutDirection, store.settings.lang == .ar ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: store.settings.lang == .ar ? "ar" : "en"))
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active { store.saveNow() }
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var splashDone = false
    @State private var metrics = Metrics()

    var body: some View {
        ZStack {
            Palette.navy800.ignoresSafeArea()
            if !splashDone {
                SplashView()
                    .transition(.asymmetric(insertion: .identity,
                                            removal: .opacity.combined(with: .scale(scale: 1.06))))
                    .zIndex(3)
            } else if !store.onboarded {
                WelcomeView()
                    .transition(.asymmetric(insertion: .opacity,
                                            removal: .opacity.combined(with: .scale(scale: 0.98))))
                    .zIndex(2)
            } else {
                MainView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(\.metrics, metrics)
        .animation(.easeInOut(duration: 0.4), value: store.onboarded)
        .onAppear { metrics = Metrics.current() }
        .task {
            // the splash stays at least 1.5 s, like the Android build
            try? await Task.sleep(for: .milliseconds(1500))
            metrics = Metrics.current()
            withAnimation(.easeOutApp(0.45)) { splashDone = true }
        }
    }
}

/// Loading screen: only the bare logo mark, centred on the navy gradient.
struct SplashView: View {
    @State private var phase = 0
    @State private var breathe = false

    var body: some View {
        ZStack {
            Palette.screen
            LogoMark(size: 150, animated: true)
                .scaleEffect(breathe ? 1.04 : 1)
                .scaleEffect(phase == 0 ? 0.6 : phase == 1 ? 1 : 1)
                .opacity(phase == 0 ? 0 : 1)
                .shadow(color: Palette.teal400.opacity(0.25), radius: 20, y: 18)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.8)) { phase = 1 }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(1.1)) { breathe = true }
        }
    }
}

/// The five screens, the floating glass tab bar, sheets and toasts.
struct MainView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics

    var body: some View {
        let dx = 28 * store.tabDirection * (store.settings.lang == .ar ? -1 : 1)
        ZStack(alignment: .bottom) {
            Palette.page

            // only the visible screen exists; tab changes slide + fade (GPU-cheap)
            ZStack {
                screen(store.tab)
                    .id(store.tab)
                    .transition(.asymmetric(
                        insertion: .offset(x: dx).combined(with: .opacity),
                        removal: .offset(x: -dx * 0.5).combined(with: .opacity)
                    ))
            }
            .animation(.easeOutApp(0.26), value: store.tab)

            TabBar()
                .padding(.bottom, metrics.bottom + 10)
                .ignoresSafeArea(.keyboard)
                .zIndex(40)

            ToastView()
                .ignoresSafeArea(.keyboard)
                .zIndex(80)

            SheetHost()
                .ignoresSafeArea(.keyboard)
                .zIndex(60)
        }
        .ignoresSafeArea(.container)
    }

    @ViewBuilder
    private func screen(_ tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .tx: TransactionsView()
        case .stats: StatsView()
        case .voice: VoiceView()
        case .settings: SettingsView()
        }
    }
}

/// Floating Liquid Glass bar with a black circle that slides to the active tab.
struct TabBar: View {
    @Environment(AppStore.self) private var store
    @Namespace private var pill
    @State private var shown = false

    private func icon(_ tab: AppTab) -> LucideIcon {
        switch tab {
        case .home: return .creditCard
        case .tx: return .arrowDownUp
        case .stats: return .chartPie
        case .voice: return .mic
        case .settings: return .layoutGrid
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let on = store.tab == tab
                Button {
                    Haptic.tap()
                    store.setTab(tab)
                } label: {
                    ZStack {
                        if on {
                            Circle()
                                .fill(.black)
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                        Icon(icon(tab), size: 22, stroke: 1.6)
                            .foregroundStyle(on ? Color.white : Palette.tabInk)
                            .animation(.easeOut(duration: 0.2), value: on)
                    }
                    .frame(width: 54, height: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle(scale: 0.88))
                .accessibilityLabel(label(tab))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 58)
        .barGlass(Capsule())
        .animation(.framer(420, 34), value: store.tab)
        .offset(y: shown ? 0 : 90)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.framer(220, 26).delay(0.25)) { shown = true } }
    }

    private func label(_ tab: AppTab) -> String {
        let t = store.t
        switch tab {
        case .home: return t.home
        case .tx: return t.transactions
        case .stats: return t.stats
        case .voice: return t.voice
        case .settings: return t.settings
        }
    }
}

/// White bottom sheet over a dimmed backdrop; drag it down to close.
struct SheetHost: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottom) {
            if let sheet = store.sheet {
                Palette.backdrop
                    .ignoresSafeArea()
                    .onTapGesture { store.closeSheet() }
                    .transition(.opacity.animation(.easeOut(duration: 0.25)))
                ModalSheet {
                    switch sheet {
                    case let .add(type, editID, prefill):
                        AddSheet(initialType: type, editID: editID, prefill: prefill)
                    case .month:
                        MonthSheet()
                    case .notifications:
                        NotificationsSheet()
                    }
                }
                .id(sheet.id)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.framer(300, 34), value: store.sheet)
    }
}

struct ModalSheet<Content: View>: View {
    @Environment(AppStore.self) private var store
    @Environment(\.metrics) private var metrics
    @ViewBuilder var content: Content
    @State private var drag: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Palette.grabber)
                .frame(width: 40, height: 5)
                .padding(.bottom, 14)
            content
        }
        .padding(.top, 10)
        .padding(.horizontal, 20)
        .padding(.bottom, metrics.bottom + 16)
        .frame(maxWidth: .infinity)
        .background(
            WhiteSheetShape()
                .fill(.white)
                .shadow(color: Color(hex: 0x050F33, opacity: 0.18), radius: 15, y: -8)
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: drag)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { v in drag = max(0, v.translation.height * 0.6) }
                .onEnded { v in
                    if v.translation.height > 120 || v.velocity.height > 600 {
                        store.closeSheet()
                    } else {
                        withAnimation(.framer(300, 34)) { drag = 0 }
                    }
                }
        )
    }
}
