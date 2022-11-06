package com.tgrcode.EventsApp

import android.graphics.SurfaceTexture
import android.opengl.GLUtils
import android.util.Log
import java.util.concurrent.atomic.AtomicInteger
import javax.microedition.khronos.egl.EGL10
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.egl.EGLContext
import javax.microedition.khronos.egl.EGLDisplay
import javax.microedition.khronos.egl.EGLSurface

import java.util.concurrent.locks.Lock
import java.util.concurrent.locks.ReentrantLock

class Renderer(texture: SurfaceTexture, width: Int, height: Int) : Runnable {
    companion object {
        private const val LOG_TAG = "Renderer"

        init {
            System.loadLibrary("events_android_native")
        }

        external fun createRenderer(width: Int, height: Int)
        external fun renderFrame(): Boolean
        external fun closeRenderer()

		external fun clearExistingEvents()
		external fun passEvent(event: Int, name: String, description: String, numberProximity: Int, latitude: Double, longitude: Double)
		external fun passPerson(name: String, latitude: Double, longitude: Double)

		external fun sendCameraPosition(latitude: Double, longitude: Double, zoom: Double, tilt: Double)
    }

	public class EventInfo constructor() {
		public var event: Int = 0
		public var name: String = ""
		public var description: String = ""
		public var numberProximity: Int = 0
		public var latitude: Double = 0.0
		public var longitude: Double = 0.0
	}

	public class PersonInfo constructor() {
		public var name: String = ""
		public var latitude: Double = 0.0
		public var longitude: Double = 0.0
	}

    protected val texture: SurfaceTexture
    private lateinit var egl: EGL10
    private lateinit var eglDisplay: EGLDisplay
    private lateinit var eglContext: EGLContext
    private lateinit var eglSurface: EGLSurface
    private var running: Boolean

	protected val width: Int
	protected val height: Int

	private val eventLock: Lock = ReentrantLock()
	private var events: List<EventInfo> = arrayOf<EventInfo>().asList()
	private var people: List<PersonInfo> = arrayOf<PersonInfo>().asList()
	private var hasRecievedEventUpdate: Boolean = false

	private val cameraLock: Lock = ReentrantLock()
	private var latitudeCamera: Double = 0.0
	private var longitudeCamera: Double = 0.0
	private var zoomCamera: Double = 1.0
	private var tiltCamera: Double = 0.0
	private var hasRecievedCameraUpdate: Boolean = false

    override fun run() {
        initGL()

        // TODO on create
		Log.d(LOG_TAG, "Width " + width + " height " + height)
        createRenderer(width, height)

        Log.d(LOG_TAG, "OpenGL init OK.")
        while (running) {
            val loopStart: Long = System.currentTimeMillis()

			eventLock.lock()
			if (hasRecievedEventUpdate) {
				clearExistingEvents()
				for (event in events) {
					passEvent(event.event, event.name, event.description, event.numberProximity, event.latitude, event.longitude)
				}
				for (person in people) {
                    passPerson(person.name, person.latitude, person.longitude)
				}

				hasRecievedEventUpdate = false
			}
			eventLock.unlock()

			cameraLock.lock()
			if (hasRecievedCameraUpdate) {
				sendCameraPosition(latitudeCamera, longitudeCamera, zoomCamera, tiltCamera)
				hasRecievedCameraUpdate = false
			}
			cameraLock.unlock()

            if (renderFrame()) {
                if (!egl.eglSwapBuffers(eglDisplay, eglSurface)) {
                    Log.d(LOG_TAG, GLUtils.getEGLErrorString(egl.eglGetError()))
                }
            }
            val waitDelta: Long = 16 - (System.currentTimeMillis() - loopStart)
            if (waitDelta > 0) {
                try {
                    Thread.sleep(waitDelta)
                } catch (e: InterruptedException) {
                }
            }
        }

        // TODO on deconstruct
        //worker.onDispose()
		closeRenderer()

        deinitGL()
    }

	@Synchronized
    public fun setEventInfo(events: List<EventInfo>, people: List<PersonInfo>) {
		eventLock.lock()
        this.events = events
		this.people = people
		hasRecievedEventUpdate = true
		eventLock.unlock()
    }

	@Synchronized
	public fun setCameraPosition(latitude: Double, longitude: Double, zoom: Double, tilt: Double) {
		cameraLock.lock()
		this.latitudeCamera = latitude
		this.longitudeCamera = longitude
		this.zoomCamera = zoom
		this.tiltCamera = tilt
		this.hasRecievedCameraUpdate = true
		cameraLock.unlock()
	}

    private fun initGL() {
        egl = EGLContext.getEGL() as EGL10
        eglDisplay = egl.eglGetDisplay(EGL10.EGL_DEFAULT_DISPLAY)
        if (eglDisplay === EGL10.EGL_NO_DISPLAY) {
            throw RuntimeException("eglGetDisplay failed")
        }
        val version = IntArray(2)
        if (!egl.eglInitialize(eglDisplay, version)) {
            throw RuntimeException("eglInitialize failed")
        }
        val eglConfig: EGLConfig = chooseEglConfig()
        eglContext = createContext(egl, eglDisplay, eglConfig)
        eglSurface = egl.eglCreateWindowSurface(eglDisplay, eglConfig, texture, null)
        if (eglSurface == null || eglSurface === EGL10.EGL_NO_SURFACE) {
            throw RuntimeException("GL Error: " + GLUtils.getEGLErrorString(egl.eglGetError()))
        }
        if (!egl.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)) {
            throw RuntimeException(
                "GL make current error: " + GLUtils.getEGLErrorString(egl.eglGetError())
            )
        }
    }

    private fun deinitGL() {
        egl.eglMakeCurrent(
            eglDisplay, EGL10.EGL_NO_SURFACE, EGL10.EGL_NO_SURFACE, EGL10.EGL_NO_CONTEXT
        )
        egl.eglDestroySurface(eglDisplay, eglSurface)
        egl.eglDestroyContext(eglDisplay, eglContext)
        egl.eglTerminate(eglDisplay)
        Log.d(LOG_TAG, "OpenGL deinit OK.")
    }

    private fun createContext(
        egl: EGL10,
        eglDisplay: EGLDisplay,
        eglConfig: EGLConfig
    ): EGLContext {
        val EGL_CONTEXT_CLIENT_VERSION = 0x3098
        val attribList = intArrayOf(EGL_CONTEXT_CLIENT_VERSION, 2, EGL10.EGL_NONE)
        return egl.eglCreateContext(eglDisplay, eglConfig, EGL10.EGL_NO_CONTEXT, attribList)
    }

    private fun chooseEglConfig(): EGLConfig {
        val configsCount = IntArray(1)
        val configs: Array<EGLConfig?> = arrayOfNulls<EGLConfig>(1)
        val configSpec = config
        if (!egl.eglChooseConfig(eglDisplay, configSpec, configs, 1, configsCount)) {
            throw IllegalArgumentException(
                "Failed to choose config: " + GLUtils.getEGLErrorString(egl.eglGetError())
            )
        }/* else if (configsCount[0] > 0) {
            return configs[0]
        }*/

        return configs[0]!!
    }

    private val config: IntArray
        private get() = intArrayOf(
            EGL10.EGL_RENDERABLE_TYPE, 4,
            EGL10.EGL_RED_SIZE, 8,
            EGL10.EGL_GREEN_SIZE, 8,
            EGL10.EGL_BLUE_SIZE, 8,
            EGL10.EGL_ALPHA_SIZE, 8,
            EGL10.EGL_DEPTH_SIZE, 16,
            EGL10.EGL_STENCIL_SIZE, 0,
            EGL10.EGL_SAMPLE_BUFFERS, 1,
            EGL10.EGL_SAMPLES, 4,
            EGL10.EGL_NONE
        )

    //@Override
    //@Throws(Throwable::class)
    //protected fun finalize() {
    //    super.finalize()
    //    running = false
    //}

    fun onDispose() {
        running = false
    }

    init {
        this.texture = texture
        this.width = width
        this.height = height
        running = true
        val thread = Thread(this)
        thread.start()
    }
}