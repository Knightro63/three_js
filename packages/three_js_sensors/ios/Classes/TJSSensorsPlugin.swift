import Flutter
import UIKit
import CoreMotion

let GRAVITY = 9.8
let TYPE_ACCELEROMETER = 1
let TYPE_MAGNETIC_FIELD = 2
let TYPE_GYROSCOPE = 4
let TYPE_USER_ACCELEROMETER = 10
let TYPE_ORIENTATION = 11
let TYPE_ABSOLUTE_ORIENTATION = 15


// translate from https://github.com/flutter/plugins/tree/master/packages/sensors
public class TJSSensorsPlugin: NSObject, FlutterPlugin {
    private let accelerometerStreamHandler = AccelerometerStreamHandler()
    private let magnetometerStreamHandler = MagnetometerStreamHandler()
    private let gyroscopeStreamHandler = GyroscopeStreamHandler()
    private let userAccelerometerStreamHandler = UserAccelerometerStreamHandler()
    private let orientationStreamHandler = AttitudeStreamHandler(CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical)
    private let absoluteOrientationStreamHandler = AttitudeStreamHandler(CMAttitudeReferenceFrame.xMagneticNorthZVertical)
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let METHOD_CHANNEL_NAME = "tjs_sensors/method"
        let instance = TJSSensorsPlugin(registrar: registrar)
        let channel = FlutterMethodChannel(name: METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

    }
    
    init(registrar: FlutterPluginRegistrar) {
        let ACCELEROMETER_CHANNEL_NAME = "tjs_sensors/accelerometer"
        let MAGNETOMETER_CHANNEL_NAME = "tjs_sensors/magnetometer"
        let GYROSCOPE_CHANNEL_NAME = "tjs_sensors/gyroscope"
        let USER_ACCELEROMETER_CHANNEL_NAME = "tjs_sensors/user_accelerometer"
        let ORIENTATION_CHANNEL_NAME = "tjs_sensors/orientation"
        let ABSOLUTE_ORIENTATION_CHANNEL_NAME = "tjs_sensors/absolute_orientation"
        let SCREEN_ORIENTATION_CHANNEL_NAME = "tjs_sensors/screen_orientation"

        let accelerometerChannel = FlutterEventChannel(name: ACCELEROMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        accelerometerChannel.setStreamHandler(accelerometerStreamHandler)
        
        let magnetometerChannel = FlutterEventChannel(name: MAGNETOMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        magnetometerChannel.setStreamHandler(magnetometerStreamHandler)
        
        let gyroscopeChannel = FlutterEventChannel(name: GYROSCOPE_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        gyroscopeChannel.setStreamHandler(gyroscopeStreamHandler)
        
        let userAccelerometerChannel = FlutterEventChannel(name: USER_ACCELEROMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        userAccelerometerChannel.setStreamHandler(userAccelerometerStreamHandler)
        
        let orientationChannel = FlutterEventChannel(name: ORIENTATION_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        orientationChannel.setStreamHandler(orientationStreamHandler)

        let absoluteOrientationChannel = FlutterEventChannel(name: ABSOLUTE_ORIENTATION_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        absoluteOrientationChannel.setStreamHandler(absoluteOrientationStreamHandler)

        let screenOrientationChannel = FlutterEventChannel(name: SCREEN_ORIENTATION_CHANNEL_NAME, binaryMessenger: registrar.messenger())
        screenOrientationChannel.setStreamHandler(ScreenOrientationStreamHandler())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSensorAvailable":
            result(isSensorAvailable(call.arguments as! Int))
        case "setSensorUpdateInterval":
            let arguments = call.arguments as! NSDictionary
            setSensorUpdateInterval(arguments["sensorType"] as! Int, arguments["interval"] as! Int)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func isSensorAvailable(_ sensorType: Int) -> Bool {
        let motionManager = CMMotionManager()
        switch sensorType {
        case TYPE_ACCELEROMETER:
            return motionManager.isAccelerometerAvailable
        case TYPE_MAGNETIC_FIELD:
            return motionManager.isMagnetometerAvailable
        case TYPE_GYROSCOPE:
            return motionManager.isGyroAvailable
        case TYPE_USER_ACCELEROMETER:
            return motionManager.isDeviceMotionAvailable
        case TYPE_ORIENTATION:
            return motionManager.isDeviceMotionAvailable
        case TYPE_ABSOLUTE_ORIENTATION:
            return motionManager.isDeviceMotionAvailable
        default:
            return false
        }
    }
    
    public func setSensorUpdateInterval(_ sensorType: Int, _ interval: Int) {
        let timeInterval = TimeInterval(Double(interval)*0.000001)
        switch sensorType {
        case TYPE_ACCELEROMETER:
            accelerometerStreamHandler.setUpdateInterval(timeInterval)
        case TYPE_MAGNETIC_FIELD:
            magnetometerStreamHandler.setUpdateInterval(timeInterval)
        case TYPE_GYROSCOPE:
            gyroscopeStreamHandler.setUpdateInterval(timeInterval)
        case TYPE_USER_ACCELEROMETER:
            userAccelerometerStreamHandler.setUpdateInterval(timeInterval)
        case TYPE_ORIENTATION:
            orientationStreamHandler.setUpdateInterval(timeInterval)
        case TYPE_ABSOLUTE_ORIENTATION:
            absoluteOrientationStreamHandler.setUpdateInterval(timeInterval)
        default:
            break
        }
    }
}

class AccelerometerStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
                if data != nil {
                    events([-data!.acceleration.x * GRAVITY, -data!.acceleration.y * GRAVITY, -data!.acceleration.z * GRAVITY])
                }
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopAccelerometerUpdates()
        return nil
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        motionManager.accelerometerUpdateInterval = interval
    }
}

class UserAccelerometerStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: queue) { (data, error) in
                if data != nil {
                    events([-data!.userAcceleration.x * GRAVITY, -data!.userAcceleration.y * GRAVITY, -data!.userAcceleration.z * GRAVITY])
                }
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        return nil
    }

    func setUpdateInterval(_ interval: TimeInterval) {
        motionManager.deviceMotionUpdateInterval = interval
    }
}

class GyroscopeStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: queue) { (data, error) in
                if data != nil {
                    events([data!.rotationRate.x, data!.rotationRate.y, data!.rotationRate.z])
                }
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopGyroUpdates()
        return nil
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        motionManager.gyroUpdateInterval = interval
    }
}

class MagnetometerStreamHandler: NSObject, FlutterStreamHandler {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: queue) { (data, error) in
                if data != nil {
                    events([data!.magneticField.field.x, data!.magneticField.field.y, data!.magneticField.field.z])
                }
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        return nil
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        motionManager.deviceMotionUpdateInterval = interval
    }
}

class AttitudeStreamHandler: NSObject, FlutterStreamHandler {
    private var attitudeReferenceFrame:  CMAttitudeReferenceFrame
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    init(_ referenceFrame: CMAttitudeReferenceFrame) {
        attitudeReferenceFrame = referenceFrame
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true
            motionManager.startDeviceMotionUpdates(using: attitudeReferenceFrame, to: queue) { (data, error) in
                if data != nil {
                    // Let the y-axis point to magnetic north instead of the x-axis
                    if self.attitudeReferenceFrame == CMAttitudeReferenceFrame.xMagneticNorthZVertical {
                        let yaw = (data!.attitude.yaw + Double.pi + Double.pi / 2).truncatingRemainder(dividingBy: Double.pi * 2) - Double.pi
                        events([yaw, data!.attitude.pitch, data!.attitude.roll,data!.attitude.quaternion.x,data!.attitude.quaternion.y,data!.attitude.quaternion.z, data!.attitude.quaternion.w] )
                    } else {
                        events([data!.attitude.yaw, data!.attitude.pitch, data!.attitude.roll,data!.attitude.quaternion.x,data!.attitude.quaternion.y,data!.attitude.quaternion.z, data!.attitude.quaternion.w] )
                    }
                }
            }
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        return nil
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        motionManager.deviceMotionUpdateInterval = interval
    }
}

class ScreenOrientationStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink:  FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationChanged()
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
        return nil
    }
    
    @objc func orientationChanged() {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            eventSink!(0.0)
        case .portraitUpsideDown:
            eventSink!(180.0)
        case .landscapeLeft:
            eventSink!(-90.0)
        case .landscapeRight:
            eventSink!(90.0)
        default:
            eventSink!(0.0)
        }
    }
}