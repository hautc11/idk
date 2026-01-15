# Build Variants

As an Android Developer you may need separate environments:

* `debug (Dev)`/`staging (QA)`: For testing features without affecting real user data.
* `release (Production)`: For publishing to the Play Store.

That's when you need to config some build variants for your project.

`build.gralde.kts` (:module level)

```groovy
android {
    ...

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
            buildConfigField("String", "BASE_URL", "\"https://dev.api.com/\"")
            //0. Fallback name if not specified elsewhere. Use ${appLabel} in AndroidManifest.xml for `android:label=`
            // Thinking about diferent API key for GGMap
            // <meta-data
            //    android:name="com.google.android.geo.API_KEY"
            //    android:value="${googleMapsKey}" />
            manifestPlaceholders["appName"] = "DailyDrive (Dev)"
        }

        create("staging") {
            initWith(getByName("debug")) //1. copies debug configuration.
            applicationIdSuffix = ".staging" //2. appends to package name.
            buildConfigField("String", "BASE_URL", "\"https://staging.api.com/\"") //3. Different base url (BuildConfig.BASE_URL)
            manifestPlaceholders["appName"] = "DailyDrive (QA)"
            
            //If others module/library that do not have `staging`, please use `debug` instead for them.
            matchingFallbacks += listOf("debug")
        }

        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    ...

    buildFeatures {
        compose = true
        buildConfig = true // <- Don't forgot this!
    }
}
```

## Results

1. We have different package name for different build variant.

    ![package-name-by-variant](../images/package_by_variants_android.png)

2. Each variant have different app label/app name and logo.

    ![app-name-by-variant](../images/app_name_by_variants_android.png)

3. Each variant have different directory for `res`
    
    * This is how we add new directory for `res` for new variant.

    ![res-by-variant](../images/res_by_variants_android.png)

    * Add resource for each variant.

    ![add-res-by-variant](../images/add_res_by_variants_android.png)

    * And we also do this for `strings.xml`, `values.xml`...

4. We can also have Variant-Specific Dependencies

    ```groovy
        dependencies {
            implementation("androidx.core:core-ktx:1.12.0")
            
            // Syntax: "flavorNameImplementation"
            // Only 'debug' and 'staging' (which copies debug) get this
            "debugImplementation"("com.squareup.leakcanary:leakcanary-android:2.12")
        }
    ```

## Build Variants vs. Build Types

<b>Build Type:</b> Manages Technical aspects (Minify, Debug) + Environment (Server URL, API Key).

<b>Flavor:</b> Manages Business aspects (Features, Limits, Content, Branding).

<b>Both:</b> Use `buildConfigField`, `manifestPlaceholders`, and `applicationIdSuffix` to serve their own respective purposes.