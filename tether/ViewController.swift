//
//  ViewController.swift
//  tether
//
//  Created by Ishil Puri on 3/18/22.
//

import UIKit
import AVFoundation
import AudioToolbox
import Gifu
import BackgroundTasks
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var plugStatusLbl: UILabel!
    @IBOutlet weak var secureBtn: UIButton!
    @IBOutlet weak var plugImgView: UIImageView!
    @IBOutlet weak var eyesGifView: GIFImageView!
    @IBOutlet weak var optionsBtn: UIButton!
    
    let center = NotificationCenter.default
    var token: NSObjectProtocol?
    var bkgnd: NSObjectProtocol?
    
    var player: AVAudioPlayer?
    var currSound: String = "frozen"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UIDevice.current.isBatteryMonitoringEnabled = true
        setPlugImage()
        setPopupButton()
        eyesGifView.contentMode = .scaleAspectFit
        eyesGifView.prepareForAnimation(withGIFNamed: "eye-gif")
        token = center.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: nil, using: { note in
            self.setPlugImage()
            self.shouldTrigger()
        })
        
        bkgnd = center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil, using: { note in
//            self.sendAlert(message: "Please keep app running for full functionality.")
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey: "Tether", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey: "Keep app running for full alarm functionality", arguments: nil)
            content.sound = UNNotificationSound.default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier: "comeback", content: content, trigger: trigger) // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error : Error?) in
                 if let theError = error {
                     // Handle any errors
                     print("\(theError)")
                 }
            }
        })
    }
    
    @IBAction func secureBtnAction(_ sender: Any) {
        if (statusLbl.text == "secured") {
            disableAuthFlow()
        } else {
            switch UIDevice.current.batteryState.rawValue {
            case 0:
                // unknown
                sendAlert(message: "Cannot enable alarm. Battery state unknown.")
            
            case 1:
                // unplugged
                sendAlert(message: "Plug device in to enable alarm.")
                
            case 2:
                // plugged in
                enable()
                
            case 3:
                // plugged in and @ 100%
                enable()
                
            default:
                print("default case...should never reach here")
            }
        }
    }
    
    func enable() {
        toggleEyeAnimation()
        statusLbl.text = "secured"
        secureBtn.tintColor = .systemRed
        secureBtn.setTitle("disable", for: .normal)
        plugStatusLbl.text = ""
    }
    
    func resetUI() {
        toggleEyeAnimation()
        statusLbl.text = "unsecured"
        secureBtn.tintColor = .systemBlue
        secureBtn.setTitle("enable", for: .normal)
        setPlugImage()
        playMusic()
    }
    
    func disableAuthFlow(){
        // TODO: two cases
        // 1. if the phone was locked, then don't require face id / pass
        // 2. if phone was NOT locked, then required authentication
        // RN AM JUST SOLVING FOR MVP
        let context = LAContext()
        context.localizedCancelTitle = "Beta. Cancel will authenticate."
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")

            // Fall back to a asking for username and password.
            // if can't use face id, auto authenticate
            return
        }
        
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Disable alarm")
                resetUI()
            } catch let error {
                print(error.localizedDescription)
                sendAlert(message: "Authentication Failed. Try again.")
                // Fall back to a asking for username and password.
                // ...
            }
        }
    }
    
    func sendAlert(title: String = "Error", message: String, completionMethod: @escaping () -> Void = {}) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        NSLog("errored.")
        }))
        self.present(alert, animated: true, completion: completionMethod)
    }
    
    func toggleEyeAnimation() {
        if (eyesGifView.isAnimatingGIF) {
            eyesGifView.stopAnimatingGIF()
            eyesGifView.prepareForAnimation(withGIFNamed: "eye-gif")
        } else {
            eyesGifView.animate(withGIFNamed: "eye-gif")
        }
    }
    
    /// Set image of plug based on
    func setPlugImage() {
        let curr = UIDevice.current.batteryState.rawValue
        
        if (curr == 1) {
            plugImgView.image = UIImage(systemName: "powerplug")
            plugImgView.tintColor = .systemGray
            plugStatusLbl.text = "plug in to enable alarm."
        } else if (curr == 2 || curr == 3) {
            plugImgView.image = UIImage(systemName: "powerplug.fill")
            plugImgView.tintColor = .systemGreen
            plugStatusLbl.text = "ready to enable."
        } else {
            plugImgView.image = UIImage(systemName: "xmark.circle.fill")
            plugImgView.tintColor = .systemRed
            plugStatusLbl.text = "error: unknown battery state."
        }
    }
    
    func shouldTrigger() {
        // check alarm condition
        if (statusLbl.text == "secured" && UIDevice.current.batteryState.rawValue == 1) {
            // start sounds & vibrations
            playMusic()
//            AudioServicesPlayAlertSound(SystemSoundID(1304))
            sendAlert(title: "Alert", message: "Alarm triggered.")

        }
    }
    
    func playMusic() {
        if let player = player, player.isPlaying || statusLbl.text == "unsecured" { // if disable sound btn clicked after audio ends -->
            // stop playback
            player.stop()
        } else {
            // set up player, and play
            let audioData = NSDataAsset(name: currSound)
            do {
                try AVAudioSession.sharedInstance().setMode(.default)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                guard let audioData = audioData else {
                    return
                }
                
                player = try AVAudioPlayer(data: audioData.data)
                guard let player = player else {
                    return
                }
                
                player.numberOfLoops = -1
                
                player.play()
            }
            catch {
                print("sth went wrong")
            }
        }
    }
    
    func setPopupButton(){
        let optionClosure = {(action : UIAction) in print(action.title)
            self.currSound = action.title
        }
        optionsBtn.menu = UIMenu(children: [ UIAction(title: "frozen", handler: optionClosure), UIAction(title: "beeps", handler: optionClosure), UIAction(title: "piercing", handler: optionClosure), UIAction(title: "ishil", handler: optionClosure)])
        optionsBtn.showsMenuAsPrimaryAction = true
        optionsBtn.changesSelectionAsPrimaryAction = true
    }

}

