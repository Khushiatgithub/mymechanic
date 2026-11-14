import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class BlogArticle {
  final String id;
  final String category;
  final String readTime;
  final String title;
  final String badgeLine1;
  final String badgeLine2;
  final String imageAsset;
  final String fullContent;

  const BlogArticle({
    required this.id,
    required this.category,
    required this.readTime,
    required this.title,
    required this.badgeLine1,
    required this.badgeLine2,
    required this.imageAsset,
    required this.fullContent,
  });
}

/// Horizontal carousel for "Blog Posts & Articles" matching reference screenshot.
class BlogArticlesSection extends StatelessWidget {
  final VoidCallback onBookService;

  const BlogArticlesSection({
    super.key,
    required this.onBookService,
  });

  static const List<BlogArticle> articles = [
    BlogArticle(
      id: 'blog_resale_calc',
      category: 'CAR RESALE',
      readTime: '3 min read',
      badgeLine1: 'CAR RESALE VALUE CALCULATOR',
      badgeLine2: "FIND YOUR USED CAR'S PRICE",
      title: "CAR RESALE VALUE CALCULATOR: FIND YOUR USED CAR'S PRICE",
      imageAsset: AppConstants.blogResaleCalc,
      fullContent:
          'When selling your car, buyers and valuation algorithms look at certified maintenance history first. Having a documented digital service record from an authorized network like MyMechanic ensures you receive top market value.\n\nTop tips to maximize resale value:\n1. Maintain a complete log of periodic oil changes and scheduled inspections.\n2. Fix minor bumper scratches and door dings with quality paint touch-ups.\n3. Keep interior upholstery spotlessly clean with regular deep steam detailing.\n4. Ensure tyres have adequate tread depth and brake pads have at least 50% life.',
    ),
    BlogArticle(
      id: 'blog_number_plate',
      category: 'RC GUIDE',
      readTime: '4 min read',
      badgeLine1: 'VEHICLE NUMBER PLATE',
      badgeLine2: 'HOW TO DECODE YOUR RC',
      title: 'VEHICLE NUMBER PLATE: HOW TO READ & DECODE YOUR RC',
      imageAsset: AppConstants.bannerPeriodicService,
      fullContent:
          'High summer temperatures and dusty conditions cause cabin air filters to clog rapidly, putting heavy strain on your car\'s AC compressor.\n\nEssential maintenance routine:\n1. Check AC refrigerant pressure and wash the external condenser coil.\n2. Inspect wiper blades for rubber hardening before the rainy season.\n3. Check battery fluid and voltage levels — extreme heat accelerates battery degradation faster than cold weather.\n4. Keep coolant levels topped up with manufacturer-recommended ethylene glycol mixture.',
    ),
    BlogArticle(
      id: 'blog_car_spa',
      category: 'CAR SPA',
      readTime: '3 min read',
      badgeLine1: 'DEEP CAR SPA & DETAILING',
      badgeLine2: 'PAINT GLOSS PROTECTION',
      title: 'CAR SPA & DETAILING: KEEP YOUR PAINT PROTECTED',
      imageAsset: AppConstants.bannerCarSpa,
      fullContent:
          'Modern turbocharged engines operate under high pressures and extreme thermal cycles. Over time, engine oil loses viscosity and collects combustion contaminants.\n\nKey takeaways:\n1. Always adhere to the 10,000 km or 1-year service interval, whichever comes first.\n2. Always replace the oil filter alongside engine oil to prevent circulation of trapped debris.\n3. Using OEM-grade synthetic oil ensures tight seal protection and seamless startup lubrication.',
    ),
  ];

  void _openArticleSheet(BuildContext context, BlogArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.readTime,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                article.fullContent,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onBookService();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Explore All Services', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header matching screenshot
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blog Posts & Articles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Get to know your car, a bit more',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openArticleSheet(context, articles.first),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Card Carousel
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildArticleCard(context, article);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(BuildContext context, BlogArticle article) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openArticleSheet(context, article),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Photo
                Image.asset(
                  article.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(Icons.article_rounded, color: Colors.white38, size: 40),
                  ),
                ),

                // Dark Bottom Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black12,
                        Colors.black54,
                        Colors.black87,
                      ],
                      stops: [0.3, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),

                // Top Left: Red Pill Tag with 2 lines
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          article.badgeLine1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          article.badgeLine2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right: Brand Logo
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.directions_car_filled_rounded,
                          color: Color(0xFFEF4444),
                          size: 13,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'MyMechanic',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Title Overlay Text
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
