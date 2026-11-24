enum AppDestination {
  summary('/'),
  results('/results'),
  documents('/documents'),
  labs('/labs'),
  doctors('/doctors'),
  profile('/profile'),
  sharing('/sharing'),
  settings('/settings');

  const AppDestination(this.path);
  final String path;
}
