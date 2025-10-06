import 'package:flutter/material.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/services/cart_service.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/wishlist_viewmodel_tmp.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:frontendemart/views/Items/ChooseAddressScreen.dart';
import 'package:frontendemart/views/Items/PDFItemViewerScreen.dart';
import 'package:frontendemart/views/Items/ShowWishlistScreen.dart';
import 'package:frontendemart/views/Ordres/ShowCartScreen.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:widget_zoom/widget_zoom.dart';
import 'package:frontendemart/views/Items/InlineVideoPlayer.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductDetailsScreen extends StatefulWidget {
  final SellerItem item;

  const ProductDetailsScreen({super.key, required this.item});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> 
    with TickerProviderStateMixin 
    {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentImageIndex = 0;
  bool _isFavorite = false;

Color get _primaryColor {
  final config = context.watch<ConfigViewModel>().config;
  if (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty) {
    return Color(int.parse('FF${config.ciPrimaryColor}', radix: 16));
  }
  return const Color(0xFFEE6B33); // fallback
}

Color get _secondaryColor {
  final config = context.watch<ConfigViewModel>().config;
  if (config?.ciSecondaryColor != null && config!.ciSecondaryColor!.isNotEmpty) {
    return Color(int.parse('FF${config.ciSecondaryColor}', radix: 16));
  }
  return const Color(0xFF6366F1); // fallback
}



  List<String> get imageUrls {
    final mainImage = widget.item.photoUrl ?? "https://via.placeholder.com/400";
    return [
      mainImage,
      mainImage, // Tu pourras mettre d'autres images ici
      mainImage,
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    // CORRECTION: Charger toutes les données spécifiques au produit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<ItemsViewModel>(context, listen: false);
      
      // Réinitialiser les données pour éviter l'affichage de données d'un autre produit
      vm.resetProductData();
      
      // Charger les données spécifiques à ce produit
      vm.loadDatasheets(widget.item.medicineID);
      vm.loadVideos(widget.item.medicineID);
      vm.loadRatings(widget.item.sellerItemID);
    });
  }

  @override
  void dispose()
   {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context)
 {
  return Consumer<ConfigViewModel>(
    builder: (context, configVM, _) {
      final config = configVM.config;

      final primaryColor =
          (config?.ciPrimaryColor != null && config!.ciPrimaryColor.isNotEmpty)
              ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
              : const Color(0xFFEE6B33);

      const backgroundColor = Colors.white;

      return Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              pinned: true,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              title: Text(
                'product_details'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              actions: [
                // ❤️ Toggle favori
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer<WishlistViewModeltep>(
                    builder: (_, wish, __) {
                      final isFav = wish.contains(widget.item);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          wish.toggle(widget.item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFav
                                  ? 'removed_from_wishlist'.tr()
                                  : 'added_to_wishlist'.tr()),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

      



                // 🛒 Aller au panier (et ajouter l’item courant)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart,
                        color: Colors.white, size: 22),
                    onPressed: () {
                      final selected =
                          SellerItem.fromJson(widget.item.toJson())..qty = 1;

                      // ajoute au panier partagé
                      context.read<CartViewModel>().add(selected);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('add_to_cart'.tr()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShowCartScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ---- Contenu ----
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Passe la couleur au builder (évite variable hors portée)
                  _buildImageGalleryModern(),

                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                _buildProductInfoModern(),
                                _buildRatingsSection(),
                                const SizedBox(height: 20),
                                _buildPriceSectionModern(),
                                const SizedBox(height: 24),
                                _buildDescriptionModern(),
                                const SizedBox(height: 24),
                                _buildDatasheetsSection(),
                                const SizedBox(height: 24),
                                _buildVideosSection(),
                                const SizedBox(height: 32),
                                _buildActionButtonsModern(
                                  primaryColor: primaryColor,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
                  bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),

      );
    },

  );

} 


  Widget _buildImageGalleryModern() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              height: 350,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: WidgetZoom(
                              heroAnimationTag: "image_$index",
                              zoomWidget: Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
  color: Colors.grey.shade50,
  child: Center(
    child: CircularProgressIndicator(
      color: _primaryColor, // ici on utilise la couleur dynamique
      strokeWidth: 3,
    ),
  ),
);

                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page indicators avec style HomeScreen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: imageUrls.asMap().entries.map((entry) {
                      return Container(
                        width: _currentImageIndex == entry.key ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentImageIndex == entry.key
                              ? _primaryColor
                              : Colors.grey[300],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDatasheetsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "datasheets".tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Consumer<ItemsViewModel>(
          builder: (context, vm, _) {
            if (!vm.isCurrentProduct(widget.item.sellerItemID)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.datasheets.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "no_datasheet".tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: vm.datasheets.map((ds) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(ds.fileName),
                    subtitle: Text(
                      "added_on".tr(
                        args: [ds.createdAt.toLocal().toString().split(" ")[0]],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PDFViewerScreen(url: ds.fileUrl),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildVideosSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text( // 🔹 SUPPRIMER const
              "videos".tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Consumer<ItemsViewModel>(
          builder: (context, vm, _) {
            if (!vm.isCurrentProduct(widget.item.sellerItemID)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.videos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text( // 🔹 Traduction ajoutée
                    "no_videos".tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: vm.videos.map((video) {
                final isWmv = video.fileUrl.toLowerCase().endsWith(".wmv");

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: isWmv
                            ? InkWell(
                                onTap: () async {
                                  final uri = Uri.parse(video.fileUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        color: Colors.red, size: 64),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: InlineVideoPlayer(url: video.fileUrl),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.video_library,
                                color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download,
                                  color: Colors.blue),
                              onPressed: () async {
                                final uri = Uri.parse(video.fileUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}


  Widget _buildProductInfoModern() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text( // 🔹 SUPPRIMER const
              "product_info".tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Nom du produit
        Text(
          widget.item.nameEn,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        // Stars dynamiques (ajouter plus tard si besoin)

        const SizedBox(height: 16),
      ],
    ),
  );
}

  Widget _buildPriceSectionModern() {
  final hasDiscount = widget.item.priceWas != null && widget.item.priceWas! > widget.item.price;
  final discountPercent = hasDiscount
      ? (((widget.item.priceWas! - widget.item.price) / widget.item.priceWas!) * 100).round()
      : 0;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 28),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _primaryColor.withOpacity(0.1),
          _primaryColor.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _primaryColor.withOpacity(0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "price".tr(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "${widget.item.price.toInt()} EGP",
                      style: TextStyle(
                        fontSize: hasDiscount ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor, // couleur primaire appliquée
                      ),
                    ),
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "${widget.item.priceWas?.toInt()} EGP",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildDescriptionModern() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section avec style HomeScreen
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "product_details".tr(), // clé de traduction
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Description blocks avec style moderne
        if ((widget.item.indications ?? '').isNotEmpty)
          _buildDescriptionBlock(
            "indications".tr(),
            widget.item.indications!,
            Icons.medical_services,
          ),

        if ((widget.item.packDescription ?? '').isNotEmpty)
          _buildDescriptionBlock(
            "package".tr(),
            widget.item.packDescription!,
            Icons.inventory_2,
          ),

        if ((widget.item.pamphletEn ?? '').isNotEmpty)
          _buildDescriptionBlock(
            "instructions".tr(),
            widget.item.pamphletEn!,
            Icons.description,
          ),

        // Si aucune description
        if ((widget.item.indications ?? '').isEmpty &&
            (widget.item.packDescription ?? '').isEmpty &&
            (widget.item.pamphletEn ?? '').isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.description_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "no_description".tr(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildDescriptionBlock(String title, String content, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1), // couleur légère du primaire
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _primaryColor, // couleur primaire
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            color: Colors.black87,
            height: 1.5,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}



int _countFor(List<Map<String, dynamic>> dist, int star) {
  final row = _rowFor(dist, star);
  return (row['total'] as num?)?.toInt() ?? 0;
}



// ———————————— Ratings card ————————————
Widget _buildRatingsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Consumer<ItemsViewModel>(
      builder: (context, vm, _) {
        if (!vm.isCurrentProduct(widget.item.sellerItemID)) {
          return const Center(child: CircularProgressIndicator());
        }

        final avgRaw = vm.averageRating.clamp(0, 5).toDouble();
        final avg    = ((avgRaw * 2).round() / 2.0); // arrondi .0/.5
        final total  = vm.totalRatings;

        final full   = avg.floor();
        final half   = (avg - full) >= 0.5;
        final empty  = 5 - full - (half ? 1 : 0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Moyenne
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${avg == avg.floorToDouble() ? avg.toInt() : avg.toStringAsFixed(1)} / 5',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (int i = 0; i < full;  i++)
                            Icon(Icons.star, color: _primaryColor, size: 22),
                          if (half)
                            Icon(Icons.star_half, color: _primaryColor, size: 22),
                          for (int i = 0; i < empty; i++)
                            Icon(Icons.star_border, color: _primaryColor, size: 22),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '($total ${"reviews".tr()})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Distribution 5→1
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        final star  = 5 - i;
                       final row = _rowFor(vm.distribution, star);
  final count = row['total'] ?? 0;
  final ratio = total > 0 ? count / total : 0.0;;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  star,
                                  (_) => Icon(Icons.star, size: 14, color: _primaryColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[300],
                                  color: _primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$count'),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // % recommandé (avec namedArgs %{percent})
              Text(
                'recommend_product'.tr(namedArgs: {'percent': vm.recommendPercent.toString()}),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review, color: Colors.white),
                  label: Text(
                    'add_review'.tr(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddRatingDialog(context, widget.item.sellerItemID),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// Renvoie toujours un Map<String, int> pour éviter l'erreur de type du orElse
Map<String, int> _rowFor(List<Map<String, dynamic>> dist, int star) {
  for (final d in dist) {
    final r = d['Rate'] ?? d['rate'];
    if (r is num && r.toInt() == star) {
      final t = (d['total'] as num?)?.toInt() ?? 0;
      return <String, int>{'Rate': star, 'total': t};
    }
  }
  // valeur par défaut du bon type
  return <String, int>{'Rate': star, 'total': 0};
}

  void _showAddRatingDialog(BuildContext context, int sellerItemId) {
  final vm = Provider.of<ItemsViewModel>(context, listen: false);

  int selectedRating = 5;
  String comment = "";
  bool recommend = false;
  bool posting = false;

  debugPrint("[⭐ Dialog] Open for product=$sellerItemId");

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) {
        return AlertDialog(
          title: Text("add_review".tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Sélection d’étoiles ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final filled = index < selectedRating;
                  return IconButton(
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: _primaryColor,
                    ),
                    onPressed: posting
                        ? null
                        : () {
                            selectedRating = index + 1;
                            debugPrint("[⭐ Dialog] rating selected = $selectedRating");
                            setStateDialog(() {});
                          },
                  );
                }),
              ),
              const SizedBox(height: 16),

              // --- Commentaire ---
              TextField(
                enabled: !posting,
                decoration: InputDecoration(
                  hintText: "comment_optional".tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) {
                  comment = v;
                  // Log succinct pour éviter de spammer avec de longs commentaires
                  if (v.length % 10 == 0) {
                    debugPrint("[⭐ Dialog] comment len = ${v.length}");
                  }
                },
              ),
              const SizedBox(height: 16),

              // --- Recommander ? ---
              Row(
                children: [
                  Checkbox(
                    value: recommend,
                    activeColor: _primaryColor,
                    onChanged: posting
                        ? null
                        : (v) {
                            recommend = v ?? false;
                            debugPrint("[⭐ Dialog] recommend = $recommend");
                            setStateDialog(() {});
                          },
                  ),
                  Expanded(child: Text("recommend_checkbox".tr())),
                ],
              ),
            ],
          ),
          actions: [
            // Annuler
            TextButton(
              onPressed: posting ? null : () {
                debugPrint("[⭐ Dialog] cancel tapped");
                Navigator.of(ctx).maybePop();
              },
              child: Text("cancel".tr()),
            ),

            // Soumettre
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: posting
                  ? null
                  : () async {
                      debugPrint("[⭐ Dialog] submit tapped → rating=$selectedRating, recommend=$recommend");

                      setStateDialog(() => posting = true);
                      try {
                        // 👉 MAJ optimiste + POST : déjà géré dans vm.addRating()
                        final ok = await vm.addRating(
                          sellerItemId,
                          1, // ⚠️ Remplace 1 par l’ID réel de l’utilisateur
                          selectedRating,
                          comment: comment.isNotEmpty ? comment : null,
                          recommend: recommend,
                        );
                        debugPrint("[⭐ Dialog] addRating() → $ok");
                        debugPrint("[⭐ Dialog] after add → avg=${vm.averageRating}, total=${vm.totalRatings}, dist=${vm.distribution}");

                        // Fermer si possible
                        if (Navigator.of(ctx).canPop()) {
                          Navigator.of(ctx).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? "review_added".tr() : "review_error".tr()),
                              backgroundColor: ok ? Colors.green : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e, st) {
                        debugPrint("[⭐ Dialog][ERROR] $e");
                        debugPrint(st.toString());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("review_error".tr()),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setStateDialog(() => posting = false);
                      }
                    },
              child: posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "submit".tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    ),
  );
}



Widget _buildActionButtonsModern({required Color primaryColor}) {
  final color = primaryColor;
  final item = widget.item as SellerItem; // assure-toi que widget.item est bien SellerItem

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Row(
      children: [
        // ❤️ Bouton Favori (connecté au Provider)
        Consumer<WishlistViewModeltep>(
          builder: (context, wish, _) {
            final isFav = wish.contains(item);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFav ? Colors.red.withOpacity(.35) : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: const EdgeInsets.all(16),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? primaryColor : Colors.grey[600], // 👈 couleur primaire ici
                  size: 24,
                ),
                onPressed: () {
                  wish.toggle(item);
                  final msg = isFav
                      ? 'removed_from_wishlist'.tr()
                      : 'added_to_wishlist'.tr();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(width: 16),

        // 🛒 Bouton Add to Cart
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
              label: Text(
                'add_to_cart'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                // clone “propre” + qty = 1 (même logique que ton VM)
                final selected = SellerItem.fromJson(item.toJson())..qty = 1;
                context.read<CartViewModel>().add(selected);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('added_to_cart'.tr()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}



  
}