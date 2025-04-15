package finaldev.tjs_sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import android.view.WindowManager
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// translate from https://github.com/flutter/plugins/tree/master/packages/sensors
/** TJSSensorsPlugin */
public class TJSSensorsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private val METHOD_CHANNEL_NAME = "tjs_sensors/method"
  private val ACCELEROMETER_CHANNEL_NAME = "tjs_sensors/accelerometer"
  private val GYROSCOPE_CHANNEL_NAME = "tjs_sensors/gyroscope"
  private val MAGNETOMETER_CHANNEL_NAME = "tjs_sensors/magnetometer"
  private val USER_ACCELEROMETER_CHANNEL_NAME = "tjs_sensors/user_accelerometer"
  private val ORIENTATION_CHANNEL_NAME = "tjs_sensors/orientation"
  private val ABSOLUTE_ORIENTATION_CHANNEL_NAME = "tjs_sensors/absolute_orientation"
  private val SCREEN_ORIENTATION_CHANNEL_NAME = "tjs_sensors/screen_orientation"

  private var sensorManager: SensorManager? = null
  private var methodChannel: MethodChannel? = null
  private var accelerometerChannel: EventChannel? = null
  private var gyroscopeChannel: EventChannel? = null
  private var magnetometerChannel: EventChannel? = null
  private var userAccelerometerChannel: EventChannel? = null
  private var orientationChannel: EventChannel? = null
  private var absoluteOrientationChannel: EventChannel? = null
  private var screenOrientationChannel: EventChannel? = null


  private var accelerationStreamHandler: StreamHandlerImpl? = null
  private var gyroScopeStreamHandler: StreamHandlerImpl? = null
  private var magnetometerStreamHandler: StreamHandlerImpl? = null
  private var userAccelerationStreamHandler: StreamHandlerImpl? = null
  private var orientationStreamHandler: RotationVectorStreamHandler? = null
  private var absoluteOrientationStreamHandler: RotationVectorStreamHandler? = null
  private var screenOrientationStreamHandler: ScreenOrientationStreamHandler? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    val context = binding.applicationContext
    setupEventChannels(context, binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    teardownEventChannels()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "isSensorAvailable" -> result.success(sensorManager!!.getSensorList(call.arguments as Int).isNotEmpty())
      "setSensorUpdateInterval" -> setSensorUpdateInterval(call.argument<Int>("sensorType")!!, call.argument<Int>("interval")!!)
      else -> result.notImplemented()
    }
  }
  

  private fun setupEventChannels(context: Context, messenger: BinaryMessenger) {
    sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
    methodChannel!!.setMethodCallHandler(this)

    accelerometerChannel = EventChannel(messenger, ACCELEROMETER_CHANNEL_NAME)
    accelerationStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_ACCELEROMETER)
    accelerometerChannel!!.setStreamHandler(accelerationStreamHandler!!)

    userAccelerometerChannel = EventChannel(messenger, USER_ACCELEROMETER_CHANNEL_NAME)
    userAccelerationStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_LINEAR_ACCELERATION)
    userAccelerometerChannel!!.setStreamHandler(userAccelerationStreamHandler!!)

    gyroscopeChannel = EventChannel(messenger, GYROSCOPE_CHANNEL_NAME)
    gyroScopeStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_GYROSCOPE)
    gyroscopeChannel!!.setStreamHandler(gyroScopeStreamHandler!!)

    magnetometerChannel = EventChannel(messenger, MAGNETOMETER_CHANNEL_NAME)
    magnetometerStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_MAGNETIC_FIELD)
    magnetometerChannel!!.setStreamHandler(magnetometerStreamHandler!!)

    orientationChannel = EventChannel(messenger, ORIENTATION_CHANNEL_NAME)
    orientationStreamHandler = RotationVectorStreamHandler(sensorManager!!, Sensor.TYPE_GAME_ROTATION_VECTOR)
    orientationChannel!!.setStreamHandler(orientationStreamHandler!!)

    absoluteOrientationChannel = EventChannel(messenger, ABSOLUTE_ORIENTATION_CHANNEL_NAME)
    absoluteOrientationStreamHandler = RotationVectorStreamHandler(sensorManager!!, Sensor.TYPE_ROTATION_VECTOR)
    absoluteOrientationChannel!!.setStreamHandler(absoluteOrientationStreamHandler!!)

    screenOrientationChannel = EventChannel(messenger, SCREEN_ORIENTATION_CHANNEL_NAME)
    screenOrientationStreamHandler = ScreenOrientationStreamHandler(context, sensorManager!!, Sensor.TYPE_ACCELEROMETER)
    screenOrientationChannel!!.setStreamHandler(screenOrientationStreamHandler)
  }

  private fun teardownEventChannels() {
    methodChannel!!.setMethodCallHandler(null)
    accelerometerChannel!!.setStreamHandler(null)
    userAccelerometerChannel!!.setStreamHandler(null)
    gyroscopeChannel!!.setStreamHandler(null)
    magnetometerChannel!!.setStreamHandler(null)
    orientationChannel!!.setStreamHandler(null)
    absoluteOrientationChannel!!.setStreamHandler(null)
    screenOrientationChannel!!.setStreamHandler(null)
  }

  private fun setSensorUpdateInterval(sensorType: Int, interval: Int) {
    when (sensorType) {
      Sensor.TYPE_ACCELEROMETER -> accelerationStreamHandler!!.setUpdateInterval(interval*4000)
      Sensor.TYPE_MAGNETIC_FIELD -> magnetometerStreamHandler!!.setUpdateInterval(interval*4000)
      Sensor.TYPE_GYROSCOPE -> gyroScopeStreamHandler!!.setUpdateInterval(interval*4000)
      Sensor.TYPE_LINEAR_ACCELERATION -> userAccelerationStreamHandler!!.setUpdateInterval(interval*4000)
      Sensor.TYPE_GAME_ROTATION_VECTOR -> orientationStreamHandler!!.setUpdateInterval(interval*4000)
      Sensor.TYPE_ROTATION_VECTOR -> absoluteOrientationStreamHandler!!.setUpdateInterval(interval*4000)
    }
  }
}

class StreamHandlerImpl(private val sensorManager: SensorManager, sensorType: Int, private var interval: Int = SensorManager.SENSOR_DELAY_NORMAL) :
        EventChannel.StreamHandler, SensorEventListener {
  private val sensor = sensorManager.getDefaultSensor(sensorType)
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    if (sensor != null) {
      eventSink = events
      sensorManager.registerListener(this, sensor, interval)
    }
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    val sensorValues = listOf(event!!.values[0], event.values[1], event.values[2])
    eventSink?.success(sensorValues)
  }

  fun setUpdateInterval(interval: Int) {
    this.interval = interval
    if (eventSink != null) {
      sensorManager.unregisterListener(this)
      sensorManager.registerListener(this, sensor, interval)
    }
  }
}

class RotationVectorStreamHandler(private val sensorManager: SensorManager, sensorType: Int, private var interval: Int = SensorManager.SENSOR_DELAY_NORMAL) :
        EventChannel.StreamHandler, SensorEventListener {
  private val sensor = sensorManager.getDefaultSensor(sensorType)
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    if (sensor != null) {
      eventSink = events
      sensorManager.registerListener(this, sensor, interval)
    }
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    var matrix = FloatArray(9)
    SensorManager.getRotationMatrixFromVector(matrix, event!!.values)
    if (matrix[7] > 1.0f) matrix[7] = 1.0f
    if (matrix[7] < -1.0f) matrix[7] = -1.0f
    var orientation = FloatArray(3)
    SensorManager.getOrientation(matrix, orientation)
    val sensorValues = listOf(-orientation[0], -orientation[1], orientation[2])
    eventSink?.success(sensorValues)
  }

  fun setUpdateInterval(interval: Int) {
    this.interval = interval
    if (eventSink != null) {
      sensorManager.unregisterListener(this)
      sensorManager.registerListener(this, sensor, interval)
    }
  }
}

class ScreenOrientationStreamHandler(private val context: Context, private val sensorManager: SensorManager, sensorType: Int, private var interval: Int = SensorManager.SENSOR_DELAY_NORMAL) :
        EventChannel.StreamHandler, SensorEventListener {
  private val sensor = sensorManager.getDefaultSensor(sensorType)
  private var eventSink: EventChannel.EventSink? = null
  private var lastRotation: Double = -1.0

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    sensorManager.registerListener(this, sensor, interval)
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    val rotation = getScreenOrientation()
    if (rotation != lastRotation) {
      eventSink?.success(rotation)
      lastRotation = rotation
    }
  }

  fun setUpdateInterval(interval: Int) {
    this.interval = interval
    if (eventSink != null) {
      sensorManager.unregisterListener(this)
      sensorManager.registerListener(this, sensor, interval)
    }
  }

  private fun getScreenOrientation(): Double {
    return when ((context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay.rotation) {
      Surface.ROTATION_0 -> 0.0
      Surface.ROTATION_90 -> 90.0
      Surface.ROTATION_180 -> 180.0
      Surface.ROTATION_270 -> -90.0
      else -> 0.0
    }
  }
}