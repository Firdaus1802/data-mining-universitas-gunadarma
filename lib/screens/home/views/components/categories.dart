import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/route/screen_export.dart';
import '../../../../constants.dart';

class CategoryModel {
  final String name;
  final String? svgSrc, route;

  CategoryModel({
    required this.name,
    this.svgSrc,
    this.route,
  });
}

List<CategoryModel> demoCategories = [
  CategoryModel(name: "Semua Kategori"),
  CategoryModel(
      name: "On Sale",
      svgSrc: "assets/icons/Sale.svg",
      route: onSaleScreenRoute),
  CategoryModel(name: "Pria", svgSrc: "assets/icons/Man.svg"),
  CategoryModel(name: "Wanita", svgSrc: "assets/icons/Woman.svg"),
  CategoryModel(
      name: "Anak", svgSrc: "assets/icons/Child.svg", route: kidsScreenRoute),
];

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...List.generate(
            demoCategories.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? defaultPadding : 8,
                right: index == demoCategories.length - 1 ? defaultPadding : 0,
              ),
              child: CategoryBtn(
                category: demoCategories[index].name,
                svgSrc: demoCategories[index].svgSrc,
                isActive: index == _selectedIndex,
                press: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  if (demoCategories[index].route != null) {
                    Navigator.pushNamed(context, demoCategories[index].route!);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBtn extends StatelessWidget {
  const CategoryBtn({
    super.key,
    required this.category,
    this.svgSrc,
    required this.isActive,
    required this.press,
  });

  final String category;
  final String? svgSrc;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            if (svgSrc != null)
              SvgPicture.asset(
                svgSrc!,
                height: 18,
                width: 18,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : const Color(0xFF8E8E93),
                  BlendMode.srcIn,
                ),
              ),
            if (svgSrc != null) const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF1C1C1E),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
