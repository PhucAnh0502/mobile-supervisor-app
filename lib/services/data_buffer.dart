class DataBuffer {
  DataBuffer._();
  static final DataBuffer _instance = DataBuffer._();
  factory DataBuffer() => _instance;

  Map<String, dynamic>? _latest;
  DateTime? _updatedAt;

  Map<String, dynamic>? get latest => _latest == null ? null : Map<String, dynamic>.from(_latest!);
  DateTime? get updatedAt => _updatedAt;

  void update(Map<String, dynamic> data) {
    _latest = Map<String, dynamic>.from(data);
    _updatedAt = DateTime.now();
  }

  void clear() {
    _latest = null;
    _updatedAt = null;
  }
}
