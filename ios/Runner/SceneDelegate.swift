import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Hintergrund wie Splash und App (#F2F2F7 hell, #000000 dunkel): Blendet iOS den Splash aus,
    // bevor Flutter das erste Bild zeigt, scheint sonst kurz Schwarz durch.
    window?.backgroundColor = .systemGroupedBackground
    window?.rootViewController?.view.backgroundColor = .systemGroupedBackground
  }
}
