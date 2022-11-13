package sstonn.example.flutter_smart_watch_harmony_os

import androidx.annotation.NonNull
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.AuthClient
import com.huawei.wearengine.auth.Permission
import com.huawei.wearengine.client.ServiceConnectionListener
import com.huawei.wearengine.client.WearEngineClient
import com.huawei.wearengine.device.Device
import com.huawei.wearengine.device.DeviceClient
import com.huawei.wearengine.monitor.MonitorClient
import com.huawei.wearengine.monitor.MonitorData
import com.huawei.wearengine.monitor.MonitorItem
import com.huawei.wearengine.monitor.MonitorListener
import com.huawei.wearengine.notify.*
import com.huawei.wearengine.p2p.*
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
import java.io.*
import kotlin.coroutines.CoroutineContext

/** FlutterSmartWatchHarmonyOsPlugin */
class FlutterSmartWatchHarmonyOsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var callbackChannel: MethodChannel
    private var scope: (CoroutineContext) -> CoroutineScope = {
        CoroutineScope(it)
    }

    //companion app package name
    private var companionPackageName: String? = null

    //companion app fingerprint
    private var companionAppFingerprint: String? = null

    //Activity and context references
    private var activityBinding: ActivityPluginBinding? = null

    //clients use to authenticate with Wear Engine
    private lateinit var deviceClient: DeviceClient
    private lateinit var authClient: AuthClient
    private lateinit var monitorClient: MonitorClient
    private lateinit var p2pClient: P2pClient
    private lateinit var wearEngineClient: WearEngineClient
    private lateinit var notifyClient: NotifyClient

    //device list
    private var commonDevices: List<Device> = listOf()
    private var boundedDevices: List<Device> = listOf()

    // monitor listener use to detect device info + status
    private var monitorListeners: HashMap<String, MonitorListener> = hashMapOf()

    //message listener use to detect message received events
    private var messageListeners: HashMap<String, Receiver> = hashMapOf()

    private lateinit var connectionListener: ServiceConnectionListener

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
                    val arguments = call.arguments as HashMap<*, *>
                    // Init all dependencies
                    companionPackageName = arguments["companionPackageName"] as String?
                    companionAppFingerprint = arguments["companionAppFingerprint"] as String?
                    authClient = HiWear.getAuthClient(it.activity)
                    deviceClient = HiWear.getDeviceClient(it.activity)
                    monitorClient = HiWear.getMonitorClient(it.activity)
                    notifyClient = HiWear.getNotifyClient(it.activity)
                    p2pClient = HiWear.getP2pClient(it.activity)
                    p2pClient.setPeerPkgName(companionPackageName)
                    p2pClient.setPeerFingerPrint(companionAppFingerprint)
                    connectionListener = object : ServiceConnectionListener {
                        override fun onServiceConnect() {
                            // On connect
                            callbackChannel.invokeMethod("onConnectionChanged", true)
                        }

                        override fun onServiceDisconnect() {
                            //On Disconnect
                            callbackChannel.invokeMethod("onConnectionChanged", false)
                        }
                    }
                    //Create new wear engine client and attach connectionListener to listen to connection changed
                    wearEngineClient =
                        HiWear.getWearEngineClient(activityBinding!!.activity, connectionListener)
                    result.success(null)
                    return
                }
                handleFlutterError(result, "Can't configure Wear Engine Service, please try again")
            }
            "hasAvailableDevices" -> {
                //Check if user has available devices
                deviceClient.hasAvailableDevices().addOnSuccessListener {
                    // return the result to flutter side
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "addServiceConnectionListener" -> {
                unRegisterConnectionListener({
                    wearEngineClient.registerServiceConnectionListener().addOnSuccessListener {
                        result.success(null)
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                }, {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                })
            }
            "removeServiceConnectionListener" -> {
                // Remove connection listener and stop listen to connection changed
                unRegisterConnectionListener(
                    {
                        result.success(null)
                    }, {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
                )
            }
            "releaseConnection" -> {
                // Signal the WearEngine to release the connection => Disconnect all wearable devices
                wearEngineClient.releaseConnection().addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "getClientApiLevel" -> {
                // Get api level of the client app
                wearEngineClient.clientApiLevel.addOnSuccessListener {
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "getServiceApiLevel" -> {
                // Get api level of current WearEngine service
                wearEngineClient.serviceApiLevel.addOnSuccessListener {
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "checkWearEnginePermission" -> {
                val permissionIndex =
                    (call.arguments as HashMap<*, *>)["permissionIndex"] as Int
                //check if the requested permission is granted
                authClient.checkPermission(permissionIndex.toWearEnginePermission())
                    .addOnSuccessListener {
                        result.success(it)
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
            }
            "checkWearEnginePermissions" -> {
                val permissionIndexes =
                    (call.arguments as HashMap<*, *>)["permissionIndexes"] as List<*>
                //check if all requested permissions are granted
                authClient.checkPermissions(permissionIndexes.map { (it as Int).toWearEnginePermission() }
                    .toTypedArray()).addOnSuccessListener { permissionGrantedResults ->
                    val results: Map<Int, Boolean> = permissionGrantedResults.indices.map {
                        (permissionIndexes[it] as Int) to permissionGrantedResults[it]
                    }.toMap()
                    result.success(results)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "requestPermissions" -> {
                val arguments = (call.arguments as HashMap<*, *>)
                val permissionIndexes =
                    arguments["permissionIndexes"] as List<*>
                val requestId = arguments["requestId"] as String
                val authCallback = object : AuthCallback {
                    override fun onOk(p0: Array<out Permission>?) {
                        p0?.let {
                            callbackChannel.invokeMethod(
                                "permissionGranted",
                                mapOf(
                                    "permissionIndexes" to it.map { permission -> permission.indexFromPermission() },
                                    "requestId" to requestId
                                )
                            )
                        }
                    }

                    override fun onCancel() {
                        callbackChannel.invokeMethod(
                            "permissionCancelled",
                            mapOf(
                                "requestId" to requestId
                            )
                        )
                    }

                }
                authClient.requestPermission(
                    authCallback,
                    *permissionIndexes.map { (it as Int).toWearEnginePermission() }
                        .toTypedArray()
                ).addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "getBoundedDevices" -> {
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
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                }
                // Query for device capability
                deviceClient.queryDeviceCapability(foundDevice, queryId).addOnSuccessListener {
                    // The device capability set is successfully queried.
                    // 0 = Device.DEVICE_CAPABILITY_SUPPORT: supported
                    // 1 = Device.CAPABILITY_NOT_SUPPORT: not supported
                    // 2 = Device.UNKNOWN
                    //  Process logic when the device supports the CBTI capability set.
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "getAvailableKBytes" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                }
                deviceClient.getAvailableKbytes(foundDevice).addOnSuccessListener {
                    // Return the available storage space (KB) of a specified device.
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "queryForMonitorData" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val monitorItemIndex = arguments["monitorItemIndex"] as Int
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                val monitorItem = monitorItemIndex.toMonitorItem()
                monitorClient.query(foundDevice, monitorItem).addOnSuccessListener {
                    result.success(
                        hashMapOf(
                            "monitorItemIndex" to monitorItem.index(),
                            "data" to it.toHashMap()
                        )
                    )
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "registerMonitorListener" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                unRegisterMonitorListener(deviceUUID, {
                    val monitorItemIndexes =
                        arguments["monitorItemIndexes"] as List<*>
                    monitorListeners[deviceUUID] =
                        MonitorListener { errorCode, monitorItem, monitorData ->
                            if (errorCode != 0) return@MonitorListener
                            callbackChannel.invokeMethod(
                                "monitorItemChanged", hashMapOf(
                                    "monitorItemIndex" to monitorItem.index(),
                                    "data" to monitorData.toHashMap()
                                )
                            )
                        }
                    val monitorItemList: ArrayList<MonitorItem> = ArrayList()
                    monitorItemIndexes.forEach { index ->
                        monitorItemList.add((index as Int).toMonitorItem())
                    }
                    monitorClient.register(
                        foundDevice,
                        monitorItemList,
                        monitorListeners[deviceUUID]
                    )
                        .addOnSuccessListener {
                            result.success(null)
                        }.addOnFailureListener {
                            handleFlutterError(result, it.message ?: it.localizedMessage)
                        }
                }, {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                })
            }
            "removeMonitorListener" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                unRegisterMonitorListener(deviceUUID, {
                    result.success(null)
                }, {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                })
            }
            "isCompanionAppInstalled" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                p2pClient.isAppInstalled(foundDevice, companionPackageName).addOnSuccessListener {
                    // true if companion app has been installed, false for otherwise
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "getCompanionAppVersion" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                p2pClient.getAppVersion(foundDevice, companionPackageName).addOnSuccessListener {
                    // -1: The app has not been installed
                    result.success(it)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "checkForCompanionAppRunningStatus" -> {
                val arguments = call.arguments as HashMap<*, *>
                val pingId = arguments["pingId"] as String
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                val pingCallback = PingCallback {
                    // Result of communicating with the peer device using the ping method.
                    // If the errCode value is 200, your app has not been installed on the wearable device. If the errCode value is 201, your app has been installed but not started on the wearable device. If the errCode value is 202, your app has been started on the wearable device.
                    callbackChannel.invokeMethod(
                        "onConnectedWearableDeviceReplied", hashMapOf(
                            "pingId" to pingId,
                            "code" to it
                        )
                    )
                }

                // ping to wearable device and ready to receive callback
                p2pClient.ping(foundDevice, pingCallback).addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
            "sendNormalMessage" -> {
                val arguments = call.arguments as HashMap<*, *>
                val sendId = arguments["sendId"] as String
                val messageMap = arguments["data"] as HashMap<*, *>
                val messageDescription = arguments["messageDescription"] as String
                val enableEncrypt = arguments["enableEncrypt"] as Boolean
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }

                // Build a message
                val messageBuilder = Message.Builder()
                // Put message map as payload
                messageBuilder.setPayload(messageMap.toByteArray())
                messageBuilder.setDescription(messageDescription)
                messageBuilder.setEnableEncrypt(enableEncrypt)

                val sendCallback = object : SendCallback {
                    override fun onSendResult(code: Int) {
                        // If the resultCode value is 207, the messages have been sent successfully. Other values indicate that the messages fail to be sent.
                        callbackChannel.invokeMethod(
                            "onMessageSendResultDidCome", hashMapOf(
                                "sendId" to sendId,
                                "code" to code
                            )
                        )
                    }

                    override fun onSendProgress(progress: Long) {
                        callbackChannel.invokeMethod(
                            "onMessageSendProgressChanged", hashMapOf(
                                "sendId" to sendId,
                                "progress" to progress
                            )
                        )
                    }
                }
                p2pClient.send(foundDevice, messageBuilder.build(), sendCallback)
                    .addOnSuccessListener {
                        result.success(null)
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
            }
            "sendFile" -> {
                val arguments = call.arguments as HashMap<*, *>
                val sendId = arguments["sendId"] as String
                val filePath = arguments["filePath"] as String
                val messageDescription = arguments["messageDescription"] as String
                val enableEncrypt = arguments["enableEncrypt"] as Boolean
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                val sendFile = File(filePath)

                // Check if the file is exist
                if (!sendFile.exists()) {
                    handleFlutterError(
                        result,
                        "Unable to find corresponding file, please try again"
                    )
                    return
                }

                // Build a message
                val messageBuilder = Message.Builder()
                // Put message map as payload
                messageBuilder.setPayload(sendFile)
                messageBuilder.setDescription(messageDescription)
                messageBuilder.setEnableEncrypt(enableEncrypt)

                val sendCallback = object : SendCallback {
                    override fun onSendResult(code: Int) {
                        // If the resultCode value is 207, the messages have been sent successfully. Other values indicate that the messages fail to be sent.
                        callbackChannel.invokeMethod(
                            "onMessageSendResultDidCome", hashMapOf(
                                "sendId" to sendId,
                                "code" to code
                            )
                        )
                    }

                    override fun onSendProgress(progress: Long) {
                        callbackChannel.invokeMethod(
                            "onMessageSendProgressChanged", hashMapOf(
                                "sendId" to sendId,
                                "progress" to progress
                            )
                        )
                    }

                }
                p2pClient.send(foundDevice, messageBuilder.build(), sendCallback)
                    .addOnSuccessListener {
                        result.success(null)
                    }.addOnFailureListener {
                        handleFlutterError(result, it.message ?: it.localizedMessage)
                    }
            }
            "registerMessageReceivedListener" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }
                unRegisterMessageReceivedListener(deviceUUID, {
                    val receiver = Receiver {
                        callbackChannel.invokeMethod(
                            "onMessageReceived", hashMapOf(
                                "deviceUUID" to deviceUUID,
                                "message" to it.toRawMap()
                            )
                        )
                    }
                    messageListeners[deviceUUID] = receiver
                    p2pClient.registerReceiver(foundDevice, messageListeners[deviceUUID])
                        .addOnSuccessListener {
                            result.success(null)
                        }.addOnFailureListener {
                            handleFlutterError(result, it.message ?: it.localizedMessage)
                        }
                }, {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                })
            }
            "removeMessageReceivedListener" -> {
                val arguments = call.arguments as HashMap<*, *>
                val deviceUUID = arguments["deviceUUID"] as String
                unRegisterMessageReceivedListener(deviceUUID, {
                    result.success(null)
                }, {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                })
            }
            "sendNotification" -> {
                val arguments = call.arguments as HashMap<*, *>
                val sendId = arguments["sendId"] as String
                val deviceUUID = arguments["deviceUUID"] as String
                val notificationOptions = arguments["notificationOptions"] as HashMap<*, *>
                val notificationButtonContents = notificationOptions["buttonContents"] as List<*>
                val wearablePackageName =
                    notificationOptions["wearablePackageName"] as String? ?: companionPackageName
                val notificationTitle = notificationOptions["title"] as String
                val notificationContent = notificationOptions["content"] as String
                val foundDevice: Device? = findDevice(deviceUUID)
                if (foundDevice == null) {
                    handleFlutterError(
                        result,
                        "Device not found, please refresh device list and try again"
                    )
                    return
                }

                //Build notification
                val notificationBuilder: Notification.Builder = Notification.Builder()
                notificationBuilder.setTemplateId(
                    NotificationTemplate.getTemplateForTemplateId(
                        50 + notificationButtonContents.count()
                    )
                )
                notificationBuilder.setPackageName(wearablePackageName)
                notificationBuilder.setTitle(notificationTitle)
                notificationBuilder.setText(notificationContent)

                val buttonContents = hashMapOf<Int, String>()
                if (notificationButtonContents.isNotEmpty()) {
                    buttonContents[NotificationConstants.BUTTON_ONE_CONTENT_KEY] =
                        notificationButtonContents[0] as String
                }
                if (notificationButtonContents.count() >= 2) {
                    buttonContents[NotificationConstants.BUTTON_TWO_CONTENT_KEY] =
                        notificationButtonContents[1] as String
                }
                if (notificationButtonContents.count() >= 3) {
                    buttonContents[NotificationConstants.BUTTON_THREE_CONTENT_KEY] =
                        notificationButtonContents[2] as String
                }
                notificationBuilder.setButtonContents(buttonContents)

                val action: Action = object : Action {
                    override fun onResult(notification: Notification?, feedback: Int) {
                        callbackChannel.invokeMethod(
                            "onNotificationResult", hashMapOf(
                                "sendId" to sendId,
                                "notification" to notification?.toRawMap()
                            )
                        )
                    }

                    override fun onError(
                        notification: Notification?,
                        errorCode: Int,
                        errorMsg: String
                    ) {
                        callbackChannel.invokeMethod(
                            "onNotificationError", hashMapOf(
                                "sendId" to sendId,
                                "notification" to notification?.toRawMap(),
                                "errorCode" to errorCode,
                                "errorMsg" to errorMsg
                            )
                        )
                    }

                }

                notificationBuilder.setAction(action)

                val notification = notificationBuilder.build()

                notifyClient.notify(foundDevice, notification).addOnSuccessListener {
                    result.success(null)
                }.addOnFailureListener {
                    handleFlutterError(result, it.message ?: it.localizedMessage)
                }
            }
        }
    }

    private fun unRegisterMonitorListener(
        deviceUUID: String,
        onSuccess: () -> Unit,
        onFailure: (e: Exception) -> Unit
    ) {
        if (monitorListeners.containsKey(deviceUUID)) {
            monitorClient.unregister(monitorListeners[deviceUUID]).addOnSuccessListener {
                onSuccess()
            }.addOnFailureListener {
                onFailure(it)
            }
        } else {
            onSuccess()
        }
    }

    private fun unRegisterMessageReceivedListener(
        deviceUUID: String,
        onSuccess: () -> Unit,
        onFailure: (e: Exception) -> Unit
    ) {
        if (messageListeners.containsKey(deviceUUID)) {
            p2pClient.unregisterReceiver(messageListeners[deviceUUID]).addOnSuccessListener {
                onSuccess()
            }.addOnFailureListener {
                onFailure(it)
            }
        } else {
            onSuccess()
        }
    }

    private fun unRegisterConnectionListener(
        onSuccess: () -> Unit,
        onFailure: (e: Exception) -> Unit
    ) {
        wearEngineClient.unregisterServiceConnectionListener().addOnSuccessListener {
            onSuccess()
        }.addOnFailureListener {
            onFailure(it)
        }
    }

    private fun MonitorData.toHashMap(): HashMap<String, Any?> {
        return hashMapOf(
            "intData" to this.asInt(),
            "mapData" to this.asMap().map {
                it.key to it.value.toHashMap()
            },
            "boolData" to this.asBool(),
            "stringData" to this.asString()
        )
    }

    private fun findDevice(deviceUUID: String): Device? {
        // Check if deviceUUID contain on either common device or bounded device list
        if (commonDevices.any { it.uuid == deviceUUID }) {
            return commonDevices.filter { it.uuid == deviceUUID }[0]
        } else if (boundedDevices.any { it.uuid == deviceUUID }) {
            return commonDevices.filter { it.uuid == deviceUUID }[0]
        }
        return null
    }

    private fun MonitorItem.index(): Int {
        return when (this) {
            MonitorItem.MONITOR_ITEM_CONNECTION -> 0
            MonitorItem.MONITOR_ITEM_WEAR -> 1
            MonitorItem.MONITOR_ITEM_SLEEP -> 2
            MonitorItem.MONITOR_ITEM_LOW_POWER -> 3
            MonitorItem.MONITOR_ITEM_SPORT -> 4
            MonitorItem.MONITOR_POWER_STATUS -> 5
            MonitorItem.MONITOR_CHARGE_STATUS -> 6
            MonitorItem.MONITOR_ITEM_HEART_RATE_ALARM -> 7
            MonitorItem.MONITOR_ITEM_USER_AVAILABLE_KBYTES -> 8
            else -> 0
        }
    }

    private fun Int.toMonitorItem(): MonitorItem {
        return when (this) {
            0 -> MonitorItem.MONITOR_ITEM_CONNECTION
            1 -> MonitorItem.MONITOR_ITEM_WEAR
            2 -> MonitorItem.MONITOR_ITEM_SLEEP
            3 -> MonitorItem.MONITOR_ITEM_LOW_POWER
            4 -> MonitorItem.MONITOR_ITEM_SPORT
            5 -> MonitorItem.MONITOR_POWER_STATUS
            6 -> MonitorItem.MONITOR_CHARGE_STATUS
            7 -> MonitorItem.MONITOR_ITEM_HEART_RATE_ALARM
            8 -> MonitorItem.MONITOR_ITEM_USER_AVAILABLE_KBYTES
            else -> MonitorItem.MONITOR_ITEM_CONNECTION
        }
    }

    private fun Int.toWearEnginePermission(): Permission {
        return when (this) {
            0 -> Permission.DEVICE_MANAGER
            1 -> Permission.NOTIFY
            2 -> Permission.SENSOR
            3 -> Permission.MOTION_SENSOR
            4 -> Permission.WEAR_USER_STATUS
            else -> Permission.DEVICE_MANAGER
        }
    }


    private fun Permission.indexFromPermission(): Int {
        return when (this) {
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
            "softwareVersion" to this.softwareVersion,
            "isConnected" to this.isConnected,
            "p2pCapability" to this.p2pCapability,
            "monitorCapability" to this.monitorCapability,
            "notifyCapability" to this.notifyCapability,
            "deviceCategory" to this.deviceCategory
        )
    }

    private fun Message.toRawMap(): HashMap<String, Any?> {
        return hashMapOf(
            "messageData" to this.data.toHashMap(),
            "filePath" to this.file.path,
            "description" to this.description,
            "type" to this.type,
            "isEnableEncrypt" to this.isEnableEncrypt,
        )
    }

    private fun Notification.toRawMap(): HashMap<String, Any?> {
        return hashMapOf(
            "templateId" to templateId,
            "packageName" to packageName,
            "title" to title,
            "content" to text,
            "buttonContents" to buttonContents
        )
    }

    private fun HashMap<*, *>.toByteArray(): ByteArray {
        val byteOut = ByteArrayOutputStream()
        val out = ObjectOutputStream(byteOut)
        out.writeObject(this)
        return byteOut.toByteArray()
    }

    private fun ByteArray.toHashMap(): HashMap<*, *> {
        val byteIn = ByteArrayInputStream(this)
        val ins = ObjectInputStream(byteIn)
        return ins.readObject() as HashMap<*, *>
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
