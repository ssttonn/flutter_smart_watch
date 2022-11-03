package sstonn.example.flutter_smart_watch_harmony_os

import android.util.Log
import androidx.annotation.NonNull
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.Permission

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

/** FlutterSmartWatchHarmonyOsPlugin */
class FlutterSmartWatchHarmonyOsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var scope: CoroutineScope = CoroutineScope(Dispatchers.IO)

    //Activity and context references
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "sstonn/flutter_smart_watch_harmony_os")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                HiWear.getAuthClient(activityBinding!!.activity).requestPermission(object : AuthCallback{
                  override fun onOk(p0: Array<out Permission>?) {
                    Log.d("WearEngine#OK","OKAY now")
                  }

                  override fun onCancel() {
                    Log.d("WearEngine#Cancel","Cancel")
                  }

                }, Permission.DEVICE_MANAGER)
            }
        }
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
