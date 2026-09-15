class VisualizerPhysics {
  static void updateHeights({
    required int barCount,
    required List<double> targetHeights,
    required List<double> currentHeights,
    required List<double> dotHeights,
    required List<double> dotVelocities,
    required double attack,
    required double release,
    required double gravity,
    required double bounce,
    required Function() onRepaintNeeded,
  }) {
    bool needsRepaint = false;

    for (int i = 0; i < barCount; i++) {
      double target = targetHeights[i];
      double current = currentHeights[i];
      
      double oldCurrent = current;
      if (target > current) {
        currentHeights[i] += (target - current) * attack;
        needsRepaint = true;
      } else if (current > target) {
        currentHeights[i] += (target - current) * release;
        needsRepaint = true;
      }
      
      if ((currentHeights[i] - target).abs() < 0.001) {
        currentHeights[i] = target;
      }

      if (currentHeights[i] >= dotHeights[i]) {
        dotHeights[i] = currentHeights[i];
        
        // Calculate velocity of impact
        double barVelocity = currentHeights[i] - oldCurrent;
        if (barVelocity > 0) {
          double bounceFactor = (barVelocity * 25.0).clamp(0.0, 2.0);
          dotVelocities[i] = bounce * bounceFactor;
        } else {
          dotVelocities[i] = 0.0;
        }
      } else {
        dotVelocities[i] += gravity;
        dotHeights[i] += dotVelocities[i];
        
        if (dotHeights[i] < currentHeights[i]) {
          dotHeights[i] = currentHeights[i];
          dotVelocities[i] = 0.0;
        }
      }
      if (dotVelocities[i] != 0.0 || dotHeights[i] > currentHeights[i]) {
        needsRepaint = true;
      }
    }
    
    if (needsRepaint) {
      onRepaintNeeded();
    }
  }
}
