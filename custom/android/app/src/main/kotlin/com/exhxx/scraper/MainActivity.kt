package com.exhxx.scraper

import android.content.Intent
import android.graphics.*
import android.net.Uri
import android.os.*
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "overlay_channel"
    override fun configureFlutterEngine(fe: FlutterEngine) {
        super.configureFlutterEngine(fe)
        MethodChannel(fe.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this))
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "startOverlay" -> {
                    startService(Intent(this, OverlayService::class.java).apply {
                        putExtra("type", call.argument<String>("type"))
                        putExtra("color", call.argument<Int>("color"))
                        putExtra("size", call.argument<Double>("size")?.toFloat())
                        putExtra("opacity", call.argument<Double>("opacity")?.toFloat())
                    })
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

class OverlayService : android.app.Service() {
    private var wm: WindowManager? = null
    private var view: CrosshairView? = null
    override fun onBind(i: Intent?) = null
    override fun onStartCommand(intent: Intent?, f: Int, id: Int): Int {
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        view = CrosshairView(this,
            intent?.getStringExtra("type") ?: "sniper",
            intent?.getIntExtra("color", Color.RED) ?: Color.RED,
            intent?.getFloatExtra("size", 60f) ?: 60f,
            intent?.getFloatExtra("opacity", 1f) ?: 1f
        )
        wm?.addView(view, WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ))
        return START_STICKY
    }
    override fun onDestroy() { view?.let { wm?.removeView(it) }; super.onDestroy() }
}

class CrosshairView(ctx: android.content.Context, val type: String,
    val color: Int, val size: Float, val opacity: Float) : View(ctx) {
    private val p = Paint().apply {
        this.color = color; strokeWidth = 3f
        style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND
        isAntiAlias = true; alpha = (opacity * 255).toInt()
    }
    private val f = Paint().apply {
        this.color = color; style = Paint.Style.FILL
        isAntiAlias = true; alpha = (opacity * 255).toInt()
    }
    override fun onDraw(canvas: Canvas) {
        val cx = width/2f; val cy = height/2f; val s = size*0.5f
        when(type) {
            "sniper" -> {
                val g=s*0.2f
                canvas.drawLine(cx-s,cy,cx-g,cy,p); canvas.drawLine(cx+g,cy,cx+s,cy,p)
                canvas.drawLine(cx,cy-s,cx,cy-g,p); canvas.drawLine(cx,cy+g,cx,cy+s,p)
                canvas.drawCircle(cx,cy,s*0.8f,p); canvas.drawCircle(cx,cy,4f,f)
            }
            "circle" -> {
                canvas.drawCircle(cx,cy,s*0.8f,p)
                canvas.drawLine(cx-s,cy,cx+s,cy,p); canvas.drawLine(cx,cy-s,cx,cy+s,p)
                canvas.drawCircle(cx,cy,4f,f)
            }
            "cod" -> {
                p.strokeWidth=4f; val g=s*0.18f
                canvas.drawLine(cx-s,cy,cx-g,cy,p); canvas.drawLine(cx+g,cy,cx+s,cy,p)
                canvas.drawLine(cx,cy-s*0.7f,cx,cy-g,p); canvas.drawLine(cx,cy+g,cx,cy+s*0.7f,p)
                canvas.drawCircle(cx,cy,3f,f)
            }
            "dot" -> {
                canvas.drawCircle(cx,cy,5f,f); val g=s*0.25f
                canvas.drawLine(cx-s,cy,cx-g,cy,p); canvas.drawLine(cx+g,cy,cx+s,cy,p)
                canvas.drawLine(cx,cy-s,cx,cy-g,p); canvas.drawLine(cx,cy+g,cx,cy+s,p)
            }
            "diamond" -> {
                val path=Path(); path.moveTo(cx,cy-s); path.lineTo(cx+s*0.6f,cy)
                path.lineTo(cx,cy+s); path.lineTo(cx-s*0.6f,cy); path.close()
                canvas.drawPath(path,p); canvas.drawCircle(cx,cy,4f,f)
            }
            else -> {
                canvas.drawLine(cx-s,cy,cx+s,cy,p)
                canvas.drawLine(cx,cy-s,cx,cy+s,p)
                canvas.drawCircle(cx,cy,4f,f)
            }
        }
    }
}
