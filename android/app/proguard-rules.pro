# For using API_KEY from .env
-keep class io.handleit.BuildConfig { *; }
# Prevent flutter_blue_plus "Field androidScanMode_ for t.h0 not found"
# https://github.com/boskokg/flutter_blue_plus/issues/300
-keep public class * extends com.google.protobuf.** { *; }