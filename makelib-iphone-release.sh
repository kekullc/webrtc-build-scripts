#!/bin/sh

# gclient can be found here:
# git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

# don't forget to modify .bashrc:
# export PATH="$PATH":/path/to/depot_tools

function fetch() {
    echo "-- fetching webrtc"
    gclient config http://webrtc.googlecode.com/svn/trunk/ || fail
    echo "target_os = ['ios', 'mac']" >> .gclient
    gclient sync || fail
    echo "-- webrtc has been sucessfully fetched"
}

function set_environment() {
    export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1"
    export GYP_GENERATORS="ninja"
    export GYP_DEFINES="$GYP_DEFINES OS=ios target_arch=armv7"
    export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=out_ios"
    export GYP_CROSSCOMPILE=1
}

function patch() {
   #TODO: fix bundle identifier
   #trunk/talk/app/webrtc/objctests/Info.plist 

   sed -i "" '/.*assert identity not in cache or fingerprint.*/d' trunk/tools/gyp/pylib/gyp/xcode_emulation.py
   sed -i "" '/.*Multiple codesigning fingerprints for identity.*/d' trunk/tools/gyp/pylib/gyp/xcode_emulation.py
   sed -i "" '/.*framework IOKit.*/d' trunk/talk/libjingle.gyp 
}

function build() {
    echo "-- building webrtc"
    pushd trunk
    gclient runhooks  || fail
    #TODO: fix code signing error
    ninja -C out_ios/Release-iphoneos libjingle_peerconnection_objc_test
    popd
    echo "-- webrtc has been sucessfully built"
}

function fail() {
    echo "*** webrtc build failed"
    exit 1
}

if [ ! -d trunk ]; then
    fetch || fail
    patch || fail
fi

set_environment || fail
build || fail

