enum GameMode {
  levels,
  daily,
  sprint,
  zen;
  
  bool get allowsUndo => this != GameMode.sprint;
  bool get allowsHint => this == GameMode.levels || this == GameMode.zen;
}
