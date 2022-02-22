import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';

import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class WeekChart extends StatefulWidget {
  WeekChart({
    Key? key,
    required this.series,
    required DateTime start,
    required this.movement,
  })  : start = start.beginningOfWeek(),
        super(key: key);

  final SeriesType series;
  final DateTime start;
  final Movement movement;

  @override
  State<WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<WeekChart> {
  final _dataProvider = StrengthSessionDescriptionDataProvider.instance;

  List<StrengthSessionStats> _strengthSessionStats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _update();
  }

  Future<void> _update() async {
    final strengthSessionStats = await _dataProvider.getStatsAggregationsByDay(
      movementId: widget.movement.id,
      from: widget.start,
      until: widget.start.weekLater(),
    );
    assert(strengthSessionStats.length <= 7);
    if (mounted) {
      setState(() => _strengthSessionStats = strengthSessionStats);
    }
  }

  @override
  void didUpdateWidget(WeekChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.start != widget.start) {
      _update();
    }
  }

  List<BarChartGroupData> get _barData {
    final getValue = statsAccessor(widget.series);
    final result = <BarChartGroupData>[];

    var index = 0;
    for (int i = 0; i < 7; ++i) {
      if (index < _strengthSessionStats.length &&
          _strengthSessionStats[index]
              .datetime
              .isOnDay(widget.start.add(Duration(days: i)))) {
        result.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            y: getValue(_strengthSessionStats[index]),
            colors: [primaryColorOf(context)],
          )
        ]));
        ++index;
      } else {
        result.add(BarChartGroupData(x: i, barRods: [BarChartRodData(y: 0)]));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isTime = widget.movement.dimension == MovementDimension.time;
    return BarChart(BarChartData(
      barGroups: _barData,
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          interval: null,
          showTitles: true,
          reservedSize: isTime ? 60 : 40,
          getTitles: isTime
              ? (value) =>
                  formatDurationShort(Duration(milliseconds: value.round()))
              : null,
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          getTitles: (value) => shortWeekdayName(value.round() + 1),
        ),
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
      ),
      gridData: FlGridData(
        getDrawingHorizontalLine: gridLineDrawer(context),
        getDrawingVerticalLine: gridLineDrawer(context),
      ),
    ));
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }
}
