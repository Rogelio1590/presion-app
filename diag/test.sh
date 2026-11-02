#!/bin/bash
# Prueba de instalación en emulador. Escribe todo en diag/out.txt
exec >> diag/out.txt 2>&1
set -x
BT=$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)
"$BT/apksigner" verify -v --print-certs apks/build-5/*.apk
"$BT/zipalign" -c -v 4 apks/build-5/*.apk | tail -3
"$BT/aapt2" dump badging apks/build-5/*.apk | head -3
adb shell getprop ro.build.version.sdk
echo "### instalar build-5 limpio"
adb install apks/build-5/*.apk
adb shell pm list packages | grep presion
adb uninstall com.rogelio.presion_app
echo "### instalar build-3 limpio (control)"
adb install apks/build-3/*.apk
adb uninstall com.rogelio.presion_app
echo "### fin"
