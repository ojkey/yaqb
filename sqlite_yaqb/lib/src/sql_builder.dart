
import 'util.dart';

class SqlBuilder {
  String _from;
  List<String> _columns = [];
  List<String> _joins = [];
  List<String> _args = [];
  List<Object> _values = [];
  List<SqlColumnSort> _orderBy = [];
  List<SqlColumn> _groupBy = [];
  int _limit;
  int _offset;

  SqlBuilder.select(String fromTable, String alias) {
    _from = "$fromTable $alias";
  }

  SqlBuilder.wrap(SqlBuilder source, String alias) {
    _from = "(${source.toQuery()}) $alias";
    _values.addAll(source._values);
  }

  SqlBuilder column(String name, [String alias]) {
    if (nonNull(alias)) {
      name = "$name $alias";
    }
    _columns.add(name);
    return this;
  }

  SqlBuilder value(Object value) {
    _values.add(value);
    return this;
  }

  SqlBuilder join(SqlJoinOnBuilder join) {
    _joins.add(join.build());
    return this;
  }

  SqlBuilder where(SqlCondition condition) {
    _args.add(condition.toCondition());
    _values.addAll(condition.toArguments());
    return this;
  }

  SqlBuilder orderBy(SqlColumnSort column) {
    _orderBy.add((column));
    return this;
  }

  SqlBuilder groupBy(SqlColumn column) {
    _groupBy.add(column);
    return this;
  }

  /// Number of rows to select
  SqlBuilder limit(int limit) {
    _limit = limit;
    return this;
  }

  /// How many rows to skip
  SqlBuilder offset(int offset) {
    this._offset = offset;
    return this;
  }

  String toQuery() {
    var query = "select";
    if (_columns.isNotEmpty) {
      query += " ${_columns.join(', ')}";
    } else {
      query += " *";
    }
    query += "\n from $_from";
    if (_joins.isNotEmpty) {
      query += "\n ${_joins.join('\n ')}";
    }
    if (_args.isNotEmpty) {
      query += "\n where ${_args.join(' and ')}";
    }
    if (_orderBy.isNotEmpty) {
      query += "\n order by ${_orderBy.join(', ')}";
    }
    if (_groupBy.isNotEmpty) {
      query += "\n group by ${_groupBy.map(toGrouping).join(', ')}";
    }
    if (nonNull(_limit)) {
      query += "\n limit $_limit";
    }
    if (nonNull(_offset)) {
      query += (isNull(_limit) ? "\n" : "") + " offset $_offset";
    }
    return query;
  }

  String toGrouping(SqlColumn c) => c._toGrouping();

  List<Object> toArguments() => _values;
}

class SqlJoinBuilder {
  String _query;
  List<String> _conditions = [];

  SqlJoinBuilder._join(String query, String toTable, String toAlias)
      : this._query = "$query $toTable $toAlias";

  SqlJoinBuilder.join(String toTable, String toAlias)
      : this._join("join", toTable, toAlias);

  SqlJoinBuilder.leftJoin(String toTable, String toAlias)
      : this._join("left join", toTable, toAlias);

  SqlJoinOnBuilder on(String condition) {
    _conditions.add(condition);
    return SqlJoinOnBuilder._onDone(this);
  }

  String _build() {
    return "$_query on ${_conditions.join(' and ')}";
  }
}

class SqlJoinOnBuilder {
  SqlJoinBuilder _builder;

  SqlJoinOnBuilder._onDone(this._builder);

  SqlJoinOnBuilder on(String condition) {
    _builder.on(condition);
    return this;
  }

  String build() => _builder._build();
}

class SqlCondition<T, R> {
  String _left;
  String _right;
  String _condition;
  List<Object> _arguments = [];

  SqlCondition.eq(String columnWithAlias, T value,
      [FunctionCallback<T, R> converter]) {
    _left = columnWithAlias;
    _condition = "=";
    _right = "?";
    _addArgument(value, converter);
  }

  SqlCondition.ge(String columnWithAlias, T value,
      [FunctionCallback<T, R> converter]) {
    _left = columnWithAlias;
    _condition = ">=";
    _right = "?";
    _addArgument(value, converter);
  }

  SqlCondition.gt(String columnWithAlias, T value,
      [FunctionCallback<T, R> converter]) {
    _left = columnWithAlias;
    _condition = ">";
    _right = "?";
    _addArgument(value, converter);
  }

  SqlCondition.le(String columnWithAlias, T value,
      [FunctionCallback<T, R> converter]) {
    _left = columnWithAlias;
    _condition = "<=";
    _right = "?";
    _addArgument(value, converter);
  }

  _addArgument(T value, [FunctionCallback<T, R> converter]) {
    Object arg = value;
    if (nonNull(converter)) {
      arg = converter(value);
    }
    _arguments.add(arg);
  }

  SqlCondition.or(List<SqlCondition> conditions) {
    _left = "(";
    _condition = conditions.map((e) => '${e.toCondition()}').join(' or ');
    _right = ")";
    _arguments
        .add(conditions.map((e) => e.toArguments()).expand((e) => e).toList());
  }

  /// Value IN condition
  SqlCondition.inSubQuery(String columnWithAlias, SqlBuilder builder) {
    _left = columnWithAlias;
    _condition = "IN";
    _right = "(${builder.toQuery()})";
    _arguments.addAll(builder.toArguments());
  }

  /// Value IN condition
  SqlCondition.inValues(String columnWithAlias, List<T> values,
      [FunctionCallback<T, R> converter]) {
    _left = columnWithAlias;
    _condition = "IN";
    _right = "(" + values.map((e) => '?').join(',') + ")";
    List<Object> args = values;
    if (nonNull(converter)) {
      args = values.map(converter).toList();
    }
    _arguments.addAll(args);
  }

  SqlCondition wrap(String function) {
    _left = "$function($_left)";
    _right = "$function($_right)";
    return this;
  }

  String toCondition() => '$_left $_condition $_right';

  List<Object> toArguments() => _arguments;
}

class SqlColumn {
  final String _tableAlias;
  final String _name;
  final String _alias;
  final bool _distinct;
  final List<String> _functions;

  SqlColumn(this._name,
      [this._tableAlias,
      this._alias,
      this._distinct = false,
      this._functions = const []]);

  SqlColumn tableAlias(String tableAlias) => SqlColumn(
      this._name, tableAlias, this._alias, this._distinct, this._functions);

  SqlColumn alias(String alias) => SqlColumn(
      this._name, this._tableAlias, alias, this._distinct, this._functions);

  SqlColumn distinct() => SqlColumn(
      this._name, this._tableAlias, this._alias, true, this._functions);

  SqlColumnSort sort([SqlSort direction = SqlSort.ASC]) =>
      SqlColumnSort(this, direction);

  SqlColumnSort sortAsc() => sort();

  SqlColumnSort sortDesc() => sort(SqlSort.DESC);

  String get _nameWithTableAlias =>
      (nonNull(_tableAlias) ? '$_tableAlias.' : '') + _name;

  @override
  String toString() {
    var string = _nameWithTableAlias;
    if (_distinct) {
      string = 'DISTINCT $string';
    }
    return string;
  }

  String _toGrouping() {
    return _nameWithTableAlias;
  }
}

class SqlColumnSort {
  final SqlColumn _column;
  final SqlSort _sortDesc;

  SqlColumnSort(this._column, this._sortDesc);

  @override
  String toString() {
    return '${_column._nameWithTableAlias} ${_sortDesc.name}';
  }
}

enum SqlSort {
  ASC, DESC
}

extension SortType on SqlSort {

  String get name {
    switch (this) {
      case SqlSort.ASC:
        return 'asc';
      case SqlSort.DESC:
        return 'desc';
      default:
        return null;
    }
  }
}
