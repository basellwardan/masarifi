import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Called when the app was launched with a url. Feel free to add additional processing here,
        // but if you want the App API to support tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when the app was launched with an activity, including Universal Links.
        // Feel free to add additional processing here, but if you want the App API to support
        // tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}

// MARK: - Liquid Glass (iOS 26+)
//
// The app's screens are web content; the tab bar is the app's navigation
// layer, so on iOS 26 it is drawn natively with Apple's Liquid Glass material
// (UIGlassEffect) instead of HTML, as Apple's "Adopting Liquid Glass" guide
// recommends for navigation. Older iOS versions keep the web tab bar.

/// Root view controller (set in Main.storyboard) that registers the app's own plugin.
class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(GlassTabBarPlugin())
    }
}

@objc(GlassTabBarPlugin)
public class GlassTabBarPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GlassTabBarPlugin"
    public let jsName = "GlassTabBar"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "select", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setHidden", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setMinimized", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "accessibility", returnType: CAPPluginReturnPromise)
    ]

    /// Kept as UIView so the stored property needs no availability annotation.
    private var bar: UIView?

    override public func load() {
        let center = NotificationCenter.default
        for name in [
            UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification
        ] {
            center.addObserver(self, selector: #selector(accessibilityChanged), name: name, object: nil)
        }
    }

    private func accessibilityState() -> [String: Any] {
        return [
            "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
            "increaseContrast": UIAccessibility.isDarkerSystemColorsEnabled,
            "reduceMotion": UIAccessibility.isReduceMotionEnabled
        ]
    }

    @objc private func accessibilityChanged() {
        notifyListeners("accessibilityChanged", data: accessibilityState())
    }

    @objc func accessibility(_ call: CAPPluginCall) {
        DispatchQueue.main.async { call.resolve(self.accessibilityState()) }
    }

    @objc func show(_ call: CAPPluginCall) {
        guard #available(iOS 26.0, *) else {
            call.reject("Liquid Glass needs iOS 26", "UNAVAILABLE")
            return
        }
        let raw = call.getArray("tabs", JSObject.self) ?? []
        let items: [GlassTabBar.Item] = raw.compactMap { tab in
            guard let id = tab["id"] as? String, let symbol = tab["symbol"] as? String else { return nil }
            return GlassTabBar.Item(id: id, symbol: symbol, label: (tab["label"] as? String) ?? id)
        }
        let selected = call.getString("selected") ?? items.first?.id ?? ""
        let rtl = call.getBool("rtl") ?? false
        DispatchQueue.main.async {
            guard let host = self.bridge?.viewController?.view, !items.isEmpty else {
                call.reject("No host view", "UNAVAILABLE")
                return
            }
            self.bar?.removeFromSuperview()
            let bar = GlassTabBar(items: items, selected: selected, rtl: rtl) { [weak self] id in
                self?.notifyListeners("tabSelected", data: ["tab": id])
            }
            bar.attach(to: host)
            self.bar = bar
            call.resolve()
        }
    }

    @objc func select(_ call: CAPPluginCall) {
        let tab = call.getString("tab") ?? ""
        DispatchQueue.main.async {
            if #available(iOS 26.0, *), let bar = self.bar as? GlassTabBar { bar.select(tab, animated: true) }
            call.resolve()
        }
    }

    @objc func setHidden(_ call: CAPPluginCall) {
        let hidden = call.getBool("hidden") ?? false
        DispatchQueue.main.async {
            if #available(iOS 26.0, *), let bar = self.bar as? GlassTabBar { bar.setHidden(hidden) }
            call.resolve()
        }
    }

    @objc func setMinimized(_ call: CAPPluginCall) {
        let minimized = call.getBool("minimized") ?? false
        DispatchQueue.main.async {
            if #available(iOS 26.0, *), let bar = self.bar as? GlassTabBar { bar.setMinimized(minimized) }
            call.resolve()
        }
    }
}

/// Floating capsule tab bar in Liquid Glass. The selected tab is marked by a
/// dark tinted glass "lens" that glides between items; both live in one
/// UIGlassContainerEffect so the shapes blend and morph like system glass.
@available(iOS 26.0, *)
final class GlassTabBar: UIView {
    struct Item {
        let id: String
        let symbol: String
        let label: String
    }

    private let items: [Item]
    private var selected: String
    private let onSelect: (String) -> Void

    private let container = UIVisualEffectView(effect: UIGlassContainerEffect())
    private let barGlass: UIVisualEffectView
    private let lens: UIVisualEffectView
    private let stack = UIStackView()
    private var buttons: [String: UIButton] = [:]

    private var isBarHidden = false
    private var isMinimized = false

    private let itemWidth: CGFloat = 56
    private let barHeight: CGFloat = 62
    private let lensSize: CGFloat = 52
    private let sidePadding: CGFloat = 6

    init(items: [Item], selected: String, rtl: Bool, onSelect: @escaping (String) -> Void) {
        self.items = items
        self.selected = selected
        self.onSelect = onSelect

        let barEffect = UIGlassEffect(style: .regular)
        barEffect.isInteractive = true
        barGlass = UIVisualEffectView(effect: barEffect)

        let lensEffect = UIGlassEffect(style: .regular)
        lensEffect.tintColor = UIColor.black.withAlphaComponent(0.88)
        lensEffect.isInteractive = true
        lens = UIVisualEffectView(effect: lensEffect)

        super.init(frame: .zero)
        overrideUserInterfaceStyle = .light

        container.frame = bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(container)

        barGlass.layer.cornerRadius = barHeight / 2
        barGlass.layer.cornerCurve = .continuous
        container.contentView.addSubview(barGlass)

        lens.layer.cornerRadius = lensSize / 2
        lens.layer.cornerCurve = .continuous
        container.contentView.addSubview(lens)

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
        addSubview(stack)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        for item in items {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(systemName: item.symbol, withConfiguration: symbolConfig), for: .normal)
            button.accessibilityLabel = item.label
            button.accessibilityTraits = .tabBar
            let id = item.id
            button.addAction(UIAction { [weak self] _ in self?.tapped(id) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons[id] = button
        }
        applyTints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func attach(to host: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(self)
        let width = CGFloat(items.count) * itemWidth + sidePadding * 2
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: host.centerXAnchor),
            bottomAnchor.constraint(equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: barHeight)
        ])
        // rise in from below
        transform = CGAffineTransform(translationX: 0, y: 120)
        alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3) {
            self.transform = .identity
            self.alpha = 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barGlass.frame = bounds
        stack.frame = bounds.insetBy(dx: sidePadding, dy: 0)
        stack.layoutIfNeeded()
        positionLens()
    }

    private func positionLens() {
        guard let button = buttons[selected] else { return }
        let center = stack.convert(button.center, to: self)
        lens.frame = CGRect(x: center.x - lensSize / 2, y: center.y - lensSize / 2, width: lensSize, height: lensSize)
    }

    private func applyTints() {
        for (id, button) in buttons {
            let on = id == selected
            button.tintColor = on ? .white : UIColor(white: 0.11, alpha: 1)
            button.accessibilityTraits = on ? [.tabBar, .selected] : .tabBar
            button.alpha = (isMinimized && !on) ? 0.0 : 1.0
        }
    }

    private func tapped(_ id: String) {
        UISelectionFeedbackGenerator().selectionChanged()
        if isMinimized { setMinimized(false) }
        select(id, animated: true)
        onSelect(id)
    }

    func select(_ id: String, animated: Bool) {
        guard buttons[id] != nil, id != selected else { return }
        selected = id
        let changes = {
            self.positionLens()
            self.applyTints()
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0.4,
                           options: [.allowUserInteraction, .beginFromCurrentState], animations: changes)
        } else {
            changes()
        }
    }

    /// Tab bars minimize while scrolling down and expand when scrolling up.
    func setMinimized(_ minimized: Bool) {
        guard minimized != isMinimized else { return }
        isMinimized = minimized
        animateState()
    }

    func setHidden(_ hidden: Bool) {
        guard hidden != isBarHidden else { return }
        isBarHidden = hidden
        isUserInteractionEnabled = !hidden
        animateState()
    }

    private func animateState() {
        let target: CGAffineTransform
        if isBarHidden {
            target = CGAffineTransform(translationX: 0, y: 140)
        } else if isMinimized {
            target = CGAffineTransform(translationX: 0, y: 6).scaledBy(x: 0.82, y: 0.82)
        } else {
            target = .identity
        }
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: reduceMotion ? 0.2 : 0.5, delay: 0, usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.3, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.transform = (reduceMotion && !self.isBarHidden) ? .identity : target
            self.alpha = self.isBarHidden ? 0 : 1
            self.applyTints()
        }
    }
}
