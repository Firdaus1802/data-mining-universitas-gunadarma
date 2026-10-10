import 'package:flutter/foundation.dart';

class AprioriRuleSummary {
  final String antecedent;
  final String consequent;
  final double confidence;
  final double support;
  final double lift;

  const AprioriRuleSummary({
    required this.antecedent,
    required this.consequent,
    required this.confidence,
    required this.support,
    required this.lift,
  });
}

class AprioriStateManager extends ChangeNotifier {
  static final AprioriStateManager instance = AprioriStateManager._internal();
  AprioriStateManager._internal();

  double _minSupport = 10.0;
  double _minConfidence = 50.0;
  final List<List<String>> _transactions = [];
  final List<AprioriRuleSummary> _rules = [];
  int _totalRulesCount = 0;
  String _userName = "";
  final Map<String, String> _userAccounts = {};

  double get minSupport => _minSupport;
  double get minConfidence => _minConfidence;
  List<List<String>> get transactions => List.unmodifiable(_transactions);
  List<AprioriRuleSummary> get rules => List.unmodifiable(_rules);
  int get totalTransactions => _transactions.length;
  int get totalRules => _totalRulesCount;
  bool get isDataLoaded => _transactions.isNotEmpty;
  String get userName => _userName;

  void setUserName(String name) {
    _userName = name.trim();
    notifyListeners();
  }

  void registerUser(String email, String name) {
    final cleanEmail = email.toLowerCase().trim();
    final cleanName = name.trim();
    if (cleanEmail.isNotEmpty && cleanName.isNotEmpty) {
      _userAccounts[cleanEmail] = cleanName;
    }
    setUserName(cleanName);
  }

  String detectUserName(String email) {
    final cleanEmail = email.toLowerCase().trim();
    if (_userAccounts.containsKey(cleanEmail) && _userAccounts[cleanEmail]!.isNotEmpty) {
      return _userAccounts[cleanEmail]!;
    }
    if (_userName.isNotEmpty) {
      return _userName;
    }
    final parts = cleanEmail.split('@');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      final raw = parts[0].replaceAll('.', ' ').replaceAll('_', ' ');
      final detected = raw
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ')
          .trim();
      if (detected.isNotEmpty) return detected;
    }
    return "Dosen / Pengguna";
  }

  void updateAll({
    required List<List<String>> transactions,
    required int rulesCount,
    required double minSupport,
    required double minConfidence,
    List<AprioriRuleSummary>? rules,
  }) {
    _transactions.clear();
    _transactions.addAll(transactions);
    _totalRulesCount = rulesCount;
    _minSupport = minSupport;
    _minConfidence = minConfidence;
    _rules.clear();
    if (rules != null) {
      _rules.addAll(rules);
    }
    notifyListeners();
  }

  void updateParameters(double minSup, double minConf) {
    _minSupport = minSup;
    _minConfidence = minConf;
    notifyListeners();
  }

  void setRulesCount(int count) {
    if (_totalRulesCount != count) {
      _totalRulesCount = count;
      notifyListeners();
    }
  }

  void setTransactions(List<List<String>> newTransactions) {
    _transactions.clear();
    _transactions.addAll(newTransactions);
    notifyListeners();
  }

  void addTransaction(List<String> items) {
    _transactions.add(List<String>.from(items));
    notifyListeners();
  }

  void removeTransaction(int index) {
    if (index >= 0 && index < _transactions.length) {
      _transactions.removeAt(index);
      notifyListeners();
    }
  }

  void clearAll() {
    _transactions.clear();
    _totalRulesCount = 0;
    _rules.clear();
    notifyListeners();
  }
}

