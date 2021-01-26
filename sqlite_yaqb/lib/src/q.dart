
import 'sql_builder.dart';
import 'util.dart';

class Q {
  static SqlBuilder select(String fromTable, String alias) =>
      SqlBuilder.select(fromTable, alias);

  static SqlBuilder wrap(SqlBuilder source, String alias) =>
      SqlBuilder.wrap(source, alias);

  static SqlJoinBuilder join(String toTable, String toAlias) =>
      SqlJoinBuilder.join(toTable, toAlias);

  static SqlJoinBuilder leftJoin(String toTable, String toAlias) =>
      SqlJoinBuilder.leftJoin(toTable, toAlias);

  static SqlCondition eq<T, R>(String columnWithAlias, T value,
          [FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.eq(columnWithAlias, value, converter);

  static SqlCondition gt<T, R>(String columnWithAlias, T value,
          [FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.gt(columnWithAlias, value, converter);

  static SqlCondition ge<T, R>(String columnWithAlias, T value,
          [FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.ge(columnWithAlias, value, converter);

  static SqlCondition le<T, R>(String columnWithAlias, T value,
          [FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.le(columnWithAlias, value, converter);

  static SqlCondition custom<T,R>(String columnWithAlias,
  [T value, FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.custom(columnWithAlias, value);

  static SqlCondition like<T>(String columnWithAlias, String value) =>
      SqlCondition<String, String>.like(columnWithAlias, value);

  static SqlCondition inSubQuery(String columnWithAlias, SqlBuilder builder) =>
      SqlCondition.inSubQuery(columnWithAlias, builder);

  static SqlCondition inValues<T, R>(String columnWithAlias, List<T> values,
          [FunctionCallback<T, R> converter]) =>
      SqlCondition<T, R>.inValues(columnWithAlias, values, converter);

  static SqlCondition or(List<SqlCondition> conditions) =>
      SqlCondition.or(conditions);

  static SqlCondition isNull(String columnWithAlias) =>
      SqlCondition.isNull(columnWithAlias);

  static SqlCondition isNotNull(String columnWithAlias) =>
      SqlCondition.isNotNull(columnWithAlias);

  static SqlColumn column(String name, [String alias]) =>
      SqlColumn(name, null, alias);

  static SqlColumn tableColumn(String tableAlias, String name,
          [String alias]) =>
      SqlColumn(name, tableAlias, alias);
}
