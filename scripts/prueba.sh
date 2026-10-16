#!/bin/bash
# Abre MINIPTV en el emulador, entra en Xtream y escribe la contraseña.
# Guarda pantallas, registros y avisos de "no responde" en salida/.
DIR="${GITHUB_WORKSPACE:-$PWD}"
SALIDA="$DIR/salida"
PKG=com.iptv.mio
mkdir -p "$SALIDA"
RESUMEN="$SALIDA/resumen.txt"
: > "$RESUMEN"

APK=$(find "$DIR/proyecto" -path "*debug*" -name "*.apk" | head -1)
echo "APK: $APK" | tee -a "$RESUMEN"
adb wait-for-device
adb install -r "$APK" | tee -a "$RESUMEN"
adb logcat -c

tocar() { # modo valor: "texto Xtream" o "editar 2"
  for intento in 1 2 3 4 5; do
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
    adb pull /sdcard/ui.xml "$SALIDA/ui_ultimo.xml" >/dev/null 2>&1
    if coord=$(python3 "$DIR/scripts/buscar.py" "$SALIDA/ui_ultimo.xml" $1 "$2"); then
      echo "Toco $1 $2 en $coord" | tee -a "$RESUMEN"
      adb shell input tap $coord
      sleep 2
      return 0
    fi
    sleep 2
  done
  echo "NO ENCONTRADO: $1 $2" | tee -a "$RESUMEN"
  return 1
}

captura() { # nombre
  adb shell screencap -p /sdcard/captura.png
  adb pull /sdcard/captura.png "$SALIDA/$1.png" >/dev/null 2>&1
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb pull /sdcard/ui.xml "$SALIDA/$1.xml" >/dev/null 2>&1
}

adb shell am start -n $PKG/.MainActivity
sleep 6
captura 1_inicio
tocar texto Xtream
sleep 3
captura 2_perfil_vacio

tocar editar 0
adb shell input text "http://192.168.1.50:9191"
tocar editar 1
adb shell input text "usuariotest"
tocar editar 2
adb shell input text "Prueba123"
sleep 5
captura 3_tras_contraseña

if grep -qi "no responde" "$SALIDA/3_tras_contraseña.xml" 2>/dev/null; then
  echo "AVISO: aparece 'no responde'" | tee -a "$RESUMEN"
fi
if adb shell pidof $PKG >/dev/null 2>&1; then
  echo "La app sigue viva" | tee -a "$RESUMEN"
else
  echo "La app NO esta en ejecucion" | tee -a "$RESUMEN"
fi

adb logcat -d > "$SALIDA/logcat.txt"
grep -iE "ANR|FATAL|$PKG" "$SALIDA/logcat.txt" > "$SALIDA/errores.txt" || true
adb root >/dev/null 2>&1 && adb pull /data/anr/ "$SALIDA/anr/" >/dev/null 2>&1 || true
echo "Fin de la prueba" | tee -a "$RESUMEN"
