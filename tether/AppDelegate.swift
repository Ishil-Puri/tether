//
//  AppDelegate.swift
//  tether
//
//  Created by Ishil Puri on 3/18/22.
//

import UIKit
import UserNotifications
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        registerBackgroundTasks()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
//        let content = UNMutableNotificationContent()
//        content.title = NSString.localizedUserNotificationString(forKey: "Tether", arguments: nil)
//        content.body = NSString.localizedUserNotificationString(forKey: "Please keep app running for full alarm functionality", arguments: nil)
//        content.sound = UNNotificationSound.default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: "OneSecond", content: content, trigger: trigger) // Schedule the notification.
//        let center = UNUserNotificationCenter.current()
//        center.add(request) { (error : Error?) in
//             if let theError = error {
//                 // Handle any errors
//                 print("\(theError)")
//             }
//        }
        scheduleAppRefresh()
        scheduleSentryWatch()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App active")
        cancelAllPendingBGTask()
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.tether.sentry", using: nil) { task in
//        self.handleImageFetcherTask(task: task as! BGProcessingTask)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.tether.apprefresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func cancelAllPendingBGTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
       // Schedule a new refresh task.
        print("handling refresh")
       scheduleAppRefresh()

       // Create an operation that performs the main part of the background task.
//       let operation = RefreshAppContentsOperation()
//
//       // Provide the background task with an expiration handler that cancels the operation.
//       task.expirationHandler = {
//          operation.cancel()
//       }
//
//       // Inform the system that the background task is complete
//       // when the operation completes.
//       operation.completionBlock = {
//          task.setTaskCompleted(success: !operation.isCancelled)
//       }
//
//       // Start the operation.
//       OperationQueue.addOperation(operation)
     }
    
    func scheduleAppRefresh() {
       let request = BGAppRefreshTaskRequest(identifier: "com.tether.apprefresh")
       // Fetch no earlier than 5 seconds from now.
       request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 5)
            
       do {
          try BGTaskScheduler.shared.submit(request)
       } catch {
          print("Could not schedule app refresh: \(error)")
       }
    }
    
    func scheduleSentryWatch() {
        let request = BGProcessingTaskRequest(identifier: "com.tether.sentry")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5) // set next task no earlier than 5 seconds from now
        
        do {
           try BGTaskScheduler.shared.submit(request)
        } catch {
           print("Could not schedule sentry watch: \(error)")
        }
    }
    
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
          }
    }

    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
//        print("Notification settings: \(settings)")
      }
    }

}

