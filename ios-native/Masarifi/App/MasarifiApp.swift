import SwiftUI

@main
struct MasarifiApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.layoutDirection, store.settings.lang == .ar ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: store.settings.lang == .ar ? "ar" : "en"))
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
                MainTabs().transition(.opacity)
            } else {
                WelcomeView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: store.onboarded)
    }
}

/// Apple's tab bar: Liquid Glass, shrinks while scrolling, Search on its own
/// at the trailing end, and a quick-add bar above it like Music's mini player.
struct MainTabs: View {
    @Environment(AppStore.self) private var store
    @Namespace private var zoom

    var body: some View {
        @Bindable var store = store
        let t = store.t
        TabView(selection: $store.tab) {
            Tab(t.home, systemImage: "creditcard", value: AppTab.home) {
                HomeView(zoom: zoom)
            }
            Tab(t.transactions, systemImage: "list.bullet.rectangle.portrait", value: AppTab.tx) {
                TransactionsView(zoom: zoom)
            }
            Tab(t.stats, systemImage: "chart.pie", value: AppTab.stats) {
                StatsView(zoom: zoom)
            }
            Tab(t.settings, systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
            Tab(t.search, systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchView(zoom: zoom)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            QuickAddBar(zoom: zoom)
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
            .navigationTransition(.zoom(sourceID: store.sheetSource, in: zoom))
        }
        .overlay(alignment: .top) { ToastView() }
    }
}

/// "Say an expense…" bar above the tab bar (tabViewBottomAccessory).
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
                        .foregroundStyle(Palette.brand)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeat(.periodic(delay: 2)))
                    Text(t.quickAdd)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.horizontal, 16)
    }
}
