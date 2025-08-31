import 'package:flutter/material.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/services/cart_service.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:frontendemart/views/Items/ChooseAddressScreen.dart';
import 'package:frontendemart/views/Items/OrderSummaryScreen.dart';
import 'package:frontendemart/views/Items/PDFItemViewerScreen.dart';
import 'package:frontendemart/views/Items/Summary2Screenscreen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:widget_zoom/widget_zoom.dart';
import 'package:frontendemart/views/Items/InlineVideoPlayer.dart';

class ProductDetailsScreen extends StatefulWidget {
  final SellerItem item;

  const ProductDetailsScreen({super.key, required this.item});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> 
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  // Couleurs cohérentes avec HomeScreen
  static const _primaryColor = Color(0xFFEE6B33);
  static const _secondaryColor = Color(0xFF6366F1);
  static const _backgroundColor = Color(0xFFF8FAFC);

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
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header similaire à HomeScreen
          SliverAppBar(
  expandedHeight: 80,
  floating: false,
  pinned: true,
  elevation: 0,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
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
  title: const Text(
    "Product Details",
    style: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    // 🔹 Favori
    Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          setState(() => _isFavorite = !_isFavorite);
        },
      ),
    ),

    // 🔹 Panier
    Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
          );
        },
      ),
    ),
  ],
),


          SliverToBoxAdapter(
            child: Column(
              children: [
                // Image Gallery avec style HomeScreen
                _buildImageGalleryModern(),
                
                // Contenu principal avec animations
                TweenAnimationBuilder(
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
                              _buildActionButtonsModern(),
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
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: _primaryColor,
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
              const Text(
                "Datasheets",
                style: TextStyle(
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
              // CORRECTION: Vérifier si c'est le bon produit
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
                  child: const Center(
                    child: Text(
                      "No datasheet available",
                      style: TextStyle(color: Colors.grey),
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
                        "Added on ${ds.createdAt.toLocal().toString().split(" ")[0]}",
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
              const Text(
                "Videos",
                style: TextStyle(
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
              // CORRECTION: Vérifier si c'est le bon produit
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
                  child: const Center(
                    child: Text(
                      "No videos available",
                      style: TextStyle(color: Colors.grey),
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
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: const BorderRadius.vertical(
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
                                icon: const Icon(Icons.download, color: Colors.blue),
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
            const Text(
              "Product Info",
              style: TextStyle(
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

        // Stars dynamiques par produit
        

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
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Partie prix (prend tout l'espace dispo)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Price",
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
                        "${widget.item.price.toStringAsFixed(2)} EGP",
                        style: TextStyle(
                          fontSize: hasDiscount ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "${widget.item.priceWas?.toStringAsFixed(2)} EGP",
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
                    ]
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
              const Text(
                "Product Details",
                style: TextStyle(
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
            _buildDescriptionBlock("Indications", widget.item.indications!, Icons.medical_services),
          
          if ((widget.item.packDescription ?? '').isNotEmpty)
            _buildDescriptionBlock("Package", widget.item.packDescription!, Icons.inventory_2),
          
          if ((widget.item.pamphletEn ?? '').isNotEmpty)
            _buildDescriptionBlock("Instructions", widget.item.pamphletEn!, Icons.description),

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
                    Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "No description available",
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
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
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

  Widget _buildRatingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Consumer<ItemsViewModel>(
        builder: (context, vm, _) {
          // CORRECTION: Vérifier si c'est le bon produit
          if (!vm.isCurrentProduct(widget.item.sellerItemID)) {
            return const Center(child: CircularProgressIndicator());
          }

          final avg = vm.averageRating.toStringAsFixed(1);
          final totalVotes = vm.totalRatings;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    "$avg / 5",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text("($totalVotes reviews)"),
                ],
              ),
              const SizedBox(height: 16),

              // Distribution des étoiles
              if (vm.distribution.isNotEmpty)
                Column(
                  children: vm.distribution.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text("${d["Rate"]} ★"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: totalVotes > 0
                                  ? (d["total"] / totalVotes)
                                  : 0,
                              backgroundColor: Colors.grey[300],
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text("${d["total"]}", textAlign: TextAlign.end),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),
              Text("👍 Recommend this product: ${vm.recommendPercent}%"),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                icon: const Icon(Icons.rate_review, color: Colors.white),
                label: const Text("Add Review", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showAddRatingDialog(context, widget.item.sellerItemID);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddRatingDialog(BuildContext context, int sellerItemId) {
    final vm = Provider.of<ItemsViewModel>(context, listen: false);
    int selectedRating = 5;
    String comment = "";
    bool recommend = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Comment field
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Your comment (optional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => comment = val,
                  ),

                  const SizedBox(height: 16),

                  // Recommendation checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: recommend,
                        onChanged: (val) {
                          setStateDialog(() {
                            recommend = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text("I recommend this product"),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  child: const Text("Submit", style: TextStyle(color: Colors.white)),
                  onPressed: () async {
                    final success = await vm.addRating(
                      sellerItemId,
                      1, // TODO: Replace with actual user ID
                      selectedRating,
                      comment: comment.isNotEmpty ? comment : null,
                      recommend: recommend,
                    );

                    Navigator.pop(ctx);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? "Review added successfully!"
                              : "Error adding review"),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtonsModern() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
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
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey[600],
                size: 24,
              ),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
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
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                label: const Text(
                  "Add to Cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              onPressed: () async 
              {
  final selectedAddress = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChooseAddressScreen()),
  );

  if (selectedAddress != null) {
    final items = await CartService.getCartItems();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Summary2Screen(
          items: items,
          selectedAddress: selectedAddress,
        ),
      ),
    );
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