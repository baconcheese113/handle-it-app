DateTime fromGraphQLDateTimeToDartDateTime(String date) => DateTime.parse(date);
String fromDartDateTimeToGraphQLDateTime(DateTime date) => date.toUtc().toString();

DateTime? fromGraphQLDateTimeNullableToDartDateTimeNullable(String? date) => date == null ? null : DateTime.parse(date);
String? fromDartDateTimeNullableToGraphQLDateTimeNullable(DateTime? date) => date?.toUtc().toString();
