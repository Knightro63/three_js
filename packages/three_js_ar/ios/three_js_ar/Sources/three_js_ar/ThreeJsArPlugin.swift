import Flutter
import UIKit
import ARKit

public class ThreeJsArPlugin: NSObject, FlutterPlugin {
  private let arManager = ARManager()
  private var registrar: FlutterPluginRegistrar

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "three_js_ar/method", binaryMessenger: registrar.messenger())
    let instance = ThreeJsArPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
      
    let armanagerChannel = FlutterEventChannel(name: "three_js_ar/armanager", binaryMessenger: registrar.messenger())
    armanagerChannel.setStreamHandler(arManager)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "isSupported":
      result(ARWorldTrackingConfiguration.isSupported)
    case "startStream":
      arManager.startSession()
    case "createTexture":
      arManager.texture = ARCameraTexture(messenger: registrar.messenger(), textureRegistry: registrar.textures())
      result(["textureId": arManager.texture?.textureId])
    case "stopStream":
      arManager.pauseSession()
    case "handleTap":
        guard let args = call.arguments as? [String: Double],
              let x = args["x"],
              let y = args["y"],
              let width = args["width"],
              let height = args["height"] else {
            result(FlutterError(code: "invalid_argument", message: "Missing coordinates or widget size", details: nil))
            return
        }
        
        let point = CGPoint(x: x, y: y)
        let size = CGSize(width: width, height: height)
        
        let raycastResults = arManager.performRaycast(at: point, flutterWidgetSize: size)
        result(raycastResults)
    case "textureFrameAvailable":
      arManager.texture?.textureFrameAvailable()
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class ARCameraTexture: NSObject, FlutterTexture {
  private var latestPixelBuffer: CVPixelBuffer?
  private var textureRegistry: FlutterTextureRegistry
  var textureId: Int64?
  private var messenger: FlutterBinaryMessenger?
    
  init(messenger: FlutterBinaryMessenger, textureRegistry: FlutterTextureRegistry) {
    self.messenger = messenger
    self.textureRegistry = textureRegistry
    super.init()
    self.textureId = textureRegistry.register(self)
    FlutterMethodChannel(name: "three_js_ar/texture", binaryMessenger: messenger).invokeMethod("textureId", arguments: textureId)
  }
    
  func update(with pixelBuffer: CVPixelBuffer) {
    latestPixelBuffer = pixelBuffer
  }

  func textureFrameAvailable(){
    if let textureId = self.textureId {
      textureRegistry.textureFrameAvailable(textureId)
    }
  }
  
  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let pixelBuffer = latestPixelBuffer else { return nil }
    return Unmanaged.passRetained(pixelBuffer)
  }
}

class ARManager: NSObject, ARSessionDelegate {
  let arSession = ARSession()
  private var eventSink: FlutterEventSink?
  var texture: ARCameraTexture?
  private var latestFrame: ARFrame?
    
  override init() {
    super.init()
    arSession.delegate = self
  }
    
  func startSession() {
    guard ARWorldTrackingConfiguration.isSupported else {
      print("ARWorldTrackingConfiguration is not supported on this device.")
      return
    }

    let configuration = ARWorldTrackingConfiguration()
    arSession.run(configuration)
  }

  func pauseSession() {
    arSession.pause()
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame){
    latestFrame = frame
    texture?.update(with: frame.capturedImage)
    sendFrameData(frame)
  }

  func performRaycast1(at point: CGPoint) -> [Float]?{
    guard let latestFrame = latestFrame else { return nil}

    // First, prioritize existing planes using their geometry.
    var results = latestFrame.hitTest(point, types: [.existingPlaneUsingGeometry])
    
    // If no existing plane was hit, try estimated planes.
    if results.isEmpty {
      results = latestFrame.hitTest(point, types: [.estimatedHorizontalPlane, .estimatedVerticalPlane])
    }

    if let firstResult = results.first {
      let transform = firstResult.worldTransform
      let position = [
        transform.columns.3.x,
        transform.columns.3.y,
        transform.columns.3.z
      ]
      
      return position
    }
      
    return nil
  }
    // Change this line in your arManager file to include the second parameter:
    public func performRaycast(at point: CGPoint, flutterWidgetSize: CGSize) -> [[Float]]? {
        guard let currentFrame = arSession.currentFrame else { return nil }

        // Normalized coordinates (0.0 to 1.0)
        let normalizedPoint = CGPoint(
            x: point.x / flutterWidgetSize.width,
            y: point.y / flutterWidgetSize.height
        )
        
        // Transform coordinates based on screen orientation
        let displayTransform = currentFrame.displayTransform(
            for: UIInterfaceOrientation.landscapeRight,
            viewportSize: flutterWidgetSize
        )
        let cameraPoint = normalizedPoint.applying(displayTransform.inverted())
        
        let query = currentFrame.raycastQuery(
            from: cameraPoint,
            allowing: ARRaycastQuery.Target.existingPlaneInfinite,
            alignment: ARRaycastQuery.TargetAlignment.any
        )
        
        // Map transforms to an array of dictionaries for Flutter compatibility
        return arSession.raycast(query).map { hit in
            let transform = hit.worldTransform
            return [
                    transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
                    transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
                    transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
                    transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
            ]
        }
    }
  // Send data to Flutter via the event sink
  private func sendFrameData(_ frame: ARFrame) {
    let cameraTransform = frame.camera.transform
    let matrixArray = [
      cameraTransform.columns.0.x, cameraTransform.columns.0.y, cameraTransform.columns.0.z, cameraTransform.columns.0.w,
      cameraTransform.columns.1.x, cameraTransform.columns.1.y, cameraTransform.columns.1.z, cameraTransform.columns.1.w,
      cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z, cameraTransform.columns.2.w,
      cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z, cameraTransform.columns.3.w
    ]
    
    DispatchQueue.main.async {
      self.eventSink?(matrixArray)
    }
  }
}

extension ARManager: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    startSession()
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    pauseSession()
    return nil
  }
}
