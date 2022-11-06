#include <jni.h>

// "00024Companion" required for kotlin
#define JNI_METHOD(return_type, method_name)                                                                           \
	JNIEXPORT return_type JNICALL Java_com_tgrcode_EventsApp_Renderer_00024Companion_##method_name

extern "C" {
JNIEnv* GetJniEnv();

JNI_METHOD(void, createRenderer)(JNIEnv* env, jclass, jint, jint);
JNI_METHOD(jboolean, renderFrame)(JNIEnv* env, jclass);
JNI_METHOD(void, closeRenderer)(JNIEnv* env, jclass);

JNI_METHOD(void, clearExistingEvents)(JNIEnv* env, jclass);
JNI_METHOD(void, passEvent)(JNIEnv* env, jclass, jint, jstring, jstring, jint, jdouble, jdouble);
JNI_METHOD(void, passPerson)(JNIEnv* env, jclass, jstring, jdouble, jdouble);

JNI_METHOD(void, sendCameraPosition)(JNIEnv* env, jclass, jdouble, jdouble, jdouble, jdouble);
}