import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

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

class TeamMember {
  final String name;
  final String npm;
  final String role;
  final String? imagePath;
  final String? developerUrl;
  final String developerType;

  const TeamMember({
    required this.name,
    required this.npm,
    this.role = "",
    this.imagePath,
    this.developerUrl,
    this.developerType = "GitHub",
  });

  TeamMember copyWith({
    String? name,
    String? npm,
    String? role,
    String? imagePath,
    String? developerUrl,
    String? developerType,
    bool clearImage = false,
    bool clearDeveloperUrl = false,
  }) {
    return TeamMember(
      name: name ?? this.name,
      npm: npm ?? this.npm,
      role: role ?? this.role,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      developerUrl: clearDeveloperUrl ? null : (developerUrl ?? this.developerUrl),
      developerType: developerType ?? this.developerType,
    );
  }
}

class AprioriStateManager extends ChangeNotifier {
  static final AprioriStateManager instance = AprioriStateManager._internal();
  AprioriStateManager._internal();

  double _minSupport = 1.0;
  double _minConfidence = 16.0;
  int _scenarioIndex = 0;
  final List<List<String>> _masterTransactions = [];
  final List<List<String>> _transactions = [];
  final List<List<String>> _testTransactions = [];
  final List<AprioriRuleSummary> _rules = [];
  int _totalRulesCount = 0;
  String _userName = "Firdaus Dhuha Prabowo";
  final Map<String, String> _userAccounts = {};
  final List<TeamMember> _teamMembers = [
    const TeamMember(
      name: "Firdaus Dhuha Prabowo",
      npm: "10124497",
    ),
    const TeamMember(
      name: "Bagas Sena Dwi Jatmika",
      npm: "10124237",
    ),
    const TeamMember(
      name: "Fabio Arvin Aeneas",
      npm: "10124402",
    ),
    const TeamMember(
      name: "Farid Hilmy Cordova",
      npm: "10124442",
    ),
    const TeamMember(
      name: "Hesti Setiana",
      npm: "10124563",
    ),
    const TeamMember(
      name: "Nur Bian'Aziza",
      npm: "11124490",
    ),
  ];

  double get minSupport => _minSupport;
  double get minConfidence => _minConfidence;
  int get scenarioIndex => _scenarioIndex;
  List<List<String>> get masterTransactions => List.unmodifiable(_masterTransactions);
  List<List<String>> get transactions => List.unmodifiable(_transactions);
  List<List<String>> get testTransactions => List.unmodifiable(_testTransactions);
  List<AprioriRuleSummary> get rules => List.unmodifiable(_rules);
  int get totalMasterTransactions => _masterTransactions.length;
  int get totalTransactions => _transactions.length;
  int get totalTestTransactions => _testTransactions.length;
  int get totalRules => _totalRulesCount;
  bool get isDataLoaded => _masterTransactions.isNotEmpty || _transactions.isNotEmpty;
  String get userName => _userName;
  List<TeamMember> get teamMembers => List.unmodifiable(_teamMembers);

  TeamMember? get activeMember {
    for (final member in _teamMembers) {
      if (member.name.toLowerCase() == _userName.toLowerCase()) {
        return member;
      }
    }
    if (_teamMembers.isNotEmpty) {
      return _teamMembers.first;
    }
    return null;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_transactions_v2');
      final savedMinSup = prefs.getDouble('saved_min_support');
      final savedMinConf = prefs.getDouble('saved_min_confidence');
      final savedScenario = prefs.getInt('saved_scenario_index');

      if (savedScenario != null && savedScenario >= 0 && savedScenario <= 2) {
        _scenarioIndex = savedScenario;
      }
      if (savedMinSup != null) _minSupport = savedMinSup;
      if (savedMinConf != null) _minConfidence = savedMinConf;

      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        _masterTransactions.clear();
        for (final item in decoded) {
          if (item is List) {
            final row = item.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
            if (row.isNotEmpty) {
              _masterTransactions.add(row);
            }
          }
        }
      }

      if (_masterTransactions.length < 10) {
        _masterTransactions.clear();
        final csvString = await rootBundle.loadString('assets/data/dataset_groceries_1000.csv');
        final lines = csvString.split(RegExp(r'\r?\n'));
        for (final line in lines) {
          final clean = line.trim();
          if (clean.isEmpty) continue;
          final parts = clean.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            _masterTransactions.add(parts);
          }
        }
        if (savedMinSup == null) _minSupport = 1.0;
        if (savedMinConf == null) _minConfidence = 16.0;
      }

      _applyScenarioSplit();
      notifyListeners();
    } catch (_) {
      _applyScenarioSplit();
      notifyListeners();
    }
  }

  void _applyScenarioSplit() {
    _transactions.clear();
    _testTransactions.clear();
    final total = _masterTransactions.length;
    if (total == 0) {
      _computeRulesInternal();
      return;
    }

    if (_scenarioIndex == 1) {
      final trainCount = (total * 0.8).round();
      _transactions.addAll(_masterTransactions.sublist(0, trainCount));
      _testTransactions.addAll(_masterTransactions.sublist(trainCount));
    } else if (_scenarioIndex == 2) {
      final trainCount = (total * 0.7).round();
      _transactions.addAll(_masterTransactions.sublist(0, trainCount));
      _testTransactions.addAll(_masterTransactions.sublist(trainCount));
    } else {
      _transactions.addAll(_masterTransactions);
    }
    _computeRulesInternal();
  }

  void setScenarioIndex(int index) {
    if (_scenarioIndex != index && index >= 0 && index <= 2) {
      _scenarioIndex = index;
      _applyScenarioSplit();
      _saveToPrefs();
      notifyListeners();
    }
  }

  void _computeRulesInternal() {
    final int totalTrans = _transactions.length;
    if (totalTrans == 0) {
      _rules.clear();
      _totalRulesCount = 0;
      return;
    }

    final Map<String, int> itemCounts = {};
    for (final trans in _transactions) {
      for (final item in trans.toSet()) {
        itemCounts[item] = (itemCounts[item] ?? 0) + 1;
      }
    }

    final Map<String, int> pairCounts = {};
    for (final trans in _transactions) {
      final list = trans.toSet().toList();
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          final a = list[i];
          final b = list[j];
          final key = a.compareTo(b) < 0 ? '$a|||$b' : '$b|||$a';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final List<AprioriRuleSummary> newRules = [];
    pairCounts.forEach((key, countBoth) {
      final parts = key.split('|||');
      final itemA = parts[0];
      final itemB = parts[1];

      final countA = itemCounts[itemA] ?? 1;
      final countB = itemCounts[itemB] ?? 1;

      final double supportBoth = (countBoth / totalTrans) * 100.0;
      final double confAtoB = (countBoth / countA) * 100.0;
      final double suppB = (countB / totalTrans) * 100.0;
      final double liftAtoB = suppB > 0 ? (confAtoB / suppB) : 0.0;

      if (supportBoth >= _minSupport && confAtoB >= _minConfidence) {
        newRules.add(AprioriRuleSummary(
          antecedent: itemA,
          consequent: itemB,
          confidence: confAtoB,
          support: supportBoth,
          lift: liftAtoB,
        ));
      }

      final double confBtoA = (countBoth / countB) * 100.0;
      final double suppA = (countA / totalTrans) * 100.0;
      final double liftBtoA = suppA > 0 ? (confBtoA / suppA) : 0.0;

      if (supportBoth >= _minSupport && confBtoA >= _minConfidence) {
        newRules.add(AprioriRuleSummary(
          antecedent: itemB,
          consequent: itemA,
          confidence: confBtoA,
          support: supportBoth,
          lift: liftBtoA,
        ));
      }
    });

    newRules.sort((a, b) {
      final cmp = b.confidence.compareTo(a.confidence);
      if (cmp != 0) return cmp;
      return b.lift.compareTo(a.lift);
    });

    _rules.clear();
    _rules.addAll(newRules);
    _totalRulesCount = newRules.length;
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_transactions_v2', jsonEncode(_masterTransactions));
      await prefs.setDouble('saved_min_support', _minSupport);
      await prefs.setDouble('saved_min_confidence', _minConfidence);
      await prefs.setInt('saved_scenario_index', _scenarioIndex);
    } catch (_) {}
  }

  void setUserName(String name) {
    _userName = name.trim();
    notifyListeners();
  }

  void addTeamMember(String name, String npm, String role, {String? imagePath}) {}

  void updateTeamMember(
    int index, {
    String? name,
    String? npm,
    String? role,
    String? imagePath,
    String? developerUrl,
    String? developerType,
    bool clearImage = false,
    bool clearDeveloperUrl = false,
  }) {}

  void updateMemberPhoto(int index, String? newImagePath) {}

  void updateActiveProfilePhoto(String? newImagePath) {}

  void removeTeamMember(int index) {}

  void setActiveProfile(String name) {
    setUserName(name);
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
    List<List<String>>? masterTransactions,
    int? scenarioIndex,
  }) {
    if (masterTransactions != null) {
      _masterTransactions.clear();
      _masterTransactions.addAll(masterTransactions);
    } else if (_masterTransactions.isEmpty) {
      _masterTransactions.clear();
      _masterTransactions.addAll(transactions);
    }
    if (scenarioIndex != null && scenarioIndex >= 0 && scenarioIndex <= 2) {
      _scenarioIndex = scenarioIndex;
    }
    _transactions.clear();
    _transactions.addAll(transactions);
    _totalRulesCount = rulesCount;
    _minSupport = minSupport;
    _minConfidence = minConfidence;
    _rules.clear();
    if (rules != null) {
      _rules.addAll(rules);
    } else {
      _computeRulesInternal();
    }
    _saveToPrefs();
    notifyListeners();
  }

  void updateParameters(double minSup, double minConf) {
    _minSupport = minSup;
    _minConfidence = minConf;
    _computeRulesInternal();
    _saveToPrefs();
    notifyListeners();
  }

  void setRulesCount(int count) {
    if (_totalRulesCount != count) {
      _totalRulesCount = count;
      notifyListeners();
    }
  }

  void setTransactions(List<List<String>> newTransactions) {
    _masterTransactions.clear();
    _masterTransactions.addAll(newTransactions);
    _applyScenarioSplit();
    _saveToPrefs();
    notifyListeners();
  }

  void addTransaction(List<String> items) {
    _masterTransactions.add(List<String>.from(items));
    _applyScenarioSplit();
    _saveToPrefs();
    notifyListeners();
  }

  void removeTransaction(int index) {
    if (index >= 0 && index < _masterTransactions.length) {
      _masterTransactions.removeAt(index);
      _applyScenarioSplit();
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearAll() {
    _masterTransactions.clear();
    _transactions.clear();
    _testTransactions.clear();
    _totalRulesCount = 0;
    _rules.clear();
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> resetToDefaultDataset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_transactions_v1');
      await prefs.remove('saved_transactions_v2');
      await prefs.remove('saved_min_support');
      await prefs.remove('saved_min_confidence');
      await prefs.remove('saved_scenario_index');
      _masterTransactions.clear();
      _transactions.clear();
      _testTransactions.clear();
      _scenarioIndex = 0;
      await init();
    } catch (_) {}
  }
}
