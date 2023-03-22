# For using API_KEY from .env
-keep class io.handleit.BuildConfig { *; }
# Need below to prevent errors scanning
-keep class com.boskokg.flutter_blue_plus.** { *; }
-keepclassmembernames class com.boskokg.flutter_blue_plus.* { *; }