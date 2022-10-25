package com.sstonn.flutter_smart_watch_android

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
import java.lang.Exception

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
                    try{
                        val nodes = nodeClient.connectedNodes.await()
                        result.success(nodes.map { it.toRawMap() })
                    }catch (_: Exception){
                        handleFlutterError(result, "Can't retrieve connected devices, please try again")
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
                    }catch (_: Exception){
                        handleFlutterError(result, "Can't retrieve local device info, please try again")
                    }
                }
            }
            "findDeviceIdFromBluetoothAddress" -> {
                val macAddress: String? = call.arguments as String?
                macAddress?.let {
                    scope.launch {
                        try{
                            result.success(nodeClient.getNodeId(it).await())
                        }catch (_:Exception){
                            result.success(null)
                        }
                    }
                    return
                }
                result.success(null)
            }
            "registerNewCapability" -> {
                val capabilityName: String? =
                    call.arguments as String?
                capabilityName?.let {
                    scope.launch {
                        try{
                            capabilityClient.addLocalCapability(capabilityName)
                            result.success(null)
                        }catch (e: Exception){
                            handleFlutterError(result, "Unable to register new capability, please try again")
                        }
                    }
                    return
                }
                result.success(null)
            }
            "removeExistingCapability"->{
                val capabilityName: String? =
                    call.arguments as String?
                capabilityName?.let {
                    scope.launch {
                        try{
                            capabilityClient.removeLocalCapability(capabilityName)
                            result.success(null)
                        }catch (e: Exception){
                            handleFlutterError(result, "Unable to remove capability, please try again")
                        }
                    }
                    return
                }
                result.success(null)
            }
        }
    }

    private fun handleFlutterError(result: Result, message: String){
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

fun Node.toRawMap(): Map<String, Any> {
    return mapOf(
        "name" to displayName,
        "isNearby" to isNearby,
        "id" to id
    )
}
