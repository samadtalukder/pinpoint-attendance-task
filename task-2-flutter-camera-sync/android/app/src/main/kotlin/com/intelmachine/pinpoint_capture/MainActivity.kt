package com.intelmachine.pinpoint_capture

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.hypot

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == METHOD) {
                    result.success(equivalentFocalLengths())
                } else {
                    result.notImplemented()
                }
            }
    }

    /** 35mm-equivalent focal length per camera id; cameras without data are skipped. */
    private fun equivalentFocalLengths(): Map<String, Double> {
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val lengths = mutableMapOf<String, Double>()
        for (id in manager.cameraIdList) {
            try {
                val characteristics = manager.getCameraCharacteristics(id)
                val focal = characteristics
                    .get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                    ?.firstOrNull() ?: continue
                val size = characteristics
                    .get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE) ?: continue
                val diagonal = hypot(size.width.toDouble(), size.height.toDouble())
                if (diagonal > 0) {
                    lengths[id] = focal * FULL_FRAME_DIAGONAL_MM / diagonal
                }
            } catch (_: Exception) {
                // A camera that cannot be queried is simply not classified.
            }
        }
        return lengths
    }

    private companion object {
        const val CHANNEL = "pinpoint_capture/lens_info"
        const val METHOD = "equivalentFocalLengths"
        const val FULL_FRAME_DIAGONAL_MM = 43.27
    }
}
