import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../Items/product_details_screen.dart';

class AllItemsScreen extends StatelessWidget {
  final List items;
  final String title;
  const AllItemsScreen({super.key, required this.items, required this.title});

  @override
  Widget build(BuildContext context) {
  final locale = EasyLocalization.of(context)!.locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFEE6B33),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(item: item),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        color: Colors.grey.shade50,
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.network(
                          item.photoUrl ?? "https://via.placeholder.com/150",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      locale == 'ar' ? item.nameAr ?? item.nameEn : item.nameEn ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${item.price.toInt()} ${tr('egp')}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
