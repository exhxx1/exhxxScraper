package com.crosshair.app

import android.app.Service
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "overlay_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "startOverlay" -> {
                    val type = call.argument<String>("type") ?: "sniper"
                    val color = call.argument<Int>("color") ?: Color.RED
                    val size = call.argument<Double>("size")?.toFloat() ?: 60f
                    val intent = Intent(this, OverlayService::class.java).apply {
                        putExtra("type", type)
                        putExtra("color", color)
                        putExtra("size", size)
                    }
                    startService(intent)
                    result.success(null)
                }
                "stopOverlay" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: CrosshairView? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val type = intent?.getStringExtra("type") ?: "sniper"
        val color = intent?.getIntExtra("color", Color.RED) ?: Color.RED
        val size = intent?.getFloatExtra("size", 60f) ?: 60f

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        overlayView = CrosshairView(this, type, color, size)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        windowManager?.addView(overlayView, params)
        return START_STICKY
    }

    override fun onDestroy() {
        overlayView?.let { windowManager?.removeView(it) }
        super.onDestroy()
    }
}

class CrosshairView(
    context: android.content.Context,
    private val type: String,
    private val color: Int,
    private val size: Float
) : View(context) {

    private val paint = Paint().apply {
        this.color = color
        strokeWidth = 3f
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        isAntiAlias = true
    }

    private val fillPaint = Paint().apply {
        this.color = color
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val s = size * 0.5f

        when (type) {
            "sniper" -> {
                val g = s * 0.2f
                canvas.drawLine(cx - s, cy, cx - g, cy, paint)
                canvas.drawLine(cx + g, cy, cx + s, cy, paint)
                canvas.drawLine(cx, cy - s, cx, cy - g, paint)
                canvas.drawLine(cx, cy + g, cx, cy + s, paint)
                canvas.drawCircle(cx, cy, s * 0.8f, paint)
                canvas.drawCircle(cx, cy, 4f, fillPaint)
            }
            "circle" -> {
                canvas.drawCircle(cx, cy, s * 0.8f, paint)
                canvas.drawLine(cx - s, cy, cx + s, cy, paint)
                canvas.drawLine(cx, cy - s, cx, cy + s, paint)
                canvas.drawCircle(cx, cy, 4f, fillPaint)
            }
            "cod" -> {
                paint.strokeWidth = 4f
                val g = s * 0.18f
                canvas.drawLine(cx - s, cy, cx - g, cy, paint)
                canvas.drawLine(cx + g, cy, cx + s, cy, paint)
                canvas.drawLine(cx, cy - s * 0.7f, cx, cy - g, paint)
                canvas.drawLine(cx, cy + g, cx, cy + s * 0.7f, paint)
                canvas.drawCircle(cx, cy, 3f, fillPaint)
            }
            "dot" -> {
                canvas.drawCircle(cx, cy, 5f, fillPaint)
                val g = s * 0.25f
                canvas.drawLine(cx - s, cy, cx - g, cy, paint)
                canvas.drawLine(cx + g, cy, cx + s, cy, paint)
                canvas.drawLine(cx, cy - s, cx, cy - g, paint)
                canvas.drawLine(cx, cy + g, cx, cy + s, paint)
            }
            "diamond" -> {
                val path = android.graphics.Path().apply {
                    moveTo(cx, cy - s)
                    lineTo(cx + s * 0.6f, cy)
                    lineTo(cx, cy + s)
                    lineTo(cx - s * 0.6f, cy)
                    close()
                }
                canvas.drawPath(path, paint)
                canvas.drawCircle(cx, cy, 4f, fillPaint)
            }
            else -> {
                canvas.drawLine(cx - s, cy, cx + s, cy, paint)
                canvas.drawLine(cx, cy - s, cx, cy + s, paint)
                canvas.drawCircle(cx, cy, 4f, fillPaint)
            }
        }
    }
}
