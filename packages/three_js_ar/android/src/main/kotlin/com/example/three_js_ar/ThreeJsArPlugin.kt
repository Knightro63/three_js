package com.example.three_js_ar

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ThreeJsArPlugin */
class ThreeJsArPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var arSession: Session? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "three_js_ar")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  fun createArSession(activity: Activity, userRequestedInstall: Boolean, isFrontCamera: Boolean): Session? {
      var session: Session? = null
      // if we have the camera permission, create the session
      if (hasCameraPermission(activity)) {
          session = when (ArCoreApk.getInstance().requestInstall(activity, userRequestedInstall)) {
              ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                  Log.i(TAG, "ArCore INSTALL REQUESTED")
                  null
              }
              else -> {
                  if (isFrontCamera) {
                      Session(activity, EnumSet.of(Session.Feature.FRONT_CAMERA))
                  } else {
                      Session(activity)
                  }
              }
          }
          session?.let {
              val filter = CameraConfigFilter(it)
              filter.setTargetFps(EnumSet.of(CameraConfig.TargetFps.TARGET_FPS_30))
              filter.setDepthSensorUsage(EnumSet.of(CameraConfig.DepthSensorUsage.DO_NOT_USE))
              val cameraConfigList = it.getSupportedCameraConfigs(filter)
              it.cameraConfig = cameraConfigList[0]
          }

      }
      return session
  }
}
