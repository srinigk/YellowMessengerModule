//
//  YMSDK.swift
//  ymsdk
//
//  Created by Priyank Upadhyay.
//  Copyright © 2020 Yellow Messenger. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Speech


typealias JavascriptCallback = (Bool, Any?) -> Void

struct JavascriptFunction {
    var functionString:String
    var callback: JavascriptCallback
}

public class ChatController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {

    private func makeFunction(withString string:String, andCallback callback:@escaping JavascriptCallback) -> JavascriptFunction {
        JavascriptFunction(functionString: string, callback: callback)
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "ymHandler" {
            guard let dict = message.body as? [String: AnyObject],
            let code = dict["code"] as? String,
                let data = dict["data"] as? String else {
                    return
            }
            if code == "start-mic" {
//            self.micButton()
//                self.textToSpeech(text: data)
            }
            if code == "start-mic-ios" {
//            self.micButton()
                self.textToSpeech(text: data)
            }
            YellowMessengerModule.shared.events.trigger(eventName: "BotEvent", information: ["code" : code, "data" : data])

        }
    }

    var webView:WKWebView!
    var button:UIButton!
    var textView:UITextView!
    var progressView:UIProgressView!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))


    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.sizeToFit()
        progressView.frame.size = CGSize(width: UIScreen.main.bounds.width - 40, height: 60)
        progressView.frame.origin = CGPoint(x: 20 , y: (view.frame.maxY/2))

        
        //WebView
        let ymHandler = "ymHandler"
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let js: String = "function sendEventFromiOS(s){document.getElementById('ymIframe').contentWindow.postMessage(JSON.stringify({ event_code: 'send-voice-text', data: s }), '*');}"
        let userScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(userScript)
        contentController.add(self, name: ymHandler)
        configuration.userContentController = contentController
        let rect = CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.webView = WKWebView(frame: rect, configuration: configuration)
        self.webView.navigationDelegate = self
        
        view.addSubview(webView)
        let payload = YellowMessengerModule.shared.payloadData

        let urlString = "https://yellowmessenger.github.io/pages/dominos/mobile.html?botId=\(YellowMessengerModule.shared.configData["BotId"] ?? "")&enableHistory=false&hideTitleBar=false&ym.payload=\(payload)"

        print(urlString)
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        //End Webview
        if (YellowMessengerModule.shared.configData["EnableSpeech"] != nil && YellowMessengerModule.shared.configData["EnableSpeech"] == "true") {
                    // Mic Button
                    button = UIButton(type: .custom)
                    button.frame.origin = CGPoint(x: (view.frame.maxX - 100) , y: (view.frame.maxY - 140))
                    button.frame.size =  CGSize(width: 70, height: 70)
                    button.layer.cornerRadius = 0.5 * button.bounds.size.width
                    button.clipsToBounds = true
            button.backgroundColor = UIColor(red: 0/255.0, green: 172/255.0, blue: 220/255.0, alpha: 1.0)
            button.setImage(UIImage(named: "mic_icon"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.imageEdgeInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
                    button.isHidden = true
                    button.addTarget(self, action: #selector(micButton), for: .touchUpInside)
                    view.insertSubview(button, aboveSubview: webView)
                    //End MicButton
                    
                    //Speech results area
                    let frame =  CGRect(x: 0, y: (UIScreen.main.bounds.maxY-100), width: UIScreen.main.bounds.width, height: 100.0)
                    textView = UITextView(frame: frame)
                    textView.contentInsetAdjustmentBehavior = .automatic
                    textView.textAlignment = NSTextAlignment.justified
                    textView.textColor = UIColor(red: 86/255.0, green: 88/255.0, blue: 103/255.0, alpha: 1.0)
                    textView.isEditable = false
                    textView.backgroundColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1.0)
                    textView.isHidden = true
                    view.insertSubview(textView, aboveSubview: webView)
                    //End Speech results area
                    
                    //Speech Permissions
                    speechRecognizer?.delegate = self
                    SFSpeechRecognizer.requestAuthorization { (authStatus) in
                        switch authStatus {
                        case .authorized:
                            print("Speech recognition allowed")
                            self.enableButton(show: true)
                        case .denied:
                            print("User denied access to speech recognition")
                            self.enableButton(show: false)
                        case .restricted:
                            print("Speech recognition restricted on this device")
                            self.enableButton(show: false)
                        case .notDetermined:
                            print("Speech recognition not yet authorized")
                            self.enableButton(show: false)
                        default: print("Something happend.")
                        self.enableButton(show: false)

                        }
                    }
                    //End Speech Premissions
        }
        view.addSubview(progressView)
        let statusBarHeight = UIApplication.shared.isStatusBarHidden ? CGFloat(0) : UIApplication.shared.statusBarFrame.height
                     
        let cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(named: "close"), for: .normal)
        cancelButton.frame = CGRect(x: (self.view.frame.width - 50), y: (statusBarHeight + 15.0), width: 25, height: 25)
        cancelButton.addTarget(self, action: #selector(dismisViewController), for: .touchUpInside)
        view.addSubview(cancelButton)
        view.bringSubviewToFront(cancelButton)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
             if url.host != "yellowmessenger.github.io" {
                           UIApplication.shared.open(url)
                           decisionHandler(.cancel)
                           return
                       }
        }

        decisionHandler(.allow)
    }
          

   @objc func dismisViewController() {
    self.view.window?.isHidden = true
    self.presentingViewController?.dismiss(animated: true, completion: nil)
      }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.progressView.progress = Float(webView.estimatedProgress)
        }
        if self.progressView.progress == 1.0 {
            self.progressView.isHidden = true
        }
    }
    
    func enableButton(show:Bool){
       DispatchQueue.main.async {
        self.button.isHidden = !show
       }
    }
    
    //TTS
    let synthesizer = AVSpeechSynthesizer()
    public func textToSpeech(text:String){
        let utterance = AVSpeechUtterance(string: text)
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance){
        self.micButton()
    }
    //End TTS
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var detectionTimer:Timer!
    

    //On button Press
    @objc func micButton(){
        if audioEngine.isRunning {
            button.setImage(UIImage(named: "mic_icon"), for: .normal)
            audioEngine.stop()
            recognitionRequest = nil
            sendMessage(text: textView.text)
            textView.isHidden = true
        } else {
            button.setImage(UIImage(named: "close"), for: .normal)
            textView.isHidden = false
            startRecording()
        }
        
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                print("Text \(result.bestTranscription.formattedString)")
            }
            
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
                self.restartSpeechTimer()
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("Start Recording")
        } else {
           print("Recognition Not Available")
        }
    }
    
    func sendMessage(text:String){
        if (text != "")
        { let function:JavascriptFunction = makeFunction(withString: "sendEventFromiOS('\(text)');", andCallback: { success,result in})
        webView.evaluateJavaScript(function.functionString ) { (response, error) in
               if let _ = error {
                function.callback(false, error.debugDescription)
               }
               else {
                   function.callback(true, response)
               }
           }
        }
    }
    
    func restartSpeechTimer() {
        self.detectionTimer?.invalidate()
        self.detectionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (timer) in
            self.audioEngine.stop()
            self.recognitionTask?.cancel()
            self.sendMessage(text: self.textView.text)
            self.textView.text = ""
            self.textView.isHidden = true
            self.button.setImage(UIImage(named: "mic_icon"), for: .normal)

        })
    }
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

