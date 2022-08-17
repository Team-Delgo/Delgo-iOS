import UIKit
import WebKit
import AVFoundation

class ViewController: UIViewController , WKNavigationDelegate, WKScriptMessageHandler , WKUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webviewInit(_loadUrl: "https://www.delgo.pet") // get 방식
        requestNotificationPermission()
        
    }
    
    func requestNotificationPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge], completionHandler: {didAllow,Error in
            if didAllow {
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        })
    }
    
    
    private var mainWebView: WKWebView? = nil
    deinit {
        self.mainWebView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    
    
    func webviewInit(_loadUrl:String){
        self.setNotify()
        self.vibrate()
        self.copyToClipboard()
        self.numToCall()
        
        // [웹뷰 전체 화면 설정 실시]
        // self.mainWebView = WKWebView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        
        
        self.mainWebView = WKWebView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), configuration: self.javascriptConfig)
        
        
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0), completionHandler:{ })
        
    
        self.mainWebView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true  // 자바스크립트 활성화
        self.mainWebView?.navigationDelegate = self // 웹뷰 변경 상태 감지
        self.mainWebView?.allowsBackForwardNavigationGestures = true // 웹뷰 뒤로가기, 앞으로 가기 제스처 사용
        self.mainWebView?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // 웹뷰 로드 상태 퍼센트 확인
        self.mainWebView?.uiDelegate = self // alert 팝업창 이벤트 받기 위함
        
        
        self.view.addSubview(self.mainWebView!)
        let url = URL (string: _loadUrl)
        let request = URLRequest(url: url! as URL)
        
        self.mainWebView!.load(request)

        
    }
    
    
    let javascriptController = WKUserContentController()
    let javascriptConfig = WKWebViewConfiguration()
    
    func copyToClipboard(){
        print("")
        print("===============================")
        print("[ViewController >> copyToClipboard() : 자바스크립트 통신 브릿지 추가]")
        print("Bridge : copyToClipboard")
        print("===============================")
        print("")
        self.javascriptController.add(self, name: "copyToClipboard")
        self.javascriptConfig.userContentController = self.javascriptController

    }
    
    func numToCall(){
        print("")
        print("===============================")
        print("[ViewController >> numToCall() : 자바스크립트 통신 브릿지 추가]")
        print("Bridge : numToCall")
        print("===============================")
        print("")
        self.javascriptController.add(self, name: "numToCall")
        self.javascriptConfig.userContentController = self.javascriptController

    }



    func vibrate(){
        print("")
        print("===============================")
        print("[ViewController >> vibrate() : 자바스크립트 통신 브릿지 추가]")
        print("Bridge : vibrate")
        print("===============================")
        print("")
        self.javascriptController.add(self, name: "vibrate")
        self.javascriptConfig.userContentController = self.javascriptController

    }

    func setNotify(){
        print("")
        print("===============================")
        print("[ViewController >> setNotify() : 자바스크립트 통신 브릿지 추가]")
        print("Bridge : setNotify")
        print("===============================")
        print("")
        self.javascriptController.add(self, name: "setNotify")
        self.javascriptConfig.userContentController = self.javascriptController
    }
    
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageBody = message.body
        
        print("")
        print("===============================")
        print("[ViewController >> userContentController() : 자바스크립트 >> IOS]")
        print("message.name: " + message.name)
        print("message.body: ", messageBody)
        print("===============================")
        print("")
        
        
        switch message.name {
        case "copyToClipboard":
            let receiveData = message.body
            print("")
            print("===============================")
            print("[ViewController >> userContentController() : 자바스크립트 >> IOS]")
            print("Bridge : copyToClipboard")
            print("receiveData : ", receiveData)
            print("===============================")
            print("")
            
            UIPasteboard.general.string = (receiveData as! String)
            self.showToast(message: "클립보드에 복사되었습니다.")
            
        case "vibrate":
            print("")
            print("===============================")
            print("[ViewController >> userContentController() : 자바스크립트 >> IOS]")
            print("Bridge : vibrate")
            print("===============================")
            print("")
            UIDevice.vibrate()
            
            
        case "setNotify":
            print("")
            print("===============================")
            print("[ViewController >> userContentController() : 자바스크립트 >> IOS]")
            print("Bridge : test")
            print("===============================")
            print("")
            goAppSetting()
            
        case "numToCall":
            let receiveData = message.body
            print("")
            print("===============================")
            print("[ViewController >> userContentController() : 자바스크립트 >> IOS]")
            print("Bridge : test")
            print("===============================")
            print("")
            goDeviceApp(_url: receiveData as! String)
            
        default:
            ()
        }
        
    }
    
    func goDeviceApp(_url : String) {
            
            if let openApp = URL(string: _url), UIApplication.shared.canOpenURL(openApp) {
                print("")
                print("====================================")
                print("[goDeviceApp : 디바이스 외부 앱 열기 수행]")
                print("링크 주소 : \(_url)")
                print("====================================")
                print("")
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(openApp, options: [:], completionHandler: nil)
                }
                else {
                    UIApplication.shared.openURL(openApp)
                }
            }
            else {
                print("")
                print("====================================")
                print("[goDeviceApp : 디바이스 외부 앱 열기 실패]")
                print("링크 주소 : \(_url)")
                print("====================================")
                print("")
            }
        }

    
    func goAppSetting() {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                print("")
                print("===============================")
                print("[A_Main >> goAppSetting() : 앱 설정 화면 이동 수행]")
                print("===============================")
                print("")
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                print("")
                print("===============================")
                print("[A_Main >> goAppSetting() : 앱 설정 화면 이동 실패]")
                print("===============================")
                print("")
            }
        }
    
    
    func showToast(message: String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let _startUrl = String(describing: webView.url?.description ?? "")
        print("")
        print("===============================")
        print("[ViewController >> didStartProvisionalNavigation() : 웹뷰 로드 수행 시작]")
        print("url : \(_startUrl)")
        print("===============================")
        print("")
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("")
        print("===============================")
        print("[ViewController >> observeValue() : 웹뷰 로드 상태 확인]")
        print("loading : \(Float((self.mainWebView?.estimatedProgress)!)*100)")
        print("===============================")
        print("")
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let _endUrl = String(describing: webView.url?.description ?? "")
        print("")
        print("===============================")
        print("[ViewController >> didFinish() : 웹뷰 로드 수행 완료]")
        print("url : \(_endUrl)")
        print("===============================")
        print("")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void){
        print("")
        print("===============================")
        print("[ViewController >> runJavaScriptAlertPanelWithMessage() : alert 팝업창 처리]")
        print("message : ", message)
        print("===============================")
        print("")
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in completionHandler() }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("")
        print("===============================")
        print("[ViewController >> runJavaScriptConfirmPanelWithMessage() : confirm 팝업창 처리]")
        print("message : ", message)
        print("===============================")
        print("")
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in completionHandler(false) }))
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in completionHandler(true) }))
        self.present(alertController, animated: true, completion: nil)
    }
}


extension UIDevice {

    static func vibrate() {
        AudioServicesPlaySystemSound(1519)
    }
}
