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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

// 购物车数据模型
class CartItem {
  final String categoryName;
  final String productName;
  final int price;
  int quantity;

  CartItem({
    required this.categoryName,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });
}

// 全局购物车
class Cart {
  static final Cart _instance = Cart._internal();
  factory Cart() => _instance;
  Cart._internal();

  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  void add(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.productName == item.productName,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(item);
    }
  }

  void remove(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  void clear() => _items.clear();
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('瓷砖店铺'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：1 个大方块 (占 2 列)
            _buildRow1(context),
            // 第二行：4 个小方块
            _buildRow2(context),
            // 第三行：1 个宽方块 + 2 个小方块
            _buildRow3(context),
            // 第四行：3 个中方块
            _buildRow4(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
        },
        backgroundColor: Colors.red,
        icon: const Stack(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            Positioned(
              right: 0,
              top: -8,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Text('', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        label: Text('${Cart().totalCount}件', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRow1(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTile(
              context,
              '抛光砖',
              Icons.square,
              Colors.blue,
              height: 160,
              iconSize: 60,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _buildTile(
              context,
              '釉面砖',
              Icons.layers,
              Colors.green,
              height: 160,
              iconSize: 40,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _buildSmallTile(context, '通体砖', Icons.grid_on, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildSmallTile(context, '玻化砖', Icons.blur_on, Colors.purple)),
          const SizedBox(width: 8),
          Expanded(child: _buildSmallTile(context, '马赛克', Icons.apps, Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildSmallTile(context, '大理石', Icons.photo, Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildRow3(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTile(
              context,
              '木纹砖',
              Icons.table_rows,
              Colors.brown,
              height: 80,
              iconSize: 32,
              fontSize: 14,
              isWide: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallTile(context, '水泥砖', Icons.blur_circular, Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallTile(context, '花片', Icons.star, Colors.pink),
          ),
        ],
      ),
    );
  }

  Widget _buildRow4(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: _buildMediumTile(context, '文化石', Icons.landscape, Colors.amber)),
          const SizedBox(width: 8),
          Expanded(child: _buildMediumTile(context, '踢脚线', Icons.crop, Colors.deepOrange)),
          const SizedBox(width: 8),
          Expanded(child: _buildMediumTile(context, '腰线', Icons.horizontal_rule, Colors.cyan)),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    required double height,
    required double iconSize,
    required double fontSize,
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage(categoryName: title))),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: iconSize, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: iconSize, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSmallTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage(categoryName: title))),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage(categoryName: title))),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCartBadge() {
    return Positioned(
      right: 4,
      top: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Text(
          '${Cart().totalCount}',
          style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ProductListPage extends StatelessWidget {
  final String categoryName;

  const ProductListPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 8,
          itemBuilder: (_, index) {
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${categoryName} ${index + 1}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${categoryName}系列',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '规格：800×800mm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '¥${(index + 1) * 80}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                Cart().add(
                                  CartItem(
                                    categoryName: categoryName,
                                    productName: '${categoryName} ${index + 1}',
                                    price: (index + 1) * 80,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '已添加$categoryName ${index + 1}到购物车',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(
                            categoryName: categoryName,
                            productName: '${categoryName} ${index + 1}',
                            price: (index + 1) * 80,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      child: const Text(
                        '查看详情',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final String categoryName;
  final String productName;
  final int price;

  const ProductDetailPage({
    super.key,
    required this.categoryName,
    required this.productName,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 产品图片区域
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 80, color: Colors.grey.shade500),
                    const SizedBox(height: 16),
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 产品信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥$price',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow('分类', categoryName),
                  _buildInfoRow('规格', '800×800mm'),
                  _buildInfoRow('材质', '陶瓷'),
                  _buildInfoRow('产地', '广东佛山'),
                  _buildInfoRow('库存', '有货'),
                  const Divider(height: 32),
                  const Text(
                    '产品描述',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这款${productName}采用优质陶瓷材料，经过高温烧制而成。表面光滑细腻，质地坚硬耐用，适合用于客厅、卧室、厨房等空间的地面和墙面装饰。',
                    style: const TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已添加到购物车')));
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('加入购物车'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('立即购买')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('立即购买'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// 购物车页面
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Cart _cart = Cart();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          if (_cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() => _cart.clear());
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('购物车已清空')));
              },
            ),
        ],
      ),
      body: _cart.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '购物车是空的',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cart.items.length,
                    itemBuilder: (_, index) {
                      final item = _cart.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          title: Text(item.productName),
                          subtitle: Text('¥${item.price} × ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      _cart.remove(index);
                                    }
                                  });
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() => item.quantity++);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _cart.remove(index));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_cart.items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '共${_cart.totalCount}件商品',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              '合计：¥${_cart.totalPrice}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('订单功能开发中...')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('去结算'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
