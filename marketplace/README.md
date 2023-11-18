# Marketplace

Proyecto final

### .env

```env
# API
API_URL=
GOOGLE_MAPS_API_KEY=
```

### Configuración del proyecto en Android

android/app/src/main/AndroidManifest.xml

Se debe agregar el siguiente código dentro de la etiqueta `<manifest>`

```xml
<queries>
<!-- If your app checks for SMS support -->
<intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="sms" />
</intent>
<!-- If your app checks for call support -->
<intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="tel" />
</intent>
<!-- If your application checks for inAppBrowserView launch mode support -->
<intent>
    <action android:name="android.support.customtabs.action.CustomTabsService" />
</intent>
</queries>
```

Se debe agregar el siguiente código dentro de la etiqueta `<application>`, reemplazando `GOOGLE_MAPS_API_KEY` por la API Key de Google Maps

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="GOOGLE_MAPS_API_KEY" />
```

android/app/build.gradle

```gradle
android {
    defaultConfig {
        minSdkVersion 20
    }
}
```