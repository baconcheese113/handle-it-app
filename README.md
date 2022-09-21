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