cmake_minimum_required(VERSION 3.10)
project(events_android)

if(ANDROID)
	# Define Android architecture variables
	# Used for building in skia and determining build locations
	if(ANDROID_ABI STREQUAL "armeabi-v7a")
		set(ANDROID_ARCH "arm")
	elseif(ANDROID_ABI STREQUAL "arm64-v8a")
		set(ANDROID_ARCH "arm64")
	elseif(ANDROID_ABI STREQUAL "x86")
		set(ANDROID_ARCH "x86")
	elseif(ANDROID_ABI STREQUAL "x86_64")
		set(ANDROID_ARCH "x64")
	endif()
endif()

set(SKIA_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../third_party/skia)
set(SKIA_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/third_party/skia)
execute_process(
	COMMAND python tools/git-sync-deps
	WORKING_DIRECTORY ${SKIA_DIR})
if(ANDROID)
	execute_process(
		COMMAND bin/gn gen ${SKIA_BUILD_DIR} "--args=is_debug=false ndk=\"${ANDROID_NDK}\" target_cpu=\"${ANDROID_ARCH}\" is_component_build=true skia_use_system_libjpeg_turbo=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_zlib=false skia_use_system_libpng=false skia_use_system_harfbuzz=false skia_use_system_icu=false skia_use_system_icu=false"
		WORKING_DIRECTORY ${SKIA_DIR})
	add_library(skia SHARED IMPORTED)
	set_property(TARGET skia PROPERTY
		IMPORTED_LOCATION ${SKIA_BUILD_DIR}/libskia.so)
elseif(WIN32)
	execute_process(
		COMMAND bin/gn gen ${SKIA_BUILD_DIR} "--args=is_official_build=true clang_win=\"C:/Program Files/LLVM\" extra_cflags=[\"/MDd\"] skia_use_system_libjpeg_turbo=false skia_use_system_libwebp=false skia_use_system_expat=false skia_use_system_zlib=false skia_use_system_libpng=false skia_use_system_harfbuzz=false skia_use_system_icu=false"
		WORKING_DIRECTORY ${SKIA_DIR})
	add_library(skia STATIC IMPORTED)
	set_property(TARGET skia PROPERTY
		IMPORTED_LOCATION ${SKIA_BUILD_DIR}/skia.lib)
else()
	# MacOS
endif()
execute_process(COMMAND ninja WORKING_DIRECTORY ${SKIA_BUILD_DIR})

# The main native app library
add_library(events_android_native SHARED
	src/main/cpp/jni_interface.cpp)

target_include_directories(events_android_native PRIVATE src/main/cpp ${SKIA_DIR} ${SKIA_DIR}/include)
target_link_libraries(events_android_native log android skia GLESv3 EGL)
