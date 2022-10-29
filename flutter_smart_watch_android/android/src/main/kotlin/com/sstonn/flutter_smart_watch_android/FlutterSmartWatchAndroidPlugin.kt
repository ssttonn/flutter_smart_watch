package com.sstonn.flutter_smart_watch_android

import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.wearable.*
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
import kotlinx.coroutines.tasks.await

/** FlutterSmartWatchAndroidPlugin */
class FlutterSmartWatchAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var callbackChannel: MethodChannel
    private var scope: CoroutineScope = CoroutineScope(Dispatchers.IO)

    //Clients needed for Data Layer API
    private lateinit var messageClient: MessageClient
    private lateinit var nodeClient: NodeClient
    private lateinit var dataClient: DataClient
    private lateinit var capabilityClient: CapabilityClient

    //Activity and context references
    private var activityBinding: ActivityPluginBinding? = null

    //Listeners for capability changed
    private var capabilityListeners: MutableMap<String, CapabilityClient.OnCapabilityChangedListener> =
        mutableMapOf()

    //Listener for message received
    private var messageListeners: MutableMap<String, MessageClient.OnMessageReceivedListener?> =
        mutableMapOf()

    //Listener for data changed
    private var dataChangeListeners: MutableMap<String, DataClient.OnDataChangedListener?> =
        mutableMapOf()


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "sstonn/flutter_smart_watch_android"
        )
        callbackChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "sstonn/flutter_smart_watch_android_callback"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        activityBinding = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isSupported" -> {
                result.success(true)
            }
            "configure" -> {
                // Initialize all clients
                activityBinding?.let { it ->
                    messageClient = Wearable.getMessageClient(it.activity)
                    nodeClient = Wearable.getNodeClient(it.activity)
                    dataClient = Wearable.getDataClient(it.activity)
                    capabilityClient = Wearable.getCapabilityClient(it.activity)
                }
                result.success(null)
            }
            "getConnectedDevices" -> {
                scope.launch {
                    try {
                        val nodes = nodeClient.connectedNodes.await()
                        result.success(nodes.map { it.toRawMap() })
                    } catch (_: Exception) {
                        handleFlutterError(
                            result,
                            "Can't retrieve connected devices, please try again"
                        )
                    }
                }
            }
            "getCompanionPackageForDevice" -> {
                val nodeId = call.arguments as String?
                nodeId?.let {
                    scope.launch {
                        try {
                            val packageName: String =
                                nodeClient.getCompanionPackageForNode(it).await()
                            result.success(packageName)
                        } catch (_: Exception) {
                            handleFlutterError(result, "No companion package found for $nodeId")
                        }

                    }
                }
            }
            "getLocalDeviceInfo" -> {
                scope.launch {
                    try {
                        result.success(nodeClient.localNode.await().toRawMap())
                    } catch (_: Exception) {
                        handleFlutterError(
                            result,
                            "Can't retrieve local device info, please try again"
                        )
                    }
                }
            }
            "findDeviceIdFromBluetoothAddress" -> {
                val macAddress: String? = call.arguments as String?
                macAddress?.let {
                    scope.launch {
                        try {
                            result.success(nodeClient.getNodeId(it).await())
                        } catch (_: Exception) {
                            result.success(null)
                        }
                    }
                    return
                }
                result.success(null)
            }
            "getAllCapabilities" -> {
                val filterType = call.arguments as Int
                scope.launch {
                    try {
                        val capabilities =
                            capabilityClient.getAllCapabilities(filterType)
                                .await().entries.associate { it.key to it.value.toRawMap() }
                        result.success(capabilities)
                    } catch (e: Exception) {
                        result.success(emptyMap<String, Map<String, Any>>())
                    }
                }
            }
            "findCapabilityByName" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String
                val filterType = arguments["filterType"] as Int
                scope.launch {
                    try {
                        result.success(
                            capabilityClient.getCapability(name, filterType).await().toRawMap()
                        )
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
            }
            "addCapabilityListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                val filterType = arguments["filterType"] as Int?
                if (name != null) {
                    addNewCapabilityListener(result, name, null)
                } else if (path != null) {
                    addNewCapabilityListener(result, path, filterType)
                }
            }
            "removeCapabilityListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                if (name != null || path != null) {
                    removeCapabilityListener(result, (name ?: path)!!)
                }
            }
            "registerNewCapability" -> {
                val capabilityName: String? =
                    call.arguments as String?
                capabilityName?.let {
                    scope.launch {
                        try {
                            capabilityClient.addLocalCapability(capabilityName)
                            result.success(null)
                        } catch (e: Exception) {
                            handleFlutterError(
                                result,
                                "Unable to register new capability, please try again"
                            )
                        }
                    }
                    return
                }
                result.success(null)
            }
            "removeExistingCapability" -> {
                val capabilityName: String? =
                    call.arguments as String?
                capabilityName?.let {
                    scope.launch {
                        try {
                            capabilityClient.removeLocalCapability(capabilityName)
                            result.success(null)
                        } catch (e: Exception) {
                            handleFlutterError(
                                result,
                                "Unable to remove capability, please try again"
                            )
                        }
                    }
                    return
                }
                result.success(null)
            }
            "sendMessage" -> {
                val arguments = call.arguments as Map<*, *>
                val data = arguments["data"] as ByteArray
                val nodeId = arguments["nodeId"] as String
                val path = arguments["path"] as String
                val priority = arguments["priority"] as Int
                scope.launch {
                    try {
                        result.success(
                            messageClient.sendMessage(
                                nodeId,
                                path,
                                data,
                                MessageOptions(priority)
                            ).await()
                        )
                    } catch (e: Exception) {
                        handleFlutterError(result, e.message ?: "")
                    }
                }
            }
            "addMessageListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                val filterType = arguments["filterType"] as Int?
                if (name != null) {
                    addNewMessageListener(result, name, null)
                } else if (path != null) {
                    addNewMessageListener(result, path, filterType)
                }
            }
            "removeMessageListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                if (name != null || path != null) {
                    removeMessageListener(result, (name ?: path)!!)
                }
            }
            "findDataItem" -> {
                val path = call.arguments as String
                scope.launch {
                    try {
                        result.success(dataClient.getDataItem(Uri.parse(path)).await().toRawMap())
                    } catch (e: Exception) {
                        handleFlutterError(
                            result,
                            "Unable to find data item associated with $path"
                        )
                    }
                }
            }
            "findDataItems" -> {
                val path = call.arguments as String
                scope.launch {
                    try {
                        result.success(dataClient.getDataItems(Uri.parse(path)).await())
                    } catch (e: Exception) {
                        handleFlutterError(
                            result,
                            "Unable to find data items associated with $path"
                        )
                    }
                }
            }
            "getAllDataItems" -> {
                scope.launch {
                    try {
                        result.success(dataClient.dataItems.await().map { it.toRawMap() })
                    } catch (e: Exception) {
                        handleFlutterError(result, "Unable to find data item")
                    }
                }
            }
            "syncData" -> {
                try {
                    val arguments = call.arguments as HashMap<*, *>
                    val path = arguments["path"] as String
                    val isUrgent = arguments["isUrgent"] as Boolean
                    val rawMapData = arguments["rawMapData"] as HashMap<*, *>
                    val putDataRequest: PutDataRequest = PutDataMapRequest.create(path).run {
                        if (isUrgent) {
                            setUrgent()
                        }
                        dataMap.putAll(rawMapData.toDataMap())
                        asPutDataRequest()
                    }

                    scope.launch {
                        try {
                            val dataItem = dataClient.putDataItem(putDataRequest).await()
                            result.success(dataItem.toRawMap())
                        } catch (e: Exception) {
                            handleFlutterError(result, e.toString())
                        }
                    }
                } catch (e: Exception) {
                    handleFlutterError(result, "No data found")
                }
            }
            "deleteDataItems" -> {
                val arguments = call.arguments as HashMap<*, *>
                val path = arguments["path"] as String
                val filterType = arguments["filterType"] as Int
                scope.launch {
                    try {
                        result.success(
                            dataClient.deleteDataItems(Uri.parse(path), filterType).await()
                        )
                    } catch (e: Exception) {
                        handleFlutterError(result, "Unable to delete data items on $path")
                    }
                }

            }
            "getDataItems" -> {
                val arguments = call.arguments as HashMap<*, *>
                val path = arguments["path"] as String
                val filterType = arguments["filterType"] as Int
                Log.d("AndroidOS#GetItemsPath", path)
                scope.launch {
                    try {
                        val buffer = dataClient.getDataItems(Uri.parse(path), filterType).await()
                        result.success(
                            buffer.map {
                                it.toRawMap()
                            }
                        )
                        buffer.release()
                    } catch (e: Exception) {
                        handleFlutterError(result, "Unable to retrieve items on $path")
                    }
                }
            }
            "addDataListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                val filterType = arguments["filterType"] as Int?
                if (name != null) {
                    addNewDataListener(result, name, null)
                } else if (path != null) {
                    addNewDataListener(result, path, filterType)
                }
            }
            "removeDataListener" -> {
                val arguments = call.arguments as Map<*, *>
                val name = arguments["name"] as String?
                val path = arguments["path"] as String?
                if (name != null || path != null) {
                    removeDataListener(result, (name ?: path)!!)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun addNewCapabilityListener(result: Result, key: String, filterType: Int?) {
        scope.launch {
            try {
                capabilityListeners[key]?.let {
                    capabilityClient.removeListener(it, key).await() || capabilityClient.removeListener(it).await()
                }
                val newListener: CapabilityClient.OnCapabilityChangedListener =
                    CapabilityClient.OnCapabilityChangedListener {
                        callbackChannel.invokeMethod(
                            "onCapabilityChanged",
                            mapOf(
                                "key" to key,
                                "data" to it.toRawMap()
                            )
                        )
                    }
                capabilityListeners[key] = newListener
                if (filterType != null) {
                    capabilityClient.addListener(
                        capabilityListeners[key]!!,
                        Uri.parse(key),
                        filterType
                    ).await()
                } else {
                    capabilityClient.addListener(capabilityListeners[key]!!, key).await()
                }

                result.success(null)
            } catch (e: Exception) {
                handleFlutterError(
                    result,
                    "Unable to listen to capability changed, please try again"
                )
            }

        }
    }

    private fun removeCapabilityListener(result: Result, key: String) {
        capabilityListeners[key]?.let {
            scope.launch {
                try {
                    result.success(
                        capabilityClient.removeListener(it)
                            .await() || capabilityClient.removeListener(it, key).await()
                    )
                } catch (e: Exception) {
                    result.success(false)

                }
            }
            return
        }
        result.success(false)
    }

    private fun addNewMessageListener(result: Result, key: String, filterType: Int?) {
        scope.launch {
            try {
                messageListeners[key]?.let {
                    messageClient.removeListener(it).await()
                }
                val newListener: MessageClient.OnMessageReceivedListener =
                    MessageClient.OnMessageReceivedListener {
                        callbackChannel.invokeMethod(
                            "onMessageReceived",
                            mapOf(
                                "key" to key,
                                "data" to it.toRawData()
                            )
                        )
                    }
                messageListeners[key] = newListener
                if (filterType == null) {
                    messageClient.addListener(messageListeners[key]!!).await()
                } else {
                    messageClient.addListener(messageListeners[key]!!, Uri.parse(key), filterType)
                        .await()
                }
                result.success(null)
            } catch (e: Exception) {
                handleFlutterError(
                    result,
                    "Unable to listen to capability changed, please try again"
                )
            }

        }
    }

    private fun removeMessageListener(result: Result, key: String) {
        messageListeners[key]?.let {
            scope.launch {
                try {
                    result.success(
                        messageClient.removeListener(it)
                            .await()
                    )
                } catch (e: Exception) {
                    result.success(false)

                }
            }
            return
        }
        result.success(false)
    }

    private fun addNewDataListener(result: Result, key: String, filterType: Int?) {
        scope.launch {
            try {
                dataChangeListeners[key]?.let {
                    dataClient.removeListener(it).await()
                }
                val newListener: DataClient.OnDataChangedListener =
                    DataClient.OnDataChangedListener {
                        callbackChannel.invokeMethod(
                            "onDataChanged",
                            mapOf(
                                "key" to key,
                                "data" to it.toRawMaps()
                            )
                        )
                    }
                dataChangeListeners[key] = newListener
                if (filterType == null) {
                    dataClient.addListener(dataChangeListeners[key]!!).await()
                } else {
                    dataClient.addListener(dataChangeListeners[key]!!, Uri.parse(key), filterType)
                        .await()
                }
                result.success(null)
            } catch (e: Exception) {
                handleFlutterError(
                    result,
                    "Unable to listen to capability changed, please try again"
                )
            }
        }
    }

    private fun removeDataListener(result: Result, key: String) {
        dataChangeListeners[key]?.let {
            scope.launch {
                try {
                    result.success(
                        dataClient.removeListener(it)
                            .await()
                    )
                } catch (e: Exception) {
                    result.success(false)

                }
            }
            return
        }
        result.success(false)
    }


    private fun handleFlutterError(result: Result, message: String) {
        result.error("500", message, null)
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

fun MessageEvent.toRawData(): Map<String, Any> {
    return mapOf(
        "data" to data,
        "path" to path,
        "requestId" to this.requestId,
        "sourceNodeId" to this.sourceNodeId
    )
}

fun Node.toRawMap(): Map<String, Any> {
    return mapOf(
        "name" to displayName,
        "isNearby" to isNearby,
        "id" to id
    )
}

fun CapabilityInfo.toRawMap(): Map<String, Any> {
    return mapOf(
        "name" to this.name,
        "associatedNodes" to this.nodes.map { it.toRawMap() }
    )
}

fun DataItem.toRawMap(): Map<String, Any> {
    val mapDataItem = DataMapItem.fromDataItem(this)
    return mapOf(
        "uri" to uri.toString(),

        ) + (if (data != null) mapOf("data" to data!!) + mapDataItem.toRawMap() else mapOf())
}

fun DataMapItem.toRawMap(): Map<String, Any> {
    return mapOf(
        "uri" to uri.toString(),
        "map" to fromDataMap(dataMap)
    )
}

fun HashMap<*, *>.toDataMap(): DataMap {
    val dataMap = DataMap()
    for (entry in entries) {
        when (entry.value) {
            is String -> {
                dataMap.putString(entry.key.toString(), entry.value as String)
                break
            }
            is Boolean -> {
                dataMap.putBoolean(entry.key.toString(), entry.value as Boolean)
                break
            }
            is Int -> {
                dataMap.putInt(entry.key.toString(), entry.value as Int)
                break
            }
            is Double -> {
                dataMap.putDouble(entry.key.toString(), entry.value as Double)
                break
            }
            is Long -> {
                dataMap.putLong(entry.key.toString(), entry.value as Long)
                break
            }
            is ByteArray -> {
                dataMap.putByteArray(entry.key.toString(), entry.value as ByteArray)
                break
            }
            is FloatArray -> {
                dataMap.putFloatArray(entry.key.toString(), entry.value as FloatArray)
                break
            }
            is LongArray -> {
                dataMap.putLongArray(entry.key.toString(), entry.value as LongArray)
                break
            }
            is HashMap<*, *> -> {
                dataMap.putDataMap(entry.key.toString(), (entry.value as HashMap<*, *>).toDataMap())
                break
            }
            is List<*> -> {
                if ((entry.value as List<*>).isEmpty()) break
                @Suppress("UNCHECKED_CAST")
                if ((entry.value as List<*>).all { it is String }) {
                    dataMap.putStringArray(
                        entry.key.toString(),
                        (entry.value as List<String>).toTypedArray()
                    )
                } else if ((entry.value as List<*>).all { it is HashMap<*, *> }) {
                    dataMap.putDataMapArrayList(
                        entry.key.toString(),
                        ArrayList((entry.value as List<HashMap<*, *>>).map { it.toDataMap() })
                    )
                } else if ((entry.value as List<*>).all { it is Int }) {
                    dataMap.putIntegerArrayList(
                        entry.key.toString(),
                        ArrayList(entry.value as List<Int>)
                    )
                }
                break
            }
        }
    }
    return dataMap
}

fun fromDataMap(dataMap: DataMap): HashMap<String, *> {
    val hashMap: HashMap<String, Any> = HashMap()
    for (key in dataMap.keySet()) {
        val data = dataMap.get<Any>(key)
        data?.let {
            hashMap[key] = data
        }
    }
    return hashMap
}

fun DataEventBuffer.toRawMaps(): List<Map<String, Any>> {
    return map {
        mapOf(
            "type" to it.type,
            "dataItem" to it.dataItem.toRawMap(),
            "isDataValid" to it.isDataValid
        )

    }
}

