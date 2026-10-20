import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/route/screen_export.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  static const Color primaryPurple = Color(0xFF4A148C);
  static const Color darkText = Color(0xFF0F172A);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color slateSubtle = Color(0xFF94A3B8);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        onNavigateToDataset: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onNavigateToDiscover: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      DiscoverScreen(
        onNavigateToDataset: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
      const AprioriDashboardScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 820;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isDesktop ? 64 : 60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderSubtle,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      "assets/logo/gunadarma.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "AprioriMart",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Web Dashboard",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Text(
                        "Data Mining Kelompok 4 - Universitas Gunadarma",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: slateMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  if (isDesktop) ...[
                    const Spacer(),
                    _buildDesktopNavPill(0, "Beranda", CupertinoIcons.house_fill, CupertinoIcons.house),
                    const SizedBox(width: 6),
                    _buildDesktopNavPill(1, "Simulasi Kasir", CupertinoIcons.compass_fill, CupertinoIcons.compass),
                    const SizedBox(width: 6),
                    _buildDesktopNavPill(2, "Dataset & Apriori", CupertinoIcons.square_stack_3d_up_fill, CupertinoIcons.square_stack_3d_up),
                    const SizedBox(width: 6),
                    _buildDesktopNavPill(3, "Pengaturan & Tim", CupertinoIcons.gear_alt_fill, CupertinoIcons.gear_alt),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Spacer(),
                  ],
                  _buildHeaderButton(
                    icon: CupertinoIcons.search,
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, searchScreenRoute);
                      if (result == 'open_dataset' && mounted) {
                        setState(() {
                          _currentIndex = 2;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: isDesktop ? null : _buildDockedNavigationBar(),
    );
  }

  Widget _buildDesktopNavPill(int index, String title, IconData activeIcon, IconData inactiveIcon) {
    final bool isSelected = _currentIndex == index;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? primaryPurple.withValues(alpha: 0.25) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 15,
              color: isSelected ? primaryPurple : slateMuted,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryPurple : slateMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(38, 38),
      onPressed: onPressed,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: borderSubtle,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildDockedNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, "Home",
                      activeIcon: CupertinoIcons.house_fill,
                      inactiveIcon: CupertinoIcons.house),
                  _buildNavItem(1, "Discover",
                      activeIcon: CupertinoIcons.compass_fill,
                      inactiveIcon: CupertinoIcons.compass),
                  _buildNavItem(2, "Dataset",
                      activeIcon: CupertinoIcons.square_stack_3d_up_fill,
                      inactiveIcon: CupertinoIcons.square_stack_3d_up),
                  _buildNavItem(3, "Settings",
                      activeIcon: CupertinoIcons.gear_alt_fill,
                      inactiveIcon: CupertinoIcons.gear_alt),
                ],
              ),
            ),
          ),
        );
      }

  Widget _buildNavItem(
    int index,
    String label, {
    String? iconSrc,
    IconData? activeIcon,
    IconData? inactiveIcon,
  }) {
    final bool isSelected = _currentIndex == index;
    final IconData? iconData = isSelected ? activeIcon : inactiveIcon;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconData != null
                  ? Icon(
                      iconData,
                      size: 21,
                      color: isSelected ? primaryPurple : slateSubtle,
                    )
                  : SvgPicture.asset(
                      iconSrc!,
                      height: 21,
                      width: 21,
                      colorFilter: ColorFilter.mode(
                        isSelected ? primaryPurple : slateSubtle,
                        BlendMode.srcIn,
                      ),
                    ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryPurple : slateMuted,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
