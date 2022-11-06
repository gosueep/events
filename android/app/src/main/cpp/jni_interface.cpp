#include "jni_interface.hpp"

#define SK_GL
#define SK_RELEASE

#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <android/surface_texture_jni.h>
#include <codec/SkCodec.h>
#include <core/SkCanvas.h>
#include <core/SkFont.h>
#include <core/SkGraphics.h>
#include <core/SkPaint.h>
#include <core/SkSurface.h>
#include <gpu/GrBackendSurface.h>
#include <gpu/GrDirectContext.h>
#include <gpu/gl/GrGLInterface.h>
#include <jni.h>
#include <thread>
#include <vector>

extern "C" {
namespace {
	// maintain a reference to the JVM
	static JavaVM* g_vm = nullptr;
}

jint JNI_OnLoad(JavaVM* vm, void*) {
	g_vm = vm;
	return JNI_VERSION_1_6;
}

sk_sp<SkSurface> surface;
SkCanvas* canvas { nullptr };
SkPaint fill_paint;
SkPaint stroke_paint;
SkFont current_font;

struct Event {
	int event;
	std::string name;
	std::string description;
	int numberProximity;
	double latitude;
	double longitude;
};

struct Person {
	std::string name;
	double latitude;
	double longitude;
};

std::vector<Event> events;
std::vector<Person> people;
double latitudeCamera  = 0.0;
double longitudeCamera = 0.0;
double zoomCamera      = 1.0;
double tiltCamera      = 0.0;
double width           = 0.0;
double height          = 0.0;

JNI_METHOD(void, createRenderer)(JNIEnv* env, jclass, jint w, jint h) {
	width  = w;
	height = h;

	auto gl_interface = GrGLMakeNativeInterface();
	sk_sp<GrDirectContext> gr_context(GrDirectContext::MakeGL(gl_interface));
	SkASSERT(gr_context);

	// Wrap FBO so skia can use it
	GrGLint buffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &buffer);

	GrGLFramebufferInfo buffer_info;
	buffer_info.fFBOID  = (GrGLuint)buffer;
	buffer_info.fFormat = GL_RGBA8;

	GrBackendRenderTarget target(w, h, 0, 0, buffer_info);

	SkSurfaceProps props;
	surface = SkSurface::MakeFromBackendRenderTarget(
		gr_context.get(), target, kBottomLeft_GrSurfaceOrigin, kRGBA_8888_SkColorType, nullptr, &props);
	canvas = surface->getCanvas();

	fill_paint.setStyle(SkPaint::Style::kFill_Style);
	stroke_paint.setStyle(SkPaint::Style::kStroke_Style);
	stroke_paint.setColor(SkColorSetARGB(255, 255, 255, 255));
	stroke_paint.setStrokeWidth(2);
	current_font.setSize(20);
}

void drawCircle(int center_x, int center_y, int radius_x, int radius_y) {
	auto bounds = SkRect::MakeLTRB(center_x - radius_x, center_y - radius_y, center_x + radius_x, center_y + radius_y);
	canvas->drawArc(bounds, 0, 360, false, fill_paint);
	canvas->drawArc(bounds, 0, 360, false, stroke_paint);
	// canvas->drawArc(bounds, 0, 360, false, stroke_paint);
}

double pixelX = 0.0;
double pixelY = 0.0;
void getPixelFromLatLong(double lat, double lon) {
	auto constexpr PI = 3.14159;
	auto offset       = 256 * std::pow(2, zoomCamera);
	pixelX            = std::round(offset + (offset * lon / 180));
	pixelY            = std::round(
        offset - offset / PI * std::log((1 + std::sin(lat * PI / 180)) / (1 - std::sin(lat * PI / 180))) / 2);
}

uint64_t frame = 0;
JNI_METHOD(jboolean, renderFrame)
(JNIEnv* env, jclass) {
	// drawCircle(200, 200, 20, 20);
	canvas->clear(SkColorSetARGB(0, 0, 0, 0));
	// drawCircle(250, 250, 50, 50);

	// for(int x = 0; x < 1500; x += 20) {
	//	for(int y = 0; y < 1500; y += 20) {
	//		drawCircle(x, y, 10, 10);
	//	}
	// }

	// double mapScale = 216.0 * std::pow(2.0, zoomCamera);

	fill_paint.setColor(SkColorSetARGB(255, 170, 74, 68));
	for(auto& person : people) {
		/*
		std::string latitudeCameraString = std::to_string(latitudeCamera);
		canvas->drawSimpleText(latitudeCameraString.c_str(), latitudeCameraString.size(), SkTextEncoding::kUTF8, 0, 50,
			current_font, fill_paint);
		std::string longitudeCameraString = std::to_string(longitudeCamera);
		canvas->drawSimpleText(longitudeCameraString.c_str(), longitudeCameraString.size(), SkTextEncoding::kUTF8, 0,
			100, current_font, fill_paint);

		std::string latitudePersonString = std::to_string(person.latitude);
		canvas->drawSimpleText(latitudePersonString.c_str(), latitudePersonString.size(), SkTextEncoding::kUTF8, 0, 150,
			current_font, fill_paint);
		std::string longitudePersonString = std::to_string(person.longitude);
		canvas->drawSimpleText(longitudePersonString.c_str(), longitudePersonString.size(), SkTextEncoding::kUTF8, 0,
			200, current_font, fill_paint);

		std::string zoomCameraString = std::to_string(zoomCamera);
		canvas->drawSimpleText(
			zoomCameraString.c_str(), zoomCameraString.size(), SkTextEncoding::kUTF8, 0, 250, current_font, fill_paint);

		std::string tiltCameraString = std::to_string(tiltCamera);
		canvas->drawSimpleText(
			tiltCameraString.c_str(), tiltCameraString.size(), SkTextEncoding::kUTF8, 0, 300, current_font, fill_paint);
			*/

		/*
				auto siny = std::sin(((person.latitude - latitudeCamera) * 3.14159) / 180);
				// siny = std::min(std::max(siny, -0.9999), 0.9999);
				auto x = 0.5 + (person.longitude - longitudeCamera) / 360;
				auto y = 0.5 - std::log((1 + siny) / (1 - siny)) / (4 * 3.14159);
				x *= mapScale;
				y *= -mapScale;

				std::string xString = std::to_string(x);
				canvas->drawSimpleText(
					xString.c_str(), xString.size(), SkTextEncoding::kUTF8, 0, 350, current_font, fill_paint);

				std::string yString = std::to_string(y);
				canvas->drawSimpleText(
					yString.c_str(), yString.size(), SkTextEncoding::kUTF8, 0, 400, current_font, fill_paint);

				drawCircle(width / 2 + x, height / 2 - y, 50, 50);
				*/

		getPixelFromLatLong(latitudeCamera, longitudeCamera);
		auto cameraX = pixelX;
		auto cameraY = pixelY;
		getPixelFromLatLong(person.latitude, person.longitude);
		drawCircle((pixelX - cameraX) * 2.0 / 3.0, (pixelY - cameraY) * 19.0 / 27.0, 8, 8);

		// drawCircle(height / 2 + person.longitude, width / 2 + person.latitude, 50, 50);
	}

	fill_paint.setColor(SkColorSetARGB(255, 0, 150, 255));
	for(auto& event : events) {
		getPixelFromLatLong(latitudeCamera, longitudeCamera);
		auto cameraX = pixelX;
		auto cameraY = pixelY;
		getPixelFromLatLong(event.latitude, event.longitude);
		auto x          = (pixelX - cameraX) * 2.0 / 3.0;
		auto y          = (pixelY - cameraY) * 19.0 / 27.0;
		auto text_width = current_font.measureText(event.name.c_str(), event.name.size(), SkTextEncoding::kUTF8);
		drawCircle(x, y, 12, 12);
		canvas->drawSimpleText(event.name.c_str(), event.name.size(), SkTextEncoding::kUTF8, x - text_width / 2, y - 14,
			current_font, fill_paint);
	}

	// std::string latitudeCameraString = std::to_string(latitudeCamera);
	// canvas->drawSimpleText(latitudeCameraString.c_str(), latitudeCameraString.size(), SkTextEncoding::kUTF8, 250,
	// 250, 	current_font, fill_paint);

	// canvas->clear(SkColorSetARGB(255, 0, 0, 255));

	canvas->flush();
	frame++;
	return (jboolean) true;
}

JNI_METHOD(void, closeRenderer)
(JNIEnv* env, jclass) {
	surface = NULL;
}

JNI_METHOD(void, clearExistingEvents)(JNIEnv* env, jclass) {
	events.clear();
	people.clear();
}

JNI_METHOD(void, passEvent)
(JNIEnv* env, jclass, jint event, jstring name, jstring description, jint numberProximity, jdouble latitude,
	jdouble longitude) {
	const char* name_ptr = env->GetStringUTFChars(name, NULL);
	std::string name_str(name_ptr);
	env->ReleaseStringUTFChars(name, name_ptr);

	const char* description_ptr = env->GetStringUTFChars(description, NULL);
	std::string description_str(description_ptr);
	env->ReleaseStringUTFChars(name, description_ptr);

	events.push_back({ event, name_str, description_str, numberProximity, latitude, longitude });
}

JNI_METHOD(void, passPerson)(JNIEnv* env, jclass, jstring name, jdouble latitude, jdouble longitude) {
	jboolean isCopy;
	const char* name_ptr = env->GetStringUTFChars(name, &isCopy);
	std::string name_str(name_ptr);
	if(isCopy == JNI_TRUE) {
		(env)->ReleaseStringUTFChars(name, name_ptr);
	}

	people.push_back({ name_str, latitude, longitude });
}

JNI_METHOD(void, sendCameraPosition)
(JNIEnv* env, jclass, jdouble latitude, jdouble longitude, jdouble zoom, jdouble tilt) {
	latitudeCamera  = latitude;
	longitudeCamera = longitude;
	zoomCamera      = zoom;
	tiltCamera      = tilt;
}

JNIEnv* GetJniEnv() {
	JNIEnv* env;
	jint result = g_vm->AttachCurrentThread(&env, nullptr);
	return result == JNI_OK ? env : nullptr;
}

jclass FindClass(const char* classname) {
	JNIEnv* env = GetJniEnv();
	return env->FindClass(classname);
}
}