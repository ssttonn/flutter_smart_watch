package sstonn.example.flutter_smart_watch_harmony_os

import androidx.annotation.NonNull
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.AuthClient
import com.huawei.wearengine.auth.Permission
import com.huawei.wearengine.device.Device
import com.huawei.wearengine.device.DeviceClient

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlin.coroutines.CoroutineContext

/** FlutterSmartWatchHarmonyOsPlugin */
class FlutterSmartWatchHarmonyOsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var callbackChannel: MethodChannel
    private var scope: (CoroutineContext) -> CoroutineScope = {
        CoroutineScope(it)
    }

    //Activity and context references
    private var activityBinding: ActivityPluginBinding? = null

    // Callback for permission listener
    private var authCallback: AuthCallback? = null

    //clients use to authenticate with Wear Engine
    lateinit var deviceClient: DeviceClient
    lateinit var authClient: AuthClient

    //device list
    private var commonDevices: List<Device> = listOf()
    private var boundedDevices: List<Device> = listOf()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "sstonn/flutter_smart_watch_harmony_os"
            )
        callbackChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "sstonn/flutter_smart_watch_harmony_os_callback"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "configure" -> {
                activityBinding?.let {
                    authClient = HiWear.getAuthClient(it.activity)
                    deviceClient = HiWear.getDeviceClient(it.activity)
                }
                result.success(null)
            }
            "hasAvailableDevices" -> {
                scope(Dispatchers.IO).launch {
                    //Check if user has available devices
                    deviceClient.hasAvailableDevices().addOnSuccessListener {
                        scope(Dispatchers.Main).launch {
                            // return the result to flutter side
                            result.success(it)
                        }
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }
            }
            "addPermissionsListener" -> {
                authCallback = object : AuthCallback {
                    override fun onOk(p0: Array<out Permission>?) {
                        p0?.let {
                            callbackChannel.invokeMethod(
                                "permissionGranted",
                                it.map { permission -> findIndexFromPermission(permission) })
                        }
                    }

                    override fun onCancel() {
                        callbackChannel.invokeMethod(
                            "permissionCancelled",
                            null
                        )
                    }

                }
            }
            "removePermissionListener" -> {
                authCallback = null
            }
            "checkWearEnginePermission" -> {
                scope(Dispatchers.IO).launch {
                    val permissionIndex =
                        (call.arguments as HashMap<*, *>)["permissionIndex"] as Int
                    //check if the requested permission is granted
                    authClient.checkPermission(findPermissionFromIndex(permissionIndex))
                        .addOnSuccessListener {
                            scope(Dispatchers.Main).launch {
                                result.success(it)
                            }
                        }.addOnFailureListener {
                            handleFlutterError(result, it.message ?: it.localizedMessage)
                        }
                }
            }
            "checkWearEnginePermissions" -> {
                scope(Dispatchers.IO).launch {
                    val permissionIndexes =
                        (call.arguments as HashMap<*, *>)["permissionIndexes"] as List<*>
                    //check if the requested permission is granted
                    authClient.checkPermissions(permissionIndexes.map { findPermissionFromIndex(it as Int) }
                        .toTypedArray()).addOnSuccessListener {
                        scope(Dispatchers.Main).launch {
                            result.success(it)
                        }
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }
            }
            "requestPermissions" -> {
                scope(Dispatchers.IO).launch {
                    val permissionIndexes =
                        (call.arguments as HashMap<*, *>)["permissionIndexes"] as List<*>
                    authClient.requestPermission(
                        authCallback,
                        *permissionIndexes.map { findPermissionFromIndex(it as Int) }.toTypedArray()
                    ).addOnSuccessListener {
                        scope(Dispatchers.Main).launch {
                            result.success(null)
                        }
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }
            }
            "getBoundedDevices" -> {
                scope(Dispatchers.IO).launch {
                    deviceClient.bondedDevices.addOnSuccessListener {
                        scope(Dispatchers.Main).launch {
                            boundedDevices = it
                            result.success(boundedDevices.map {
                                it.toRawMap()
                            })
                        }
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }
            }
            "getCommonDevices" -> {
                scope(Dispatchers.IO).launch {
                    deviceClient.commonDevice.addOnSuccessListener {
                        scope(Dispatchers.Main).launch {
                            commonDevices = it
                            result.success(commonDevices.map {
                                it.toRawMap()
                            })
                        }
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }
            }
            "checkForDeviceCapability" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val queryId = arguments["queryId"] as Int
                var foundDevice: Device? = null
                // Check if deviceUUID contain on either common device or bounded device list
                if (commonDevices.any { it.uuid == deviceUUID }) {
                    foundDevice = commonDevices.filter { it.uuid == deviceUUID }[0]
                } else if (boundedDevices.any { it.uuid == deviceUUID }) {
                    foundDevice = commonDevices.filter { it.uuid == deviceUUID }[0]
                }
                if (foundDevice == null) {
                    handleFlutterError(result, "Can't find selected device")
                    return
                }
                // Query for device capability
                deviceClient.queryDeviceCapability(foundDevice, queryId).addOnSuccessListener {
                    // The device capability set is successfully queried.
                    // 0 = Device.DEVICE_CAPABILITY_SUPPORT: supported
                    // 1 = Device.CAPABILITY_NOT_SUPPORT: not supported
                    // 2 = Device.UNKNOWN
                    //Process logic when the device supports the CBTI capability set.
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
        }
    }

    private fun findPermissionFromIndex(index: Int): Permission {
        return when (index) {
            0 -> Permission.DEVICE_MANAGER
            1 -> Permission.NOTIFY
            2 -> Permission.SENSOR
            3 -> Permission.MOTION_SENSOR
            4 -> Permission.WEAR_USER_STATUS
            else -> Permission.DEVICE_MANAGER
        }
    }

    private fun findIndexFromPermission(permission: Permission): Int {
        return when (permission) {
            Permission.DEVICE_MANAGER -> 0
            Permission.NOTIFY -> 1
            Permission.SENSOR -> 2
            Permission.MOTION_SENSOR -> 3
            Permission.WEAR_USER_STATUS -> 4
            else -> 0
        }
    }

    private fun handleFlutterError(result: Result, message: String) {
        scope(Dispatchers.Main).launch {
            result.error("500", message, null)
        }
    }

    private fun Device.toRawMap(): HashMap<String, Any?> {
        return hashMapOf(
            "basicInfo" to this.basicInfo,
            "capability" to this.capability,
            "name" to this.name,
            "productType" to this.productType,
            "identify" to this.identify,
            "uuid" to this.uuid,
            "model" to this.model,
            "reservedness" to this.reservedness,
            "sorfwareVersion" to this.softwareVersion,
            "isConnected" to this.isConnected,
            "p2pCapability" to this.p2pCapability,
            "monitorCapability" to this.monitorCapability,
            "notifyCapability" to this.notifyCapability,
            "deviceCategory" to this.deviceCategory
        )
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }
}
