#!/bin/sh

IFS='
'

MYARCH=linux-x86
if uname -s | grep -i "linux" > /dev/null ; then
	MYARCH=linux-x86
fi
if uname -s | grep -i "darwin" > /dev/null ; then
	MYARCH=darwin-x86
fi
if uname -s | grep -i "windows" > /dev/null ; then
	MYARCH=windows-x86
fi

NDK=`which ndk-build`
NDK=`dirname $NDK`
NDK=`readlink -f $NDK`

#echo NDK $NDK
GCCPREFIX=arm-linux-androideabi
GCCVER=4.6
PLATFORMVER=android-8
LOCAL_PATH=`dirname $0`
LOCAL_PATH=`cd $LOCAL_PATH && pwd`
ARCH=armeabi-v7a
#echo LOCAL_PATH $LOCAL_PATH

APP_MODULES=`grep 'APP_MODULES [:][=]' $LOCAL_PATH/../Settings.mk | sed 's@.*[=]\(.*\)@\1@'`
APP_AVAILABLE_STATIC_LIBS=`grep 'APP_AVAILABLE_STATIC_LIBS [:][=]' $LOCAL_PATH/../Settings.mk | sed 's@.*[=]\(.*\)@\1@'`
APP_SHARED_LIBS=$(
echo $APP_MODULES | xargs -n 1 echo | while read LIB ; do
	STATIC=`echo $APP_AVAILABLE_STATIC_LIBS application sdl_main stlport stdout-test | grep "\\\\b$LIB\\\\b"`
	if [ -n "$STATIC" ] ; then true
	else
		echo $LIB
	fi
done
)


MISSING_INCLUDE=
MISSING_LIB=

CFLAGS="\
-fpic -ffunction-sections -funwind-tables \
-D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__ -Wno-psabi \
-march=armv7-a -mfloat-abi=softfp -mfpu=vfp -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 \
-DANDROID -Wa,--noexecstack -g -O2 -DNDEBUG -g \
-isystem$NDK/platforms/$PLATFORMVER/arch-arm/usr/include \
-isystem$NDK/sources/cxx-stl/gnu-libstdc++/$GCCVER/include \
-isystem$NDK/sources/cxx-stl/gnu-libstdc++/$GCCVER/libs/$ARCH/include \
-isystem$LOCAL_PATH/../sdl-1.2/include \
`echo $APP_MODULES | sed \"s@\([-a-zA-Z0-9_.]\+\)@-isystem$LOCAL_PATH/../\1/include@g\"` \
$MISSING_INCLUDE $CFLAGS"

SHARED="-shared -Wl,-soname,libapplication.so"
if [ -n "$BUILD_EXECUTABLE" ]; then
	SHARED=
fi
if [ -n "$NO_SHARED_LIBS" ]; then
	APP_SHARED_LIBS=
fi

LDFLAGS="\
$SHARED \
--sysroot=$NDK/platforms/$PLATFORMVER/arch-arm \
`echo $APP_SHARED_LIBS | sed \"s@\([-a-zA-Z0-9_.]\+\)@$LOCAL_PATH/../../obj/local/$ARCH/lib\1.so@g\"` \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/libc.so \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/libm.so \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/libGLESv1_CM.so \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/libdl.so \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/liblog.so \
$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib/libz.so \
-L$NDK/sources/cxx-stl/gnu-libstdc++/$GCCVER/libs/$ARCH \
-lgnustl_static \
-L$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib \
-L$LOCAL_PATH/../../obj/local/$ARCH \
-Wl,--fix-cortex-a8 -Wl,--no-undefined -Wl,-z,noexecstack \
-Wl,-rpath-link=$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib -lsupc++ \
$MISSING_LIB $LDFLAGS"

#echo env CFLAGS=\""$CFLAGS"\" LDFLAGS=\""$LDFLAGS"\" "$@"

env PATH=$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin:$LOCAL_PATH:$PATH \
CFLAGS="$CFLAGS" \
CXXFLAGS="$CXXFLAGS $CFLAGS" \
LDFLAGS="$LDFLAGS" \
CC="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-gcc" \
CXX="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-g++" \
RANLIB="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-ranlib" \
LD="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-g++" \
AR="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-ar" \
CPP="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-cpp $CFLAGS" \
NM="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-nm" \
AS="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-as" \
STRIP="$NDK/toolchains/$GCCPREFIX-$GCCVER/prebuilt/$MYARCH/bin/$GCCPREFIX-strip" \
"$@"
