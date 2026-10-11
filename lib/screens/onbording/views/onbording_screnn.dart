import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/dot_indicators.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';

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
        image: "assets/logo/gunadarma.png",
        title: "Data Mining\nKelompok 4",
        description:
            "Implementasi Algoritma Apriori & K-Means Clustering pada Sistem E-Commerce - Universitas Gunadarma",
      ),
      Onbord(
        image: "assets/Illustration/analytics_3d.jpg",
        title: "Market Basket\nAnalysis",
        description:
            "Mendeteksi pola kombinasi produk yang sering dibeli bersamaan oleh pelanggan menggunakan Algoritma Apriori.",
      ),
      Onbord(
        image: "",
        title: "Segmentasi\nPelanggan",
        description:
            "Pengelompokan karakteristik dan perilaku belanja konsumen dengan K-Means untuk strategi promosi tepat sasaran.",
        customWidget: _buildCustomerSegmentationVisual(),
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
                        Navigator.pushNamed(context, logInScreenRoute);
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
                            Navigator.pushNamed(context, logInScreenRoute);
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

  Widget _buildCustomerSegmentationVisual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.person_3_fill,
                  size: 17,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "K-Means Clustering",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "k = 3 • Euclidean Distance",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 11,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Optimal",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
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
                    flex: 42,
                    child: Container(color: const Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 35,
                    child: Container(color: const Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 23,
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          _buildClusterRow(
            dotColor: const Color(0xFF6366F1),
            title: "Cluster 1: Pelanggan Loyal",
            badgeText: "42% • RFM Tinggi",
            badgeBg: const Color(0xFFEEF2FF),
            badgeFg: const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 6),
          _buildClusterRow(
            dotColor: const Color(0xFF0284C7),
            title: "Cluster 2: Pembeli Rutin",
            badgeText: "35% • Kebutuhan Pokok",
            badgeBg: const Color(0xFFF0F9FF),
            badgeFg: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 6),
          _buildClusterRow(
            dotColor: const Color(0xFFF59E0B),
            title: "Cluster 3: Sensitif Diskon",
            badgeText: "23% • Promo Hunter",
            badgeBg: const Color(0xFFFEF3C7),
            badgeFg: const Color(0xFFD97706),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.chart_pie_fill,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 6),
                Text(
                  "Silhouette Score: 0.74 • Akurasi Tinggi",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterRow({
    required Color dotColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: badgeFg,
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
          color: const Color(0xFFE2E8F0),
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  size: 17,
                  color: Color(0xFFD97706),
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
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Association Rule Mining",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 11,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 3),
                    Text(
                      "Lift 3.25x",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.cart_fill,
                            size: 11,
                            color: Color(0xFF475569),
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
                                color: Color(0xFF0F172A),
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
                    color: Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_right,
                    size: 12,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.star_fill,
                              size: 9,
                              color: Color(0xFF7B1FA2),
                            ),
                            SizedBox(width: 3),
                            Text(
                              "BUNDLING",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7B1FA2),
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
                            color: Color(0xFF5B21B6),
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
                    color: const Color(0xFFF8FAFC),
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
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        "28.4%",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
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
                    color: const Color(0xFFF8FAFC),
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
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        "91.2%",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
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
                color: Color(0xFF7B1FA2),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Penawaran Bundling Otomatis di Kasir",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                "Aktif",
                style: TextStyle(
                  fontFamily: "Plus Jakarta",
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
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
