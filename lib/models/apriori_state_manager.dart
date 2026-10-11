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
    required this.role,
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

  double _minSupport = 10.0;
  double _minConfidence = 50.0;
  final List<List<String>> _transactions = [];
  final List<AprioriRuleSummary> _rules = [];
  int _totalRulesCount = 0;
  String _userName = "Firdaus Dhuha Prabowo";
  final Map<String, String> _userAccounts = {};
  final List<TeamMember> _teamMembers = [
    const TeamMember(
      name: "Firdaus Dhuha Prabowo",
      npm: "10124497",
      role: "Ketua Kelompok & Lead Researcher",
    ),
    const TeamMember(
      name: "Bagas Sena Dwi Jatmika",
      npm: "10124237",
      role: "Algoritma Apriori & Data Engine",
    ),
    const TeamMember(
      name: "Fabio Arvin Aeneas",
      npm: "10124402",
      role: "Frontend UI/UX & Mobile Developer",
    ),
    const TeamMember(
      name: "Farid Hilmy Cordova",
      npm: "10124442",
      role: "Data Mining Analyst & Preprocessing",
    ),
    const TeamMember(
      name: "Hesti Setiana",
      npm: "10124563",
      role: "Business Intelligence & Evaluation",
    ),
    const TeamMember(
      name: "Nur Bian'Aziza",
      npm: "11124490",
      role: "Dokumentasi Riset & Presentasi",
    ),
  ];

  double get minSupport => _minSupport;
  double get minConfidence => _minConfidence;
  List<List<String>> get transactions => List.unmodifiable(_transactions);
  List<AprioriRuleSummary> get rules => List.unmodifiable(_rules);
  int get totalTransactions => _transactions.length;
  int get totalRules => _totalRulesCount;
  bool get isDataLoaded => _transactions.isNotEmpty;
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

