class LibboxCmd {
  static const log = 0;
  static const status = 1;
  static const serviceReload = 2;
  static const serviceClose = 3;
  static const closeConnections = 4;
  static const group = 5;
  static const selectOutbound = 6;
  static const urlTest = 7;
  static const groupExpand = 8; // ← «активные группы» с url-test-delay
  static const clashMode = 9;
  static const setClashMode = 10;
  static const getSystemProxyStatus = 11;
  static const setSystemProxyEnabled = 12;
  static const connections = 13;
  static const closeConnection = 14;
  static const getDeprecatedNotes = 15;
}
