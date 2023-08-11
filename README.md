## Getting Started

Generate the schema with the Android Studio GraphQL plugin pointed at localhost

Then run
```shell
flutter pub run build_runner build --delete-conflicting-outputs
```

to generate the graphql_codegen types

## Testing

Run integration tests with
```shell
flutter test integration_test --flavor devtest

```

# Firebase and flavors
These commands update the firebase configuration for each flavor
```shell
flutterfire config \
--project=handleit-devtest \
--out=lib/firebase_options_devtest.dart \
--ios-bundle-id=io.handleit.devtest \
--android-app-id=io.handleit.devtest
```
```shell
  flutterfire config \
--project=handleit-f352d \
--out=lib/firebase_options.dart \
--ios-bundle-id=io.handleit \
--android-app-id=io.handleit
```

In Flutter pod install should not called manually. 
To run pod install execute the following commands flutter clean, flutter pub get and flutter build ios.