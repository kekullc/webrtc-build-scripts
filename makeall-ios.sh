#!/bin/sh

export PATH=$PATH:$PWD/depot_tools
CONFIGURATION=Release
DIR=src

function fetch() {
    echo "-- fetching webrtc"
    gclient sync || fail
    echo "-- webrtc has been sucessfully fetched"
}

function fail() {
    echo "*** webrtc build failed"
    exit 1
}

function set_environment() {
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1"
    export GYP_GENERATORS="ninja"
    export GYP_CROSSCOMPILE=1
}

set_environment_for_device32() {
    set_environment
    #export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=arm arm_version=7"
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=armv7"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_ios"
}

set_environment_for_device64() {
    set_environment
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=arm64 target_subarch=arm64"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_ios64"
}

set_environment_for_sim32() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=ia32"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_sim"
}

set_environment_for_sim64() {
   set_environment
   export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=x64 target_subarch=arm64"
   export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_sim64"
}

function patch() {
   # fix signing issues with multiply idendities
   sed -i "" "/.*assert identity not in cache or fingerprint.*/d" $DIR/tools/gyp/pylib/gyp/xcode_emulation.py
   sed -i "" "/.*Multiple codesigning fingerprints for identity*/d" $DIR/tools/gyp/pylib/gyp/xcode_emulation.py
}

function build_device32() {
    echo "-- building webrtc/device32"
    pushd $DIR || fail
    set_environment_for_device32
    gclient runhooks  || fail
    ninja -C out_ios/$CONFIGURATION-iphoneos libjingle_peerconnection_objc_test || fail
    rm out_ios/$CONFIGURATION-iphoneos/libboringssl.a
    libtool -static -no_warning_for_no_symbols -o ../libWebRTC-armv7.a out_ios/$CONFIGURATION-iphoneos/*.a || fail
    popd
    strip -S -x -o libWebRTC-armv7-stripped.a -r libWebRTC-armv7.a || fail
    mv libWebRTC-armv7-stripped.a libWebRTC-armv7.a || fail
    echo "-- webrtc/device32 has been sucessfully built"
}

build_device64() {
    echo "-- building webrtc/device64"
    pushd $DIR || fail
    set_environment_for_device64
    gclient runhooks || fail
    ninja -C out_ios64/$CONFIGURATION-iphoneos libjingle_peerconnection_objc_test || fail
    rm out_ios64/$CONFIGURATION-iphoneos/libboringssl.a
    libtool -static -no_warning_for_no_symbols -o ../libWebRTC-arm64.a out_ios64/$CONFIGURATION-iphoneos/*.a || fail
    popd
    strip -S -x -o libWebRTC-arm64-stripped.a -r libWebRTC-arm64.a || fail
    mv libWebRTC-arm64-stripped.a libWebRTC-arm64.a || fail
    echo "-- webrtc/device64 has been sucessfully built"
}

build_sim32() {
    echo "-- building webrtc/sim32"
    pushd $DIR || fail
    set_environment_for_sim32
    gclient runhooks || fail
    ninja -C out_sim/$CONFIGURATION libjingle_peerconnection_objc_test || fail
    rm out_sim/$CONFIGURATION/libboringssl.a
    libtool -static -no_warning_for_no_symbols -o ../libWebRTC-ia32.a out_sim/$CONFIGURATION/*.a || fail
    popd
    strip -S -x -o libWebRTC-ia32-stripped.a -r libWebRTC-ia32.a || fail
    mv libWebRTC-ia32-stripped.a libWebRTC-ia32.a || fail
    echo "-- webrtc/sim32 has been sucessfully built"
}

build_sim64() {
    echo "-- building webrtc/sim64"
    pushd $DIR || fail
    set_environment_for_sim64
    gclient runhooks || fail
    ninja -C out_sim64/$CONFIGURATION libjingle_peerconnection_objc_test || fail
    rm out_sim64/$CONFIGURATION/libboringssl.a
    libtool -static -no_warning_for_no_symbols -o ../libWebRTC-x64.a out_sim64/$CONFIGURATION/*.a || fail
    popd
    strip -S -x -o libWebRTC-x64-stripped.a -r libWebRTC-x64.a || fail
    mv libWebRTC-x64-stripped.a libWebRTC-x64.a || fail
    echo "-- webrtc/sim64 has been sucessfully built"
}

concatinate_libs() {
    echo "-- concatinating webrtc libraries"
    lipo -create libWebRTC-armv7.a libWebRTC-arm64.a libWebRTC-ia32.a libWebRTC-x64.a -output libWebRTC.a || fail
    echo "-- webrtc library has been sucessfully concatinated"
}

create_framework() {
    echo "-- creating webrtc framework"
    cp libWebRTC.a WebRTC.framework/Versions/A/WebRTC || fail
    mkdir -p WebRTC.framework/Versions/A/Headers
    cp src/talk/app/webrtc/objc/public/* WebRTC.framework/Versions/A/Headers || fail
    echo "-- webrtc framework created"
}

fetch || fail
patch || fail
build_device32 || fail
build_device64 || fail
build_sim32 || fail
build_sim64 || fail
concatinate_libs || fail
create_framework || fail