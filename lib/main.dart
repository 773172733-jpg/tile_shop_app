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
class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int size; // 1=小，2=中，3=大

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.size = 2,
  });
}

// 首页 - Windows Phone 风格磁贴
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  // 分类列表
  static List<Category> getCategories() {
    return [
      Category(id: '1', name: '瓷砖', icon: '🏠', color: '#2196F3', size: 3),
      Category(id: '2', name: '岩板', icon: '🪨', color: '#9C27B0', size: 2),
      Category(id: '3', name: '仿古砖', icon: '🏺', color: '#795548', size: 2),
      Category(id: '4', name: '木纹砖', icon: '🪵', color: '#8D6E63', size: 2),
      Category(id: '5', name: '花片', icon: '🌸', color: '#E91E63', size: 1),
      Category(id: '6', name: '辅材', icon: '🔧', color: '#607D8B', size: 1),
      Category(id: '7', name: '新品', icon: '✨', color: '#FF5722', size: 1),
      Category(id: '8', name: '促销', icon: '💰', color: '#F44336', size: 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = HomePage.getCategories();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 4, // 4 列网格
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: categories.map((category) {
            return _buildTile(context, category);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, Category category) {
    // 根据 size 决定占用的行列数
    int rowSpan = category.size;
    int colSpan = category.size;

    Color tileColor;
    try {
      tileColor = HexColor.fromHex(category.color);
    } catch (e) {
      tileColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        // 跳转到产品列表页
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
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // 图标
            Positioned(
              top: 8,
              left: 8,
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            // 名称
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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

// 瓷砖数据模型
class TileProduct {
  final String id;
  final String name;      // 型号名称
  final String spec;      // 规格（如 800x800）
  final double price;     // 价格
  final String? imageUrl; // 图片 URL

  TileProduct({
    required this.id,
    required this.name,
    required this.spec,
    required this.price,
    this.imageUrl,
  });
}

class _ProductListPageState extends State<ProductListPage> {
  // 模拟不同分类的产品数据
  Map<String, List<TileProduct>> productsByCategory = {
    '1': [ // 瓷砖
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
    '2': [ // 岩板
      TileProduct(id: '1', name: '雪花白', spec: '1200×2400mm', price: 568.0),
      TileProduct(id: '2', name: '鱼肚金', spec: '1200×2400mm', price: 598.0),
      TileProduct(id: '3', name: '劳伦黑金', spec: '1200×2400mm', price: 628.0),
      TileProduct(id: '4', name: '亚马逊绿', spec: '1200×2400mm', price: 688.0),
    ],
    '3': [ // 仿古砖
      TileProduct(id: '1', name: '复古灰', spec: '600×600mm', price: 88.0),
      TileProduct(id: '2', name: '田园米黄', spec: '600×600mm', price: 92.0),
      TileProduct(id: '3', name: '欧式咖色', spec: '600×600mm', price: 98.0),
      TileProduct(id: '4', name: '美式乡村', spec: '500×500mm', price: 78.0),
    ],
    '4': [ // 木纹砖
      TileProduct(id: '1', name: '北美胡桃', spec: '150×800mm', price: 128.0),
      TileProduct(id: '2', name: '欧洲橡木', spec: '150×800mm', price: 136.0),
      TileProduct(id: '3', name: '亚洲柚木', spec: '200×1000mm', price: 158.0),
      TileProduct(id: '4', name: '非洲花梨', spec: '200×1000mm', price: 168.0),
    ],
    '5': [ // 花片
      TileProduct(id: '1', name: '樱花', spec: '300×300mm', price: 28.0),
      TileProduct(id: '2', name: '牡丹', spec: '300×300mm', price: 32.0),
      TileProduct(id: '3', name: '荷花', spec: '300×300mm', price: 30.0),
    ],
    '6': [ // 辅材
      TileProduct(id: '1', name: '美缝剂', spec: '支', price: 45.0),
      TileProduct(id: '2', name: '瓷砖胶', spec: '袋', price: 68.0),
      TileProduct(id: '3', name: '找平器', spec: '个', price: 2.5),
      TileProduct(id: '4', name: '十字卡', spec: '包', price: 15.0),
    ],
    '7': [ // 新品
      TileProduct(id: '1', name: '星空灰', spec: '800×800mm', price: 258.0),
      TileProduct(id: '2', name: '流光金', spec: '800×800mm', price: 288.0),
    ],
    '8': [ // 促销
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
          // 顶部提示
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
          // 9 宫格网格
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

  // 构建单个瓷砖卡片
  Widget _buildTileCard(TileProduct tile) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 产品图片区域
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
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
          // 产品信息区域
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

  // 默认图片（占位图）
  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
      ),
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.grey.shade500,
      ),
    );
  }
}

// 颜色扩展
extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
