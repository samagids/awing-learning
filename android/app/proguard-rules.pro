# =============================================================================
# Awing AI Learning — R8 / ProGuard rules
# =============================================================================
# Session 61 hardened: R8 minify + resource shrink is enabled in
# android/app/build.gradle.kts release buildType. Without comprehensive keep
# rules, R8 will strip plugin classes that Flutter / Firebase / Google Sign-In
# reach via reflection at runtime, causing crashes that only manifest on
# release builds (debug never minifies). Add a new keep rule whenever a
# plugin or new SDK is added and verify the release build works on a real
# device before tagging.
#
# Stack-trace preservation: we keep line numbers + the SourceFile attribute
# renamed so crash reports remain mappable, but class/method names are still
# obfuscated. The R8 mapping.txt is written to build/app/outputs/mapping/
# release/ — upload to Play Console under "App bundle explorer > Mapping"
# to deobfuscate Play Console crash reports.
# =============================================================================

# ---------- Optimization pass: ON (v1.23.5, Session 64d) ---------------------
# `-dontoptimize` was removed here. Play Console flagged release 140 (1.23.4):
#
#   "DEX code optimization is below our threshold — Optimization (0%).
#    Percentages under 25% in any category may impact your visibility and
#    publishing capabilities on Google Play."  Fix by Feb 2027.
#
# The old note said optimization had to stay off because R8 "inlines methods
# that Flutter plugins reach via reflection (Firebase, Google Sign-In,
# tflite_flutter)". That risk is real in general, but every one of those
# three already has a blanket `-keep class ... { *; }` below (added in
# Session 61, AFTER the reasoning that produced -dontoptimize). A `-keep`
# with `{ *; }` preserves every member, so R8 cannot delete or inline away
# the very methods reflection looks up. The guard was doing less work than
# its comment claimed.
#
# NOTE: R8 ignores ProGuard's `-optimizations` directive, so there is no
# way to enable optimization "partially". Keep rules are the only lever —
# which is why the safety net below is explicit rather than inherited.
#
# THIS IS THE HIGHEST-RISK CHANGE IN 1.23.5. Optimization defects are
# release-only; a debug build proves nothing. Before tagging, on a REAL
# device running the release build:
#   1. Google Sign-In (new account AND returning account)
#   2. Sign in with Apple on real iOS hardware
#   3. Firestore sync — make progress, confirm it lands in the cloud
#   4. TFLite inference — the pronunciation scorer
#   5. Dev Mode 2FA, exam mode (nsd/mDNS), audio record + playback
# If any of those fail only in release, put `-dontoptimize` back and ship
# without it; the Play deadline is Feb 2027, not this week.

# ---------- Optimization safety net ------------------------------------------
# These are the classic things that break the moment the optimization pass
# turns on. The AGP default `proguard-android-optimize.txt` includes most of
# them, but inheriting them silently is an assumption, and this codebase has
# been bitten repeatedly by assumptions that were true until they weren't.
# Declaring them here costs nothing and is idempotent with the default file.

# JNI: a native method's name is resolved by the JVM at link time. If R8
# renames or inlines it, the lookup fails with UnsatisfiedLinkError — and
# TFLite, Firestore's native client and Flutter's engine are all JNI.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enums: values() / valueOf() are called reflectively by serializers
# (Firestore codecs, JSON) even when nothing in the source calls them.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable: the framework reads the CREATOR field by name via reflection.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Serializable: the runtime reads these members reflectively during
# (de)serialization.
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ---------- Flutter embedding (do not strip) ---------------------------------
# Flutter reaches into io.flutter.* from Dart via the JNI; obfuscating these
# breaks the platform channel layer.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---------- AndroidX -------------------------------------------------------
# enableEdgeToEdge() and FlutterFragmentActivity reach into these via
# reflection.
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.app.** { *; }
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.**

# ---------- Our platform channel (MainActivity) ------------------------------
# Method names "getAssetPath / getAssetBytes / assetExists" are reflected
# from Dart via MethodChannel. The class itself is named in AndroidManifest
# as ".MainActivity" so its FQN must not be obfuscated.
-keep class com.awing.awing_ai_learning.MainActivity { *; }
-keepclassmembers class com.awing.awing_ai_learning.** {
    public *;
}

# ---------- Firebase / Google Mobile Services --------------------------------
# Firebase Auth, Firestore, App Check, and Crashlytics all use reflection
# heavily (serialization codecs, plugin registration, JNI for the native
# Firestore client). Without these keeps, app crashes on first auth call.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
-dontwarn com.google.protobuf.**

# Firebase App Check (Session 61 V3+G10) — Play Integrity provider on Android
-keep class com.google.firebase.appcheck.** { *; }
-keep interface com.google.firebase.appcheck.** { *; }
-keep class com.google.android.recaptcha.** { *; }
-dontwarn com.google.firebase.appcheck.**

# Play Integrity API (used by App Check Android provider)
-keep class com.google.android.play.core.integrity.** { *; }
-dontwarn com.google.android.play.core.integrity.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# ---------- TFLite (existing; expanded) --------------------------------------
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegate

# ---------- Kotlin metadata (required for reflection) ------------------------
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ---------- Reflection attributes --------------------------------------------
# Preserve attributes that runtime reflection and stack traces need.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Rename SourceFile attribute so stack traces in release builds don't leak
# the original Kotlin/Java file names, but Play Console can still map them
# via the uploaded mapping.txt.
-renamesourcefileattribute SourceFile

# ---------- Google Services auto-generated strings ---------------------------
# The `com.google.gms.google-services` Gradle plugin generates these string
# resources from google-services.json at build time. Firebase + Google
# Sign-In SDKs read them via Resources.getString(). R8 minify alone is
# safe (it operates on classes), but if shrinkResources is ever re-enabled
# these MUST be in keep_resources to avoid GoogleSignatureVerifier
# "package info is not set correctly" + ApiException-38003 on sign-in.
-keepclassmembers class **.R$string {
    public static <fields>;
}
-keepclassmembers class **.R$xml {
    public static <fields>;
}
# Firebase / Google Sign-In init reads these specific strings by name:
#   default_web_client_id, firebase_app_id, gcm_defaultSenderId,
#   google_api_key, google_app_id, google_crash_reporting_api_key,
#   google_storage_bucket, project_id
# Keeping the whole R$string class above covers all of them.

# ---------- Plugin-specific keep rules ---------------------------------------
# Most Flutter plugins ship consumerProguardFiles inside their AARs so R8
# picks them up automatically. The blocks below cover plugins that have
# been observed to need extra keeps in production Flutter apps.

# speech_to_text — uses Android SpeechRecognizer system service
-keep class android.speech.** { *; }

# record — uses MediaRecorder and AudioRecord
-keep class android.media.MediaRecorder { *; }
-keep class android.media.AudioRecord { *; }

# nsd (mDNS / Bonjour for exam mode)
-keep class android.net.nsd.** { *; }

# audioplayers — uses MediaPlayer and ExoPlayer
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# url_launcher — uses Intent serialization
-keep class android.content.Intent { *; }

# OkHttp (transitive via google_sign_in + firebase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ---------- flutter_gemma + MediaPipe Tasks GenAI (DORMANT) ----------------
# flutter_gemma disabled in pubspec.yaml (iOS 16 requirement + Windows JVM
# crash). Uncomment BOTH pubspec + this block when re-enabling for C3.
# -keep class com.google.mediapipe.** { *; }
# -keep interface com.google.mediapipe.** { *; }
# -dontwarn com.google.mediapipe.**
# -dontwarn javax.lang.model.**
# -dontwarn javax.annotation.processing.**
# -dontwarn autovalue.shaded.**
# -dontwarn com.google.auto.value.**
# -keep class dev.flutterberlin.flutter_gemma.** { *; }
# -keep class com.tommihirvonen.large_file_handler.** { *; }
# -dontwarn dev.flutterberlin.flutter_gemma.**
# -dontwarn com.tommihirvonen.large_file_handler.**
