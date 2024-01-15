//
//  SceneDelegate.swift
//  Delgo
//
//  Created by Woochan Park on 2022/12/18.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    
    let vc = MainWebViewController()
    
    window?.rootViewController = vc
    
    window?.makeKeyAndVisible()
    
      if let noti = connectionOptions.notificationResponse?.notification.request.content.userInfo {
          딥링크로리다이렉트(noti)
      }
      
  }
    
    private func 딥링크로리다이렉트(_ noti: [AnyHashable: Any]) {
        guard let urlData = noti["custom"] as? [String: Any] else { return }
        if let imageURL = urlData["imageUrl"] as? String, let url = urlData["url"] as? String {
            guard let url = URL(string: url) else { return }
            NotificationCenter.default.post(name: Notification.Name("deeplink"), object: url)
        }
    }
  
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
      var data = [String: Any]()
      if let components = URLComponents(string: url.absoluteString) {
        data = parsingDeepLink(url: components)
        NotificationCenter.default.post(name: NSNotification.Name("callDeepLink"), object: data)
      } else { print("deepLink Error")}
    }
  }
  
  private func parsingDeepLink(url: URLComponents) -> [String: Any] {
    var urlItem = [String: Any]()
    let items = url.queryItems ?? []
    
    urlItem["url"] = items.first?.value
    
    return urlItem
  }
  
}



