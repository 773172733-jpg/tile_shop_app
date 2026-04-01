import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '瓷砖店铺',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(title: '瓷砖店铺'),
    );
  }
}

// 分类数据模型
class TileCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final TileSize size; // 磁贴大小

  TileCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.size = TileSize.medium,
  });
}

// 磁贴大小枚举
enum TileSize {
  small,    // 小方块 (1x1)
  medium,   // 中方块 (1x2)
  wide,     // 宽方块 (2x1)
  large,    // 大方块 (2x2)
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  // 分类列表 - Windows Phone 风格布局
  List<TileCategory> getCategories() {
    return [
      // 第一行：两个大磁贴
      TileCategory(id: '1', name: '瓷砖', icon: '🏠', color: '#2196F3', size: TileSize.large),
      TileCategory(id: '2', name: '岩板', icon: '🪨', color: '#9C27B0', size: TileSize.large),
      // 第二行：一个宽磁贴 + 两个小磁贴
      TileCategory(id: '3', name: '仿古砖', icon: '🏺', color: '#795548', size: TileSize.wide),
      TileCategory(id: '5', name: '花片', icon: '🌸', color: '#E91E63', size: TileSize.small),
      TileCategory(id: '6', name: '辅材', icon: '🔧', color: '#607D8B', size: TileSize.small),
      // 第三行：两个中方块
      TileCategory(id: '4', name: '木纹砖', icon: '🪵', color: '#8D6E63', size: TileSize.medium),
      TileCategory(id: '7', name: '新品', icon: '✨', color: '#FF5722', size: TileSize.medium),
      // 第四行：促销大磁贴
      TileCategory(id: '8', name: '促销特惠', icon: '💰', color: '#F44336', size: TileSize.large),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = getCategories();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: _buildTileRows(categories),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTileRows(List<TileCategory> categories) {
    List<Widget> rows = [];
    int index = 0;

    // 第一行：2 个大磁贴
    if (index < categories.length) {
      final cat1 = categories[index];
      final cat2 = categories[index + 1];
      rows.add(const SizedBox(height: 12));
      rows.add(Row(
        children: [
          Expanded(child: _buildTile(cat1, isLarge: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildTile(cat2, isLarge: true)),
        ],
      ));
      index += 2;
    }

    // 第二行：宽磁贴 + 两个小磁贴
    if (index < categories.length) {
      final cat1 = categories[index];
      final cat2 = categories[index + 1];
      final cat3 = categories[index + 2];
      rows.add(const SizedBox(height: 12));
      rows.add(Row(
        children: [
          Expanded(flex: 2, child: _buildTile(cat1, isWide: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildTile(cat2, isSmall: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildTile(cat3, isSmall: true)),
        ],
      ));
      index += 3;
    }

    // 第三行：两个中方块
    if (index < categories.length) {
      final cat1 = categories[index];
      final cat2 = categories[index + 1];
      rows.add(const SizedBox(height: 12));
      rows.add(Row(
        children: [
          Expanded(child: _buildTile(cat1, isMedium: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildTile(cat2, isMedium: true)),
        ],
      ));
      index += 2;
    }

    // 第四行：大磁贴
    if (index < categories.length) {
      final cat = categories[index];
      rows.add(const SizedBox(height: 12));
      rows.add(Row(
        children: [
          Expanded(child: _buildTile(cat, isLarge: true)),
        ],
      ));
      index += 1;
    }

    rows.add(const SizedBox(height: 24));
    return rows;
  }

  Widget _buildTile(TileCategory category, {
    bool isSmall = false,
    bool isMedium = false,
    bool isWide = false,
    bool isLarge = false,
  }) {
    Color tileColor;
    try {
      tileColor = HexColor.fromHex(category.color);
    } catch (e) {
      tileColor = Colors.blue;
    }

    double aspectRatio = 1.0;
    if (isSmall) aspectRatio = 1.0;
    if (isMedium) aspectRatio = 2.0;
    if (isWide) aspectRatio = 2.0;
    if (isLarge) aspectRatio = 2.0;

    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListPage(
                  categoryName: category.name,
                  categoryId: category.id,
                ),
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: tileColor,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  // 图标在左上角
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  // 名称在左下角
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 产品列表页 - 9 宫格展示
class ProductListPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const ProductListPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class TileProduct {
  final String id;
  final String name;
  final String spec;
  final double price;
  final String? imageUrl;

  TileProduct({
    required this.id,
    required this.name,
    required this.spec,
    required this.price,
    this.imageUrl,
  });
}

class _ProductListPageState extends State<ProductListPage> {
  Map<String, List<TileProduct>> productsByCategory = {
    '1': [
      TileProduct(id: '1', name: '爵士白', spec: '800×800mm', price: 168.0),
      TileProduct(id: '2', name: '鱼骨纹', spec: '600×1200mm', price: 198.0),
      TileProduct(id: '3', name: '卡拉拉白', spec: '800×800mm', price: 156.0),
      TileProduct(id: '4', name: '深灰石纹', spec: '750×1500mm', price: 228.0),
      TileProduct(id: '5', name: '鱼肚白', spec: '800×800mm', price: 178.0),
      TileProduct(id: '6', name: '劳伦特黑', spec: '800×800mm', price: 188.0),
      TileProduct(id: '7', name: '亚马逊绿', spec: '800×800mm', price: 218.0),
      TileProduct(id: '8', name: '土耳其灰', spec: '750×1500mm', price: 238.0),
      TileProduct(id: '9', name: '雪山银狐', spec: '800×800mm', price: 208.0),
    ],
    '2': [
      TileProduct(id: '1', name: '雪花白', spec: '1200×2400mm', price: 568.0),
      TileProduct(id: '2', name: '鱼肚金', spec: '1200×2400mm', price: 598.0),
      TileProduct(id: '3', name: '劳伦黑金', spec: '1200×2400mm', price: 628.0),
      TileProduct(id: '4', name: '亚马逊绿', spec: '1200×2400mm', price: 688.0),
    ],
    '3': [
      TileProduct(id: '1', name: '复古灰', spec: '600×600mm', price: 88.0),
      TileProduct(id: '2', name: '田园米黄', spec: '600×600mm', price: 92.0),
      TileProduct(id: '3', name: '欧式咖色', spec: '600×600mm', price: 98.0),
      TileProduct(id: '4', name: '美式乡村', spec: '500×500mm', price: 78.0),
    ],
    '4': [
      TileProduct(id: '1', name: '北美胡桃', spec: '150×800mm', price: 128.0),
      TileProduct(id: '2', name: '欧洲橡木', spec: '150×800mm', price: 136.0),
      TileProduct(id: '3', name: '亚洲柚木', spec: '200×1000mm', price: 158.0),
      TileProduct(id: '4', name: '非洲花梨', spec: '200×1000mm', price: 168.0),
    ],
    '5': [
      TileProduct(id: '1', name: '樱花', spec: '300×300mm', price: 28.0),
      TileProduct(id: '2', name: '牡丹', spec: '300×300mm', price: 32.0),
      TileProduct(id: '3', name: '荷花', spec: '300×300mm', price: 30.0),
    ],
    '6': [
      TileProduct(id: '1', name: '美缝剂', spec: '支', price: 45.0),
      TileProduct(id: '2', name: '瓷砖胶', spec: '袋', price: 68.0),
      TileProduct(id: '3', name: '找平器', spec: '个', price: 2.5),
      TileProduct(id: '4', name: '十字卡', spec: '包', price: 15.0),
    ],
    '7': [
      TileProduct(id: '1', name: '星空灰', spec: '800×800mm', price: 258.0),
      TileProduct(id: '2', name: '流光金', spec: '800×800mm', price: 288.0),
    ],
    '8': [
      TileProduct(id: '1', name: '清仓款 A', spec: '600×600mm', price: 39.0),
      TileProduct(id: '2', name: '清仓款 B', spec: '600×600mm', price: 45.0),
      TileProduct(id: '3', name: '特价款 C', spec: '800×800mm', price: 88.0),
    ],
  };

  void shuffleProducts() {
    setState(() {
      final products = productsByCategory[widget.categoryId] ?? [];
      products.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = productsByCategory[widget.categoryId] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: shuffleProducts,
            tooltip: '换一批',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '共 ${products.length} 款 ${widget.categoryName}',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final tile = products[index];
                return _buildTileCard(tile);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加${widget.categoryName}新品')),
          );
        },
        icon: const Icon(Icons.add_a_photo),
        label: Text('录入${widget.categoryName}'),
      ),
    );
  }

  Widget _buildTileCard(TileProduct tile) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              child: tile.imageUrl != null
                  ? Image.network(
                      tile.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultImage();
                      },
                    )
                  : _buildDefaultImage(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tile.spec,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '¥${tile.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade300),
      child: const Icon(Icons.image, size: 48, color: Colors.grey),
    );
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
