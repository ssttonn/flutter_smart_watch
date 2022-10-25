package com.sstonn.flutter_smart_watch_android

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.wearable.*
import com.google.android.gms.wearable.CapabilityClient.FILTER_ALL

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
    private lateinit var context: Context
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
                    capabilityClient.addListener({ capabilityInfo ->
                        Log.d("App: ",capabilityInfo.nodes.toString())
                        callbackChannel.invokeMethod(
                            "connectedNodesChanged",
                            capabilityInfo.nodes.map { node -> node.toRawMap() })
                    }, "flutter_smart_watch_connected_nodes")
                }
                result.success(null)
            }
            "getConnectedNodes" -> {
                scope.launch {
                    var nodes = capabilityClient.getCapability("flutter_smart_watch_connected_nodes",
                        FILTER_ALL).await().nodes
                    Log.d("App: ", nodes.toString())
                    result.success(nodes.map { it.toRawMap() })
                }
            }
            "addNewCapacity" -> {
                var newCapacityName: String? =
                    (call.arguments as Map<String, Any>)["capacityName"] as String?
                newCapacityName?.let {
                    scope.launch {
                        capabilityClient.addLocalCapability(newCapacityName)
                        result.success(null)
                    }
                    return
                }
                result.success(null)
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null;
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null;
    }
}

fun Node.toRawMap(): Map<String, Any> {
    return mapOf(
        "name" to displayName,
        "isNearby" to isNearby,
        "id" to id
    )
}
