//
//  MainWebViewController.swift
//  Delgo
//
//  Created by Woochan Park on 2022/12/18.
//

import UIKit
import SnapKit
import WebKit
import Then
import FirebaseMessaging
import FBSDKCoreKit

final class MainWebViewController: UIViewController {
  
  //MARK: UI Properties
  private var webView: WKWebView!
  private var shouldScreenUp = false
  
  //MARK: Initialization
  init() {
    super.init(nibName: nil, bundle: nil)
    self.setUpWebView()
    self.configureUI()
    self.setConstraints()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.clearCacheWhenUpdated()
    self.setSwipeMotion()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    /*
     키보드 해지하고 싶으면 64, 65번째줄 주석처리
     */
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardUp), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDown), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  private func setSwipeMotion() {
    let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
    swipeRecognizer.direction = .right
    guard let webView = webView else { return }
    webView.addGestureRecognizer(swipeRecognizer)
  }
  
  private func configureUI() {
    self.view.backgroundColor = .white
    self.view.addSubview(webView)
    self.setConstraints()
  }
  
  private func setConstraints() {
    webView.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}

//MARK: Func

extension MainWebViewController {
  
  private func setUpWebView() {
    
    let userContentController = WKUserContentController().then {
      $0.add(self, name: JSMessageType.sendFCMToken.rawValue)
      $0.add(self, name: JSMessageType.goToPlusFriend.rawValue)
      $0.add(self, name: JSMessageType.handleWhenKeyboardUp.rawValue)
      $0.add(self, name: JSMessageType.goToPlusFriends.rawValue)
    }
    
    let webViewConfig = WKWebViewConfiguration().then {
      $0.userContentController = userContentController
      $0.allowsInlineMediaPlayback = true
    }
    
    webView = WKWebView(frame: .zero,
                        configuration: webViewConfig).then {
      $0.scrollView.showsVerticalScrollIndicator = false
      $0.scrollView.showsHorizontalScrollIndicator = false
      $0.scrollView.bounces = false
      $0.scrollView.alwaysBounceVertical = false
      $0.scrollView.alwaysBounceHorizontal = false
      $0.allowsBackForwardNavigationGestures = true
      $0.navigationDelegate = self
    }
    
    let request = URLRequest(url: URL(string:"https://www.reward.delgo.pet")!)
    webView.load(request)
  }
}

//MARK: WKScriptMessageHandler

enum JSMessageType: String {
  
  case sendFCMToken = "sendFcmToken"
  case goToPlusFriend
  case handleWhenKeyboardUp = "screenUp"
  case goToPlusFriends
}

extension MainWebViewController: WKScriptMessageHandler {
  /// JS-> Native 콜백 처리
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    
    guard let messageType = JSMessageType(rawValue: message.name) else {
      return
    }
    
    switch messageType {
      
    case .sendFCMToken:
      
      guard let userID = message.body as? Int else {
        return
      }
      
      Task {
        
        guard let token = try? await Messaging.messaging().token() else {
          return
        }
        
        guard let url = URL(string: "https://www.reward.delgo.pet/api/fcm/token") else {
          return
        }
        
        var request = URLRequest(url: url)
        
        let headers = ["Content-Type": "application/json",
                       "Accept": "application/json"]
        
        headers.forEach {
          request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        
        guard let body = try? encoder.encode(FCMToken(userId: userID, fcmToken: token)) else {
          return
        }
        
        request.httpBody = body
        
        try? await URLSession.shared.data(for: request)
      }
      
      
    case .goToPlusFriend:
      return
    case .handleWhenKeyboardUp:
      self.shouldScreenUp = true
    case .goToPlusFriends:
      let url = URL(string: "kakaoplus://plusfriend/friend/@delgo")!
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } 
    }
  }
}

// MARK: - Cache Control
extension MainWebViewController {
    
    func clearCacheWhenUpdated() {
//        print(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeMemoryCache], for: []) {
            print("clear cache")
        }
    }
    
}

// MARK: - Swipe
extension MainWebViewController {
  
  @objc
  func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer) {
    if recognizer.direction == .right, let webView = self.webView {
      webView.evaluateJavaScript("window.webkit.messageHandlers.swipe.postMessage('swipe')", completionHandler: nil)
    }
  }
}

// MARK: - Keyboard

extension MainWebViewController {
  
  @objc
  func keyboardUp(notification: NSNotification) {
    if let keyboardFrame:NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
      let keyboardRectangle = keyboardFrame.cgRectValue
      
      guard let webView = self.webView else { return }
      
      if shouldScreenUp == true {
        UIView.animate(
          withDuration: 0.3
          , animations: {
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRectangle.height, right: 0)
            webView.transform = CGAffineTransform(translationX: 0, y: -keyboardRectangle.height)
          }
        )
      }
    }
  }
  
  @objc
  func keyboardDown(notification: NSNotification) {
    guard let webView = self.webView else { return }
    if shouldScreenUp == true {
      webView.transform = .identity
    }
    shouldScreenUp = false
  }
  
}

// MARK: WKNavi

extension MainWebViewController: WKNavigationDelegate {

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
    
    if navigationAction.request.url?.scheme == "tel",
       let url = navigationAction.request.url,
       UIApplication.shared.canOpenURL(url)
    {
      UIApplication.shared.open(url, completionHandler: nil)
      return .cancel
    } else {
      return .allow
    }
  }
}
