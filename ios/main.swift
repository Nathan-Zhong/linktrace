import UIKit
import WebKit

// 循迹: a native shell around the bundled web app (www/), fully offline.
final class AtlasVC: UIViewController, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
  private var web: WKWebView!
  private var light = UserDefaults.standard.bool(forKey: "light")

  override var preferredStatusBarStyle: UIStatusBarStyle { light ? .darkContent : .lightContent }

  override func loadView() {
    let cfg = WKWebViewConfiguration()
    cfg.userContentController.add(self, name: "atlas")
    cfg.allowsInlineMediaPlayback = true
    web = WKWebView(frame: .zero, configuration: cfg)
    web.isOpaque = false
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.scrollView.bounces = false
    web.allowsLinkPreview = false
    web.uiDelegate = self
    web.navigationDelegate = self
    if #available(iOS 16.4, *) { web.isInspectable = true }
    paint()
    view = web
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    guard let dir = Bundle.main.url(forResource: "www", withExtension: nil) else { return }
    web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
  }

  private func paint() {
    let c = light ? UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1) : UIColor.black
    web.backgroundColor = c; web.scrollView.backgroundColor = c; view?.backgroundColor = c
    view?.window?.backgroundColor = c
    setNeedsStatusBarAppearanceUpdate()
  }

  func userContentController(_ u: WKUserContentController, didReceive m: WKScriptMessage) {
    guard let d = m.body as? [String: Any] else { return }
    if let t = d["theme"] as? String {
      light = t == "light"; UserDefaults.standard.set(light, forKey: "light"); paint()
    }
    if let name = d["file"] as? String, let text = d["text"] as? String {
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
      try? text.data(using: .utf8)?.write(to: url)
      let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      sheet.popoverPresentationController?.sourceView = view
      present(sheet, animated: true)
    }
  }

  // external links open in Safari
  func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let u = a.request.url, ["http", "https"].contains(u.scheme ?? ""), a.targetFrame?.isMainFrame ?? true {
      UIApplication.shared.open(u); decisionHandler(.cancel); return
    }
    decisionHandler(.allow)
  }
  func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
    if let u = a.request.url { UIApplication.shared.open(u) }
    return nil
  }
  func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage msg: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping () -> Void) {
    let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
    a.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
    present(a, animated: true)
  }
  func webViewWebContentProcessDidTerminate(_ w: WKWebView) { w.reload() }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ a: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.rootViewController = AtlasVC()
    w.makeKeyAndVisible()
    window = w
    return true
  }
}
