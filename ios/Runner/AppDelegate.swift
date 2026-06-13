import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var privacyView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    // Retrasamos la aparición de la máscara nativa 0.3 segundos.
    // Esto permite que el sistema tome la captura de pantalla de la app real,
    // pero que en el selector de apps (multitarea) se vea borrosa.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        // Solo la mostramos si la app sigue inactiva
        if application.applicationState != .active {
            self.showPrivacyOverlay()
        }
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    if privacyView == nil, let window = self.window {
      let blurEffect = UIBlurEffect(style: .dark)
      let blurView = UIVisualEffectView(effect: blurEffect)
      blurView.frame = window.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      
      // Intentamos cargar el logo del splash
      if let logo = UIImage(named: "LaunchImage") {
          let imageView = UIImageView(image: logo)
          imageView.contentMode = .scaleAspectFit
          // Ajustamos el tamaño para que sea proporcional
          let side = min(window.bounds.width, window.bounds.height) * 0.5
          imageView.frame = CGRect(x: 0, y: 0, width: side, height: side)
          imageView.center = CGPoint(x: window.bounds.midX, y: window.bounds.midY)
          imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
          blurView.contentView.addSubview(imageView)
      }
      
      self.privacyView = blurView
      window.addSubview(blurView)
      window.bringSubviewToFront(blurView)
    }
  }

  private func hidePrivacyOverlay() {
    privacyView?.removeFromSuperview()
    privacyView = nil
  }
}
