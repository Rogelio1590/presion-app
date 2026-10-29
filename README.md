# Presión

App Android para registrar tomas de presión arterial según el protocolo de
automonitoreo (controles de 7 días, 2 tomas a la mañana y 2 a la tarde).

- Los datos se guardan **solo en el celular** (SQLite).
- Exporta a Excel con el formato de la planilla de la cardióloga.
- Dashboard con promedios (descartando el día 1), evolución entre controles
  y comparador de controles o rangos de fechas.

## Descargar el APK

Cada push a `main` compila la app en GitHub Actions y publica el APK en
**Releases** (`build-N`). Desde el celu: entrar al repo → Releases → bajar
`presion-app-N.apk` e instalar.

Todos los builds se firman con la misma clave (`ci/debug.keystore`), así que
cada APK nuevo se instala como actualización sin perder los datos.

## Compilar localmente

```bash
flutter create --org com.rogelio --project-name presion_app --platforms android .
cp ci/debug.keystore ~/.android/debug.keystore   # misma firma que los builds de CI
flutter pub get
flutter build apk --release
```

## Backup

Menú ⋮ → *Backup de la base* comparte el archivo `.db`. Conviene hacerlo
después de cada control o exportar el historial a Excel.
