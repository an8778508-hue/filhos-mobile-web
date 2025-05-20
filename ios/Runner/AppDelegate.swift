import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Request permission for notifications
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
        if let error = error {
            print("Permission error: \(error)")
        }
    }

    // Set up the Flutter method channel
    let controller = window?.rootViewController as! FlutterViewController
    let alarmChannel = FlutterMethodChannel(name: "com.example.alarm/method_channel",
                                            binaryMessenger: controller.binaryMessenger)
    
    alarmChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        // Handle method channel
        self?.handle(call, result: result)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "setAlarm" {
      

        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "ERROR", message: "Arguments are not in the expected format", details: nil))
            return
        }

        // Print individual arguments
        let id = args["id"] as? String
        let dateStr = args["date"] as? String
        let title = args["title"] as? String
        let body = args["body"] as? String




        guard let unwrappedId = id, let unwrappedDateStr = dateStr, let alarmBody = body,let alarmTitle = title else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for 'setAlarm'. Expected 'id' and 'date' and 'title' and 'body' .", details: nil))
            return
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        // Try parsing the date string
        if let date = dateFormatter.date(from: unwrappedDateStr) {
            scheduleAlarm(id: unwrappedId, date: date,title: alarmTitle,body: alarmBody)
            result(nil)
        } else {
            // Attempt parsing with a different format (without fractional seconds)
            dateFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withFractionalSeconds]
            if let date = dateFormatter.date(from: unwrappedDateStr) {

                scheduleAlarm(id: unwrappedId, date: date,title: alarmTitle,body: alarmBody)
                result(nil)
            } else {

                result(FlutterError(code: "DATE_PARSING_FAILED", message: "Failed to parse the date string.", details: nil))
            }
        }
      } else if call.method == "cancelAlarm" {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for 'cancelAlarm'. Expected 'id'.", details: nil))
            return
        }
        
        cancelAlarm(id: id)
        result(nil)
    } else {
          result(FlutterMethodNotImplemented)
      }
  }

  private func cancelAlarm(id: String) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
}

  private func scheduleAlarm(id: String, date: Date,title: String,body: String) {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = UNNotificationSound.default

      let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second,], from: date)
      let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

      UNUserNotificationCenter.current().add(request) { (error) in
          if let error = error {
              print("Error scheduling alarm: \(error)")
          }
      }
  }

  // Additional app delegate functions if needed...
}
