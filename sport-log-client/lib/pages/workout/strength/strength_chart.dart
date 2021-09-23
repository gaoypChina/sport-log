import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter_state.dart';
import 'package:sport_log/pages/workout/strength/charts/all.dart';

import 'charts/series_type.dart';

class StrengthChart extends StatefulWidget {
  StrengthChart({
    Key? key,
    required this.dateFilter,
    required this.movement,
  })  : availableSeries = getAvailableSeries(movement.unit),
        super(key: key);

  final DateFilter dateFilter;
  final Movement movement;
  final List<SeriesType> availableSeries;

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  @override
  void didUpdateWidget(StrengthChart oldWidget) {
    if (oldWidget.movement.id != widget.movement.id) {
      setState(() {
        _activeSeriesType = widget.availableSeries.first;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _seriesSelection,
        AspectRatio(
          aspectRatio: 1.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 10, 20),
            child: _chart,
          ),
        ),
      ],
    );
  }

  late SeriesType _activeSeriesType;

  @override
  void initState() {
    super.initState();
    _activeSeriesType = widget.availableSeries.first;
  }

  Widget get _chart {
    if (widget.dateFilter is DayFilter) {
      return DayChart(
        series: _activeSeriesType,
        date: (widget.dateFilter as DayFilter).start,
        movement: widget.movement,
      );
    }
    if (widget.dateFilter is WeekFilter) {
        return WeekChart(
            series: _activeSeriesType,
            start: (widget.dateFilter as WeekFilter).start,
            movement: widget.movement);
    }
    if (widget.dateFilter is MonthFilter) {
        return MonthChart(
          series: _activeSeriesType,
          start: (widget.dateFilter as MonthFilter).start,
          movement: widget.movement,
        );
    }
    if (widget.dateFilter is YearFilter) {
        return YearChart(
          series: _activeSeriesType,
          start: (widget.dateFilter as YearFilter).start,
          movement: widget.movement,
        );
    }
    return AllChart(
      series: _activeSeriesType,
      movement: widget.movement,
    );
  }

  Widget get _seriesSelection {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widget.availableSeries.map((s) {
        final selected = s == _activeSeriesType;
        return OutlinedButton(
          onPressed: () {
            setState(() => _activeSeriesType = s);
          },
          child: Text(s.toDisplayName(widget.movement.unit)),
          style: selected
              ? OutlinedButton.styleFrom(
                  backgroundColor: primaryColorOf(context),
                  primary: onPrimaryColorOf(context),
                )
              : OutlinedButton.styleFrom(
                  side: BorderSide.none,
                ),
        );
      }).toList(),
    );
  }
}
