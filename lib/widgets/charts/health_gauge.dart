import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

/// Circular gauge widget showing crop health percentage
class HealthGauge extends StatelessWidget {
  final double healthPercentage;
  final double size;

  const HealthGauge({
    super.key,
    required this.healthPercentage,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 100,
            showLabels: false,
            showTicks: false,
            startAngle: 135,
            endAngle: 45,
            radiusFactor: 0.9,
            axisLineStyle: AxisLineStyle(
              thickness: 0.15,
              thicknessUnit: GaugeSizeUnit.factor,
              color: Colors.grey[300],
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: healthPercentage,
                width: 0.15,
                sizeUnit: GaugeSizeUnit.factor,
                gradient: SweepGradient(
                  colors: _getGradientColors(),
                  stops: const [0.0, 0.5, 1.0],
                ),
                cornerStyle: CornerStyle.bothCurve,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${healthPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: _getHealthColor(),
                      ),
                    ),
                    Text(
                      _getHealthLabel(),
                      style: TextStyle(
                        fontSize: size * 0.1,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                angle: 90,
                positionFactor: 0.0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (healthPercentage >= 70) {
      return [Colors.green[300]!, Colors.green, Colors.green[700]!];
    } else if (healthPercentage >= 40) {
      return [Colors.yellow[300]!, Colors.orange, Colors.orange[700]!];
    } else {
      return [Colors.red[300]!, Colors.red, Colors.red[700]!];
    }
  }

  Color _getHealthColor() {
    if (healthPercentage >= 70) {
      return Colors.green;
    } else if (healthPercentage >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getHealthLabel() {
    if (healthPercentage >= 70) {
      return 'ممتاز';
    } else if (healthPercentage >= 40) {
      return 'متوسط';
    } else {
      return 'ضعيف';
    }
  }
}





