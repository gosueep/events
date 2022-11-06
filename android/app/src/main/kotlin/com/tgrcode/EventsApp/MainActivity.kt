package com.tgrcode.EventsApp

import android.content.ContentValues
import android.graphics.SurfaceTexture 
import android.hardware.SensorManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.OrientationEventListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

import javax.microedition.khronos.egl.EGL10

class MainActivity : FlutterActivity() {
    private lateinit var renderer: FlutterRenderer
    private var textures = HashMap<Long, SurfaceTexture>()
    private var renders = HashMap<Long, Renderer>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        renderer = flutterEngine.getRenderer()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_native_bridge")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "addDownload" -> {
                            addItem(
                                    call.argument("path")!!,
                                    call.argument("name")!!,
                                    call.argument("mime")!!
                            )
                            result.success(null)
                        }
                        "createTexture" -> {
                            result.success(
                                getFlutterTexture()
                            )
                        }
                        "disposeTexture" -> {
                            //result.success(getFlutterTexture(
                            //    call.argument("textureID")!!
                            //))
                        }
                        "sendRecent" -> {
                            result.success(updateEvents(
                                call.argument("events")!!,
                                call.argument("people")!!
                            ))
                        }
                        "sendCameraPosition" -> {
                            result.success(updateCameraPosition(
                                call.argument("latitude")!!,
                                call.argument("longitude")!!,
                                call.argument("zoom")!!,
								call.argument("tilt")!!
                            ))
                        }
                    }
                }
    }

	private fun getFlutterTexture(): Long {
        // https://github.com/mogol/opengl_texture_widget_example
        var entry = renderer.createSurfaceTexture();
        var surfaceTexture = entry.surfaceTexture();

        //int width = arguments.get("width").intValue();
        //int height = arguments.get("height").intValue();

        var width = 512;
        var height = 1000;
        surfaceTexture.setDefaultBufferSize(width, height);
        var render = Renderer(surfaceTexture, width, height);

        textures.put(entry.id(), surfaceTexture);
        renders.put(entry.id(), render);

        return entry.id();
    }

    private fun updateEvents(events: ArrayList<HashMap<*,*>>, people: ArrayList<HashMap<*,*>>): Boolean {
        for (render in renders) {
            render.component2().setEventInfo(
                events.map(fun(event: HashMap<*,*>): Renderer.EventInfo {
                    var info: Renderer.EventInfo = Renderer.EventInfo()
                    info.event = event["event"] as Int
                    info.name = event["name"] as String
                    info.description = event["description"] as String
                    info.numberProximity = event["numberProximity"] as Int
                    info.latitude  = event["latitude"] as Double
                    info.longitude  = event["longitude"] as Double
                    return info
                }),
                people.map(fun(event: HashMap<*,*>): Renderer.PersonInfo {
                    var info: Renderer.PersonInfo = Renderer.PersonInfo()
                    info.name = event["name"] as String
                    info.latitude  = event["latitude"] as Double
                    info.longitude  = event["longitude"] as Double
                    return info
                })
            )
        }
		return true
    }

    private fun updateCameraPosition(latitude: Double, longitude: Double, zoom: Double, tilt: Double): Boolean {
        for (render in renders) {
            render.component2().setCameraPosition(latitude, longitude, zoom, tilt)
        }
		return true
    }

    private fun addItem(path: String, name: String, mimeType: String) {
        val collection =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI
                }

        val values =
                ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(
                                MediaStore.DownloadColumns.RELATIVE_PATH,
                                Environment.DIRECTORY_DOWNLOADS
                        )
                        put(MediaStore.Downloads.IS_PENDING, 1)
                    }
                }

        val resolver = applicationContext.contentResolver
        val uri = resolver.insert(collection, values)!!

        try {
            resolver.openOutputStream(uri).use { os ->
                File(path).inputStream().use { it.copyTo(os!!) }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
        } catch (ex: IOException) {
            if (ex.message != null) {
                Log.e("MediaStore", ex.message.toString())
            } else {
                Log.e("MediaStore", "error")
            }
        }
    }
}
