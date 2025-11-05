import Flutter
import UIKit
import GoogleMaps
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase first
    FirebaseApp.configure()
    
    // Configure Google Maps
    GMSServices.provideAPIKey("AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0")
    
    // Set up Firebase Messaging
    Messaging.messaging().delegate = self
    
    // Request authorization for notifications
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        print("Notification authorization granted: \(granted)")
        if let error = error {
          print("Notification authorization error: \(error)")
        }
      }
    )
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    // Set up notification presentation options
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle successful registration for remote notifications
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("APNs device token: \(deviceToken)")
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // Handle failed registration for remote notifications
  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
  }
}
