import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/dot_indicators.dart';
import 'package:shop/constants.dart';
import 'package:shop/entry_point.dart';

import 'components/onbording_content.dart';

class OnBordingScreen extends StatefulWidget {
  const OnBordingScreen({super.key});

  @override
  State<OnBordingScreen> createState() => _OnBordingScreenState();
}

class _OnBordingScreenState extends State<OnBordingScreen> {
  late PageController _pageController;
  int _pageIndex = 0;
  late final List<Onbord> _onbordData;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _onbordData = [
      Onbord(
        image: "",
        title: "Market Basket\nAnalysis",
        description:
            "Mendeteksi pola kombinasi produk yang sering dibeli bersamaan oleh pelanggan menggunakan Algoritma Apriori.",
        customWidget: _buildMarketBasketVisual(),
      ),
      Onbord(
        image: "",
        title: "Frequent Itemset\nMining",
        description:
            "Ekstraksi kombinasi itemset yang sering dibeli bersamaan (L1, L2, L3) berdasarkan ambang batas Minimum Support.",
        customWidget: _buildFrequentItemsetVisual(),
      ),
      Onbord(
        image: "",
        title: "Smart Product\nRecommendation",
        description:
            "Menghasilkan rekomendasi produk cerdas secara otomatis berdasarkan analisis support, confidence, dan lift ratio.",
        customWidget: _buildRecommendationVisual(),
      ),
    ];
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          CupertinoPageRoute(
                            settings: const RouteSettings(name: '/'),
                            builder: (context) => const EntryPoint(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _onbordData.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (value) {
                    setState(() {
                      _pageIndex = value;
                    });
                  },
                  itemBuilder: (context, index) => OnbordingContent(
                    title: _onbordData[index].title,
                    description: _onbordData[index].description,
                    image: _onbordData[index].image,
                    isActive: _pageIndex == index,
                    customWidget: _onbordData[index].customWidget,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Row(
                  children: [
                    ...List.generate(
                      _onbordData.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: defaultPadding / 4),
                        child: DotIndicator(isActive: index == _pageIndex),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_pageIndex < _onbordData.length - 1) {
                            _pageController.nextPage(
                              curve: Curves.ease,
                              duration: defaultDuration,
                            );
                          } else {
                            Navigator.pushAndRemoveUntil(
                              context,
                              CupertinoPageRoute(
                                settings: const RouteSettings(name: '/'),
                                builder: (context) => const EntryPoint(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: SvgPicture.asset(
                          "assets/icons/Arrow - Right.svg",
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketBasketVisual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.cart_fill,
                  size: 16,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Market Basket Analysis",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      "Algoritma Apriori Mining",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 11,
                      color: Color(0xFF1C1C1E),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Siap Komputasi",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: Container(color: const Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 32,
                    child: Container(color: const Color(0xFF475569)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 18,
                    child: Container(color: const Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          _buildItemsetRow(
            dotColor: const Color(0xFF1C1C1E),
            levelText: "Data",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF1C1C1E),
            itemsText: "Struk Transaksi Konsumen",
            supportText: "Dataset Aktif",
          ),
          const SizedBox(height: 6),
          _buildItemsetRow(
            dotColor: const Color(0xFF475569),
            levelText: "Pola",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF475569),
            itemsText: "Antecedent → Consequent",
            supportText: "Kombinasi Item",
          ),
          const SizedBox(height: 6),
          _buildItemsetRow(
            dotColor: const Color(0xFF8E8E93),
            levelText: "Hasil",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF1C1C1E),
            itemsText: "Aturan Asosiasi Penjualan",
            supportText: "Lift > 1.0",
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.cube_box_fill,
                  size: 12,
                  color: Color(0xFF475569),
                ),
                SizedBox(width: 6),
                Text(
                  "Sistem Analisis Transaksi Universitas Gunadarma",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentItemsetVisual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.square_stack_3d_up_fill,
                  size: 16,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Frequent Itemsets",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      "Pembentukan L1 • L2 • L3",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 11,
                      color: Color(0xFF1C1C1E),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Min Sup ≥ 20%",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: 48,
                    child: Container(color: const Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 32,
                    child: Container(color: const Color(0xFF475569)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 20,
                    child: Container(color: const Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          _buildItemsetRow(
            dotColor: const Color(0xFF1C1C1E),
            levelText: "L1",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF1C1C1E),
            itemsText: "{Kopi}, {Gula}, {Susu}",
            supportText: "Sup 48%",
          ),
          const SizedBox(height: 6),
          _buildItemsetRow(
            dotColor: const Color(0xFF475569),
            levelText: "L2",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF475569),
            itemsText: "{Kopi, Gula}, {Roti, Selai}",
            supportText: "Sup 35%",
          ),
          const SizedBox(height: 6),
          _buildItemsetRow(
            dotColor: const Color(0xFF8E8E93),
            levelText: "L3",
            levelBg: const Color(0xFFF2F2F7),
            levelFg: const Color(0xFF1C1C1E),
            itemsText: "{Kopi, Gula, Susu Kental}",
            supportText: "Sup 24%",
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  size: 12,
                  color: Color(0xFF475569),
                ),
                SizedBox(width: 6),
                Text(
                  "Pruning Apriori: Eliminasi Frekuensi Rendah",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsetRow({
    required Color dotColor,
    required String levelText,
    required Color levelBg,
    required Color levelFg,
    required String itemsText,
    required String supportText,
  }) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: levelBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            levelText,
            style: TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: levelFg,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            itemsText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            supportText,
            style: const TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationVisual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  size: 16,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Smart Cross-Selling",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    Text(
                      "Association Rule Mining",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 11,
                      color: Color(0xFF1C1C1E),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Lift 3.25x",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DI KERANJANG",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.cart_fill,
                            size: 11,
                            color: Color(0xFF1C1C1E),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Kopi + Gula",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_right,
                    size: 12,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.star_fill,
                              size: 9,
                              color: Color(0xFF1C1C1E),
                            ),
                            SizedBox(width: 3),
                            Text(
                              "BUNDLING",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Susu Kental Manis",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Support",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Text(
                        "28.4%",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confidence",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Text(
                        "91.2%",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 13,
                color: Color(0xFF1C1C1E),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Penawaran Bundling Otomatis di Kasir",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3C),
                  ),
                ),
              ),
              Text(
                "Aktif",
                style: TextStyle(
                  fontFamily: "Plus Jakarta",
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Onbord {
  final String image, title, description;
  final Widget? customWidget;

  Onbord({
    required this.image,
    required this.title,
    this.description = "",
    this.customWidget,
  });
}
