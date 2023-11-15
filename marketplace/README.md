# Marketplace

Proyecto final

### .env

```env
# API
API_URL=
GOOGLE_MAPS_API_KEY=
```

### Configuración del proyecto

android > app > src > main > AndroidManifest.xml

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