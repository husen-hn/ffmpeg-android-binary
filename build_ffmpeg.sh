#!/bin/bash

# Set NDK path
ANDROID_NDK_HOME="/opt/android-ndk"

# Update FFmpeg version
FFMPEG_VERSION="7.1"

# Use current directory
WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"
echo "Build started at: 2025-03-28 11:45:31 by husen-hn"
echo "FFmpeg version: $FFMPEG_VERSION"

# Clean old build if exists
if [ -d "ffmpeg-${FFMPEG_VERSION}" ]; then
    echo "Cleaning old FFmpeg build directory..."
    rm -rf "ffmpeg-${FFMPEG_VERSION}"
fi

# Extract FFmpeg
echo "Extracting FFmpeg..."
if [ -f "ffmpeg-${FFMPEG_VERSION}.tar.bz2" ]; then
    tar xjf "ffmpeg-${FFMPEG_VERSION}.tar.bz2" || {
        echo "Failed to extract FFmpeg"
        exit 1
    }
else
    echo "Error: ffmpeg-${FFMPEG_VERSION}.tar.bz2 not found!"
    echo "Please download FFmpeg 7.1 from:"
    echo "https://ffmpeg.org/releases/ffmpeg-7.1.tar.bz2"
    echo ""
    echo "You can download it using:"
    echo "wget https://ffmpeg.org/releases/ffmpeg-7.1.tar.bz2"
    exit 1
fi

cd "ffmpeg-${FFMPEG_VERSION}"

# Verify NDK path
echo "Checking NDK path: $ANDROID_NDK_HOME"
if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: NDK path not found: $ANDROID_NDK_HOME"
    exit 1
fi

TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

if [ ! -d "$TOOLCHAIN" ]; then
    echo "Error: Toolchain not found: $TOOLCHAIN"
    exit 1
fi

function build_ffmpeg
{
    ABI=$1
    ANDROID_API=21

    echo "Building FFmpeg for $ABI"
    
    case ${ABI} in
        armeabi-v7a)
            ARCH=arm
            CPU=armv7-a
            CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
            CC=$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi${ANDROID_API}-clang++
            ;;
        arm64-v8a)
            ARCH=aarch64
            CPU=armv8-a
            CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
            CC=$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/aarch64-linux-android${ANDROID_API}-clang++
            ;;
        x86_64)
            ARCH=x86_64
            CPU=x86-64
            CROSS_PREFIX=$TOOLCHAIN/bin/x86_64-linux-android-
            CC=$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API}-clang
            CXX=$TOOLCHAIN/bin/x86_64-linux-android${ANDROID_API}-clang++
            ;;
    esac

    PREFIX=$WORK_DIR/android/$ABI
    mkdir -p $PREFIX
    
    echo "Configuring FFmpeg for $ABI"
    ./configure \
        --prefix=$PREFIX \
        --enable-shared \
        --disable-static \
        --disable-doc \
        --disable-programs \
        --disable-everything \
        --disable-vulkan \
        --disable-ffmpeg \
        --disable-ffplay \
        --disable-ffprobe \
        --disable-avdevice \
        --disable-devices \
        --disable-hwaccels \
        --disable-dxva2 \
        --disable-vaapi \
        --disable-vdpau \
        --enable-protocol=file \
        --enable-decoder=h264,aac,mp3 \
        --enable-encoder=libx264,aac \
        --enable-parser=h264,aac \
        --enable-demuxer=mov,mp4,matroska \
        --enable-muxer=mp4,matroska \
        --enable-gpl \
        --enable-pic \
        --cross-prefix=$CROSS_PREFIX \
        --target-os=android \
        --arch=$ARCH \
        --cpu=$CPU \
        --cc=$CC \
        --cxx=$CXX \
        --enable-cross-compile \
        --sysroot=$TOOLCHAIN/sysroot \
        --extra-cflags="-Os -fpic" \
        --extra-ldflags="" || {
            echo "Configure failed for $ABI"
            return 1
        }

    echo "Building FFmpeg for $ABI"
    make clean
    make -j$(nproc) || {
        echo "Make failed for $ABI"
        return 1
    }
    make install || {
        echo "Make install failed for $ABI"
        return 1
    }
    echo "Successfully built FFmpeg for $ABI"
}

# Build only for specified architectures
for ABI in armeabi-v7a arm64-v8a x86_64
do
    echo "Starting build for $ABI..."
    build_ffmpeg $ABI
    if [ $? -ne 0 ]; then
        echo "Build failed for $ABI"
        exit 1
    fi
done

# Copy .so files to the project
PROJECT_LIBS="$WORK_DIR/android/project_libs"
mkdir -p $PROJECT_LIBS

# Copy only for specified architectures
for ABI in armeabi-v7a arm64-v8a x86_64
do
    ABI_LIBS="$PROJECT_LIBS/$ABI"
    mkdir -p $ABI_LIBS
    cp $WORK_DIR/android/$ABI/lib/*.so $ABI_LIBS/ || {
        echo "Failed to copy .so files for $ABI"
        exit 1
    }
done

echo "Build completed! .so files are in $PROJECT_LIBS"
echo "Built architectures: armeabi-v7a arm64-v8a x86_64"
echo "FFmpeg version: $FFMPEG_VERSION"