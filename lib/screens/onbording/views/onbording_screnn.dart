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

  final List<Onbord> _onbordData = [
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
      image: "assets/Illustration/Illustration-0.png",
      title: "Segmentasi\nPelanggan",
      description:
          "Pengelompokan karakteristik dan perilaku belanja konsumen dengan K-Means untuk strategi promosi tepat sasaran.",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-1.png",
      title: "Smart Product\nRecommendation",
      description:
          "Menghasilkan rekomendasi produk cerdas secara otomatis berdasarkan analisis support, confidence, dan lift ratio.",
    ),
  ];

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
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
}

class Onbord {
  final String image, title, description;

  Onbord({
    required this.image,
    required this.title,
    this.description = "",
  });
}
