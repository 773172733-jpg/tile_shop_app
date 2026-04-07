import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:collection';
import 'dart:typed_data';
import 'dart:html' as html hide Image;

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
      home: HomePage(),
    );
  }
}

// ==================== 数据模型 ====================

class User {
  final String username;
  final String password;
  final bool isAdmin;
  final bool isSuperAdmin;
  final String? inviteCode;
  final List<String>? permissions;

  User({
    required this.username,
    required this.password,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.inviteCode,
    this.permissions,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'isAdmin': isAdmin,
    'isSuperAdmin': isSuperAdmin,
    'inviteCode': inviteCode ?? '',
    'permissions': permissions ?? [],
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] ?? '',
    password: json['password'] ?? '',
    isAdmin: json['isAdmin'] ?? false,
    isSuperAdmin: json['isSuperAdmin'] ?? false,
    inviteCode: json['inviteCode'],
    permissions: json['permissions'] != null
        ? List<String>.from(json['permissions'])
        : [],
  );
}

class Category {
  final String id;
  String name;
  final IconData icon;
  final Color color;
  bool isEnabled;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'color': color.value,
    'isEnabled': isEnabled,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: IconData(
      json['icon'] ?? Icons.square.codePoint,
      fontFamily: 'MaterialIcons',
      fontPackage: 'material_icons',
    ),
    color: Color(json['color'] ?? Colors.blue.value),
    isEnabled: json['isEnabled'] ?? true,
  );
}

class Product {
  final String id;
  final String categoryId;
  String name;
  int price;
  String brand;
  String spec;
  String material;
  String origin;
  int stock;
  String? imageUrl;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.brand,
    required this.spec,
    required this.material,
    required this.origin,
    this.stock = 100,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
    'price': price,
    'brand': brand,
    'spec': spec,
    'material': material,
    'origin': origin,
    'stock': stock,
    'imageUrl': imageUrl ?? '',
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    categoryId: json['categoryId'] ?? '',
    name: json['name'] ?? '',
    price: json['price'] ?? 0,
    brand: json['brand'] ?? '',
    spec: json['spec'] ?? '',
    material: json['material'] ?? '',
    origin: json['origin'] ?? '',
    stock: json['stock'] ?? 100,
    imageUrl: json['imageUrl'],
  );
}

class CartItem {
  final String categoryId;
  final String categoryName;
  final String productName;
  final int price;
  int quantity;
  String? brand;

  CartItem({
    required this.categoryId,
    required this.categoryName,
    required this.productName,
    required this.price,
    this.quantity = 1,
    this.brand,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'productName': productName,
    'price': price,
    'quantity': quantity,
    'brand': brand ?? '',
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    categoryId: json['categoryId'] ?? '',
    categoryName: json['categoryName'] ?? '',
    productName: json['productName'] ?? '',
    price: json['price'] ?? 0,
    quantity: json['quantity'] ?? 1,
    brand: json['brand'],
  );
}

class Order {
  final String id;
  final String username;
  final List<CartItem> items;
  final int totalPrice;
  final DateTime createdAt;
  String status;

  Order({
    required this.id,
    required this.username,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'items': items.map((i) => i.toJson()).toList(),
    'totalPrice': totalPrice,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
    totalPrice: json['totalPrice'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    status: json['status'] ?? 'pending',
  );
}

// ==================== 数据管理器 ====================

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 全局购物车变化监听器
  VoidCallback? onCartChanged;

  final List<User> _users = [];
  final List<Category> _categories = [];
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<CartItem> _cartItems = [];

  User? _currentUser;
  String? _currentUserUsername;

  List<User> get users => _users;
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<CartItem> get cartItems => _cartItems;

  // 实时检查当前用户是否为管理员
  bool get isAdminUser =>
      _currentUser != null &&
      (_currentUser!.isAdmin || _currentUser!.isSuperAdmin);
  bool get isSuperUser => _currentUser != null && _currentUser!.isSuperAdmin;

  User? get currentUser => _currentUser;
  String? get currentUserUsername => _currentUserUsername;

  int get totalCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 清除之前的登录记录
    await prefs.remove('currentUser');
    _currentUser = null;
    _currentUserUsername = null;

    // 初始化用户 - 优先从 SharedPreferences 加载，如果没有则从 localStorage 备份恢复
    final usersJson = prefs.getStringList('users');
    if (usersJson != null && usersJson.isNotEmpty) {
      _users.clear();
      for (final userStr in usersJson) {
        _users.add(User.fromJson(json.decode(userStr)));
      }
    } else {
      // 尝试从 localStorage 备份加载
      await _loadUsers();

      // 如果仍然没有数据，创建默认超级管理员
      if (_users.isEmpty) {
        final superAdmin = User(
          username: 'admin',
          password: 'admin',
          isAdmin: true,
          isSuperAdmin: true,
          inviteCode: 'ADMIN001',
          permissions: ['all'],
        );
        _users.add(superAdmin);
        await _saveUsers();
      }
    }

    // 初始化分类
    final categoriesJson = prefs.getStringList('categories');
    if (categoriesJson != null && categoriesJson.isNotEmpty) {
      _categories.clear();
      for (final catStr in categoriesJson) {
        final catJson = json.decode(catStr);
        // 从预设图标中查找匹配的 icon
        final iconCode = catJson['icon'] as int?;
        IconData icon = Icons.square;
        if (iconCode != null) {
          // 使用预设图标列表查找匹配的 icon
          final presetIcons = [
            Icons.square,
            Icons.layers,
            Icons.grid_on,
            Icons.blur_on,
            Icons.apps,
            Icons.photo,
            Icons.table_rows,
            Icons.blur_circular,
            Icons.star,
            Icons.landscape,
            Icons.crop,
            Icons.horizontal_rule,
          ];
          for (final presetIcon in presetIcons) {
            if (presetIcon.codePoint == iconCode) {
              icon = presetIcon;
              break;
            }
          }
        }
        _categories.add(
          Category(
            id: catJson['id'] ?? '',
            name: catJson['name'] ?? '',
            icon: icon,
            color: Color(catJson['color'] ?? Colors.blue.value),
            isEnabled: catJson['isEnabled'] ?? true,
          ),
        );
      }
    } else {
      // 创建预设分类
      final presetCategories = [
        Category(id: '1', name: '瓷抛砖', icon: Icons.square, color: Colors.blue),
        Category(id: '2', name: '釉面砖', icon: Icons.layers, color: Colors.green),
        Category(
          id: '3',
          name: '通体砖',
          icon: Icons.grid_on,
          color: Colors.orange,
        ),
        Category(
          id: '4',
          name: '玻化砖',
          icon: Icons.blur_on,
          color: Colors.purple,
        ),
        Category(id: '5', name: '马赛克', icon: Icons.apps, color: Colors.red),
        Category(id: '6', name: '大理石', icon: Icons.photo, color: Colors.teal),
        Category(
          id: '7',
          name: '木纹砖',
          icon: Icons.table_rows,
          color: Colors.brown,
        ),
        Category(
          id: '8',
          name: '水泥砖',
          icon: Icons.blur_circular,
          color: Colors.grey,
        ),
        Category(id: '9', name: '花片', icon: Icons.star, color: Colors.pink),
        Category(
          id: '10',
          name: '文化石',
          icon: Icons.landscape,
          color: Colors.amber,
        ),
        Category(
          id: '11',
          name: '踢脚线',
          icon: Icons.crop,
          color: Colors.deepOrange,
        ),
        Category(
          id: '12',
          name: '腰线',
          icon: Icons.horizontal_rule,
          color: Colors.cyan,
        ),
      ];
      _categories.addAll(presetCategories);
      await _saveCategories();
    }

    // 初始化产品
    final productsJson = prefs.getStringList('products');
    if (productsJson != null && productsJson.isNotEmpty) {
      _products.clear();
      for (final prodStr in productsJson) {
        _products.add(Product.fromJson(json.decode(prodStr)));
      }
    } else {
      // 创建预设产品
      await _initDefaultProducts();
    }

    // 加载购物车
    final cartJson = prefs.getStringList('cart');
    if (cartJson != null && cartJson.isNotEmpty) {
      _cartItems.clear();
      for (final itemStr in cartJson) {
        _cartItems.add(CartItem.fromJson(json.decode(itemStr)));
      }
    }

    // 加载当前用户
    _currentUserUsername = prefs.getString('currentUser');
    if (_currentUserUsername != null) {
      try {
        _currentUser = _users.firstWhere(
          (u) => u.username == _currentUserUsername,
        );
      } catch (e) {
        _currentUser = null;
        _currentUserUsername = null;
        await prefs.remove('currentUser');
      }
    }

    // 加载订单
    final ordersJson = prefs.getStringList('orders');
    if (ordersJson != null && ordersJson.isNotEmpty) {
      _orders.clear();
      for (final orderStr in ordersJson) {
        _orders.add(Order.fromJson(json.decode(orderStr)));
      }
    }
  }

  Future<void> _initDefaultProducts() async {
    _products.clear();
    for (int catId = 1; catId <= 12; catId++) {
      for (int i = 1; i <= 8; i++) {
        _products.add(
          Product(
            id: '${catId}_$i',
            categoryId: '$catId',
            name: '产品${i}',
            price: (i + 1) * 80,
            brand: '诺贝尔瓷砖',
            spec: '800×800mm',
            material: '陶瓷',
            origin: '广东佛山',
            stock: 100,
          ),
        );
      }
    }
    await _saveProducts();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersList = _users.map((u) => json.encode(u.toJson())).toList();
    await prefs.setStringList('users', usersList);
    // 同时保存到浏览器的 localStorage 作为备份
    html.window.localStorage['users_backup'] = json.encode(usersList);
  }

  Future<void> _loadUsers() async {
    // 尝试从 localStorage 加载备份数据
    final backup = html.window.localStorage['users_backup'];
    if (backup != null && backup.isNotEmpty) {
      final usersList = json.decode(backup) as List;
      _users.clear();
      for (final userStr in usersList) {
        _users.add(User.fromJson(json.decode(userStr)));
      }
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'categories',
      _categories.map((c) => json.encode(c.toJson())).toList(),
    );
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'products',
      _products.map((p) => json.encode(p.toJson())).toList(),
    );
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'cart',
      _cartItems.map((i) => json.encode(i.toJson())).toList(),
    );
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'orders',
      _orders.map((o) => json.encode(o.toJson())).toList(),
    );
  }

  Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('currentUser', _currentUser!.username);
    } else {
      await prefs.remove('currentUser');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final user = _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      _currentUser = user;
      _currentUserUsername = username;
      await _saveCurrentUser();
      return true;
    } catch (e) {
      // 用户未找到或密码错误
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password,
    String inviteCode,
  ) async {
    // 检查用户名是否已存在
    if (_users.any((u) => u.username == username)) {
      return false;
    }

    // 如果是空邀请码，允许注册（简化注册流程）
    // 或者验证邀请码（超级管理员创建的邀请码）
    if (inviteCode.isNotEmpty) {
      final validCode = _users
          .where((u) => u.inviteCode == inviteCode && u.isAdmin)
          .firstOrNull;

      if (validCode == null) {
        return false;
      }
    }

    final newUser = User(
      username: username,
      password: password,
      inviteCode: inviteCode.isNotEmpty ? inviteCode : null,
      permissions: ['view_products', 'add_to_cart'],
    );
    _users.add(newUser);
    await _saveUsers();
    return true;
  }

  void logout() async {
    _currentUser = null;
    _currentUserUsername = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  void addToCart(CartItem item, {VoidCallback? onCartChanged}) {
    final existingIndex = _cartItems.indexWhere(
      (i) => i.productName == item.productName && i.brand == item.brand,
    );
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity++;
    } else {
      _cartItems.add(item);
    }
    _saveCart();
    // 通知 UI 刷新
    onCartChanged?.call();
    // 通知全局监听器
    this.onCartChanged?.call();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      _saveCart();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
  }

  void updateCategory(String id, String name, IconData icon, Color color) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final category = _categories[index];
      // 创建一个新对象以触发状态更新
      _categories[index] = Category(
        id: category.id,
        name: name,
        icon: icon,
        color: color,
        isEnabled: category.isEnabled,
      );
      _saveCategories();
    }
  }

  void toggleCategory(String id) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index >= 0) {
      final category = _categories[index];
      _categories[index] = Category(
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        isEnabled: !category.isEnabled,
      );
      _saveCategories();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    _saveCategories();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
    _saveProducts();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      _saveProducts();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _saveProducts();
  }

  void placeOrder() {
    if (_cartItems.isEmpty) return;

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: _currentUser?.username ?? 'guest',
      items: List.from(_cartItems),
      totalPrice: totalPrice,
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    _cartItems.clear();
    _saveOrders();
    _saveCart();
  }
}

// ==================== 首页 ====================

// 全局 Scaffold key 用于打开购物车侧边栏
final GlobalKey<ScaffoldState> globalScaffoldKey = GlobalKey<ScaffoldState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  final GlobalKey<_HomeContentState> _homeContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 注册购物车变化监听器
    DataManager().onCartChanged = () {
      if (mounted) setState(() {});
    };
    _initData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initData() async {
    await DataManager().init();
    setState(() => _isLoading = false);
  }

  void refreshHome() {
    setState(() {});
    _homeContentKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 存储 refreshHome 到 DataManager 以便其他页面调用
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: globalScaffoldKey,
        body: _HomeContent(key: _homeContentKey),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static _HomeContentState? _instance;
  final _searchController = TextEditingController();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  // 用于刷新
  int _version = 0;
  void refresh() => setState(() => _version++);

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    _searchController.dispose();
    super.dispose();
  }

  // 打开购物车侧边栏
  static void openCartDrawer() {
    globalScaffoldKey.currentState?.openEndDrawer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次路由变化时刷新
    refresh();
  }

  // 保存用户数据到 SharedPreferences
  Future<void> _saveUsersToPrefs(DataManager dataManager) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'users',
      dataManager.users.map((u) => json.encode(u.toJson())).toList(),
    );
  }

  // 预设颜色列表
  final List<Color> _tileColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.grey,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
  ];

  // 选择登录类型对话框
  // 选择登录类型对话框
  void _showLoginTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会员服务中心'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue, size: 32),
              title: const Text(
                '会员登录',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('管理购物车、订单等'),
              onTap: () {
                Navigator.pop(context);
                _showLoginDialog(context, isAdmin: false);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.red,
                size: 32,
              ),
              title: const Text(
                '管理员登录',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('管理分类、产品等'),
              onTap: () {
                Navigator.pop(context);
                _showLoginDialog(context, isAdmin: true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.app_registration,
                color: Colors.green,
                size: 32,
              ),
              title: const Text(
                '注册会员',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('注册新账号享受更多优惠'),
              onTap: () {
                Navigator.pop(context);
                _showRegisterDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.lock_reset,
                color: Colors.orange,
                size: 32,
              ),
              title: const Text(
                '忘记密码',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('重置您的登录密码'),
              onTap: () {
                Navigator.pop(context);
                _showForgotPasswordDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 登录对话框
  void _showLoginDialog(BuildContext context, {bool isAdmin = false}) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin ? '管理员登录' : '会员登录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onSubmitted: (_) async {
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final success = await DataManager().login(
                    usernameController.text,
                    passwordController.text,
                  );
                  if (success) {
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('登录成功')));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('用户名或密码错误')));
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                final success = await DataManager().login(
                  usernameController.text,
                  passwordController.text,
                );
                if (success) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('登录成功')));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('用户名或密码错误')));
                }
              }
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }

  // 注册对话框
  void _showRegisterDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final inviteCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注册会员'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inviteCodeController,
                decoration: const InputDecoration(
                  labelText: '邀请码（可选）',
                  border: OutlineInputBorder(),
                  hintText: '输入邀请码注册',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请填写用户名和密码')));
                return;
              }
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
                return;
              }
              final success = await DataManager().register(
                usernameController.text,
                passwordController.text,
                inviteCodeController.text,
              );
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('注册失败，用户名已存在或邀请码无效')),
                );
              }
            },
            child: const Text('注册'),
          ),
        ],
      ),
    );
  }

  // 忘记密码对话框
  void _showForgotPasswordDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('忘记密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (usernameController.text.isEmpty ||
                  newPasswordController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请填写用户名和新密码')));
                return;
              }
              if (newPasswordController.text != confirmController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('两次输入的密码不一致')));
                return;
              }
              // 重置密码
              final dataManager = DataManager();
              final userIndex = dataManager.users.indexWhere(
                (u) => u.username == usernameController.text,
              );
              if (userIndex != -1) {
                final oldUser = dataManager.users[userIndex];
                // 创建新用户对象替换旧用户（因为 User 是 final 字段）
                final newUser = User(
                  username: oldUser.username,
                  password: newPasswordController.text,
                  isAdmin: oldUser.isAdmin,
                  isSuperAdmin: oldUser.isSuperAdmin,
                  inviteCode: oldUser.inviteCode,
                  permissions: oldUser.permissions,
                );
                dataManager.users[userIndex] = newUser;
                // 调用私有方法 _saveUsers 需要通过反射或其他方式
                // 这里我们直接调用 DataManager 的内部保存逻辑
                _saveUsersToPrefs(dataManager);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('密码已重置，请重新登录')));
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('用户名不存在')));
              }
            },
            child: const Text('重置密码'),
          ),
        ],
      ),
    );
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final products = DataManager().products;
    final suggestions = <String>{};

    for (var product in products) {
      final name = product.name.toLowerCase();
      final queryLower = query.toLowerCase();

      // 模糊匹配：只要包含查询字符串就匹配
      if (name.contains(queryLower)) {
        suggestions.add(product.name);
      }
      // 也匹配产品 ID/型号中的数字
      if (product.id.contains(query)) {
        suggestions.add(product.name);
      }
    }

    setState(() {
      _searchSuggestions = suggestions.take(5).toList();
      _showSuggestions = _searchSuggestions.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final smallTileHeight = (screenWidth - 80) / 4;
    final mediumTileHeight = smallTileHeight * 1.3;
    final user = DataManager().currentUser;
    final isLoggedIn = user != null;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '优惠',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: const NotificationDot(
                    child: ScrollingText(
                      text:
                          '🎉 瓷抛砖新品上市 8 折优惠！  🔥 釉面砖买 10 送 1！  ⚡ 马赛克限时特价！  💎 大理石瓷砖满 1000 减 200！',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (isLoggedIn)
              // 已登录，显示用户名和退出菜单
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  } else if (value == 'admin') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardPage(),
                      ),
                    );
                  } else if (value == 'center') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemberCenterPage(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.isSuperAdmin
                              ? '超级管理员'
                              : user.isAdmin
                              ? '管理员'
                              : '普通会员',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'center',
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('会员中心', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  if (user.isAdmin || user.isSuperAdmin) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('管理后台', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('退出登录', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            else
              // 未登录，显示登录按钮
              TextButton(
                onPressed: () => _showLoginTypeDialog(context),
                child: const Text(
                  '登录',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    children: [
                      _buildRow1(context, screenWidth),
                      _buildRow2(context, smallTileHeight),
                      _buildRow3(context, screenWidth),
                      _buildRow4(context, mediumTileHeight),
                    ],
                  ),
                ),
              ),
            ),
            // 悬浮搜索框
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索产品（如：1809）',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.blue,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _updateSuggestions,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchResultsPage(
                                query: value,
                                products: DataManager().products,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  if (_showSuggestions)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (_, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.search,
                              color: Colors.blue,
                              size: 20,
                            ),
                            title: Text(_searchSuggestions[index]),
                            onTap: () {
                              _searchController.text =
                                  _searchSuggestions[index];
                              setState(() => _showSuggestions = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchResultsPage(
                                    query: _searchSuggestions[index],
                                    products: DataManager().products,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildCartButton(context),
        endDrawer: Drawer(
          elevation: 10,
          child: CartDrawer(onCartChanged: () => setState(() {})),
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showCartDialog(context, setState),
      backgroundColor: Colors.red,
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      label: Text(
        '${DataManager().totalCount}件',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow1(BuildContext context, double screenWidth) {
    final cats = DataManager().categories;
    final cpz = cats.where((c) => c.id == '1').firstOrNull;
    final ymz = cats.where((c) => c.id == '2').firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildLargeTile(
              context,
              cpz?.name ?? '瓷抛砖',
              cpz?.icon ?? Icons.square,
              cpz?.color ?? Colors.blue,
              screenWidth * 0.45,
              '1',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: _buildLargeTile(
              context,
              ymz?.name ?? '釉面砖',
              ymz?.icon ?? Icons.layers,
              ymz?.color ?? Colors.green,
              screenWidth * 0.45,
              '2',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow2(BuildContext context, double tileHeight) {
    final cats = DataManager().categories;
    final ttz = cats.where((c) => c.id == '3').firstOrNull;
    final bhz = cats.where((c) => c.id == '4').firstOrNull;
    final msb = cats.where((c) => c.id == '5').firstOrNull;
    final dlz = cats.where((c) => c.id == '6').firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildTile(
              context,
              ttz?.name ?? '通体砖',
              ttz?.icon ?? Icons.grid_on,
              ttz?.color ?? Colors.orange,
              tileHeight,
              '3',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTile(
              context,
              bhz?.name ?? '玻化砖',
              bhz?.icon ?? Icons.blur_on,
              bhz?.color ?? Colors.purple,
              tileHeight,
              '4',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTile(
              context,
              msb?.name ?? '马赛克',
              msb?.icon ?? Icons.apps,
              msb?.color ?? Colors.red,
              tileHeight,
              '5',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTile(
              context,
              dlz?.name ?? '大理石',
              dlz?.icon ?? Icons.photo,
              dlz?.color ?? Colors.teal,
              tileHeight,
              '6',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow3(BuildContext context, double screenWidth) {
    final cats = DataManager().categories;
    final mwz = cats.where((c) => c.id == '7').firstOrNull;
    final snz = cats.where((c) => c.id == '8').firstOrNull;
    final hp = cats.where((c) => c.id == '9').firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildWideTile(
              context,
              mwz?.name ?? '木纹砖',
              mwz?.icon ?? Icons.table_rows,
              mwz?.color ?? Colors.brown,
              '7',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTile(
              context,
              snz?.name ?? '水泥砖',
              snz?.icon ?? Icons.blur_circular,
              snz?.color ?? Colors.grey,
              (screenWidth - 60) / 4,
              '8',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTile(
              context,
              hp?.name ?? '花片',
              hp?.icon ?? Icons.star,
              hp?.color ?? Colors.pink,
              (screenWidth - 60) / 4,
              '9',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow4(BuildContext context, double tileHeight) {
    final cats = DataManager().categories;
    final whs = cats.where((c) => c.id == '10').firstOrNull;
    final tjx = cats.where((c) => c.id == '11').firstOrNull;
    final yx = cats.where((c) => c.id == '12').firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildMediumTile(
              context,
              whs?.name ?? '文化石',
              whs?.icon ?? Icons.landscape,
              whs?.color ?? Colors.amber,
              tileHeight,
              '10',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMediumTile(
              context,
              tjx?.name ?? '踢脚线',
              tjx?.icon ?? Icons.crop,
              tjx?.color ?? Colors.deepOrange,
              tileHeight,
              '11',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildMediumTile(
              context,
              yx?.name ?? '腰线',
              yx?.icon ?? Icons.horizontal_rule,
              yx?.color ?? Colors.cyan,
              tileHeight,
              '12',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    double height,
    String categoryId,
  ) {
    final category = DataManager().categories.firstWhere(
      (c) => c.id == categoryId,
    );
    // 使用预设颜色列表中的随机颜色（根据 category ID 索引）
    final randomColor = _tileColors[int.parse(categoryId) % _tileColors.length];

    if (!category.isEnabled) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: height * 0.35, color: Colors.white70),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showBrandDialog(context, title, categoryId),
        child: Container(
          height: height,
          color: randomColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: height * 0.35, color: Colors.white),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String categoryId,
  ) {
    final category = DataManager().categories.firstWhere(
      (c) => c.id == categoryId,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (screenWidth - 80) / 4;
    final randomColor = _tileColors[int.parse(categoryId) % _tileColors.length];

    if (!category.isEnabled) {
      return Container(
        height: height,
        decoration: const BoxDecoration(),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: height * 0.4, color: Colors.white70),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductListPage(categoryName: title, categoryId: categoryId),
          ),
        ),
        child: Container(
          height: height,
          color: randomColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: height * 0.4, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    double height,
    String categoryId,
  ) {
    return _buildCard(
      context,
      title,
      icon,
      color,
      height,
      categoryId,
      iconSize: height * 0.4,
      fontSize: 13,
    );
  }

  Widget _buildMediumTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    double height,
    String categoryId,
  ) {
    return _buildCard(
      context,
      title,
      icon,
      color,
      height,
      categoryId,
      iconSize: height * 0.45,
      fontSize: 14,
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    double height,
    String categoryId, {
    required double iconSize,
    required double fontSize,
  }) {
    final category = DataManager().categories.firstWhere(
      (c) => c.id == categoryId,
    );
    final randomColor = _tileColors[int.parse(categoryId) % _tileColors.length];

    if (!category.isEnabled) {
      return Container(
        height: height,
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.white70),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showBrandDialog(context, title, categoryId),
        child: Container(
          height: height,
          color: randomColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: Colors.white),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showBrandDialog(
  BuildContext context,
  String categoryName,
  String categoryId,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('选择品牌', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildBrandTile(
            context,
            categoryName,
            categoryId,
            '诺贝尔瓷砖',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          buildBrandTile(
            context,
            categoryName,
            categoryId,
            'HBI 岩板',
            Colors.purple,
          ),
        ],
      ),
    ),
  );
}

Widget buildBrandTile(
  BuildContext context,
  String categoryName,
  String categoryId,
  String brand,
  Color color,
) {
  return InkWell(
    onTap: () {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListPage(
            categoryName: categoryName,
            categoryId: categoryId,
            brand: brand,
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            brand,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 18, color: color),
        ],
      ),
    ),
  );
}

// ==================== 产品列表页 ====================

class ProductListPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final String brand;

  const ProductListPage({
    super.key,
    required this.categoryName,
    this.categoryId = '',
    this.brand = '诺贝尔瓷砖',
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int _version = 0;
  void _refresh() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    final products = DataManager().getProductsByCategory(widget.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryName, style: const TextStyle(fontSize: 14)),
            Text(
              widget.brand,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCartDialog(context, setState),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: Text(
          '${DataManager().totalCount}件',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          itemCount: products.length,
          itemBuilder: (_, index) {
            final product = products[index];
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
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child:
                            product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? Image.network(
                                product.imageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildProductPlaceholder(product),
                              )
                            : _buildProductPlaceholder(product),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.spec,
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
                              '¥${product.price}',
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
                                DataManager().addToCart(
                                  CartItem(
                                    categoryId: widget.categoryId,
                                    categoryName: widget.categoryName,
                                    productName: product.name,
                                    price: product.price,
                                    brand: product.brand,
                                  ),
                                  onCartChanged: () => setState(() {}),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已添加'),
                                    duration: const Duration(milliseconds: 800),
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
                            categoryId: widget.categoryId,
                            categoryName: widget.categoryName,
                            product: product,
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

  Widget _buildProductPlaceholder(Product product) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ==================== 产品详情页 ====================

class ProductDetailPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      floatingActionButton: DataManager().cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => showCartDialog(context, setState),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${DataManager().totalCount}件',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade300,
              child:
                  widget.product.imageUrl != null &&
                      widget.product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      child: widget.product.imageUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(
                                widget.product.imageUrl!.split(',').last,
                              ),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.product.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.product.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.product.name,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${widget.product.price}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow('分类', widget.categoryName),
                  _buildInfoRow('品牌', widget.product.brand),
                  _buildInfoRow('规格', widget.product.spec),
                  _buildInfoRow('材质', widget.product.material),
                  _buildInfoRow('产地', widget.product.origin),
                  _buildInfoRow('库存', '${widget.product.stock}件'),
                  const Divider(height: 32),
                  const Text(
                    '产品介绍',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.product.brand}品牌推出的${widget.product.name}，采用优质陶瓷材料，经过高温烧制而成。表面光滑细腻，质地坚硬耐用，适合用于客厅、卧室、厨房等空间的地面和墙面装饰。',
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
                  DataManager().addToCart(
                    CartItem(
                      categoryId: widget.categoryId,
                      categoryName: widget.categoryName,
                      productName: widget.product.name,
                      price: widget.product.price,
                      brand: widget.product.brand,
                    ),
                    onCartChanged: () => setState(() {}),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已添加'),
                      duration: Duration(milliseconds: 800),
                    ),
                  );
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
                  DataManager().addToCart(
                    CartItem(
                      categoryId: widget.categoryId,
                      categoryName: widget.categoryName,
                      productName: widget.product.name,
                      price: widget.product.price,
                      brand: widget.product.brand,
                    ),
                    onCartChanged: () => setState(() {}),
                  );
                  showCartDialog(context, setState);
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

// ==================== 购物车页面 ====================

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('购物车'),
          backgroundColor: Colors.blue.shade700,
          actions: [
            if (DataManager().cartItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => DataManager().clearCart());
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('购物车已清空')));
                },
              ),
          ],
        ),
        body: DataManager().cartItems.isEmpty
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
                      itemCount: DataManager().cartItems.length,
                      itemBuilder: (_, index) {
                        final item = DataManager().cartItems[index];
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
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
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
                                        DataManager().removeFromCart(index);
                                      }
                                    });
                                  },
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () =>
                                      setState(() => item.quantity++),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setState(
                                    () => DataManager().removeFromCart(index),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (DataManager().cartItems.isNotEmpty)
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
                                '共${DataManager().totalCount}件商品',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                '合计：¥${DataManager().totalPrice}',
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
                              _handleCheckout();
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
      ),
    );
  }

  void _handleCheckout() {
    DataManager().placeOrder();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('订单提交成功！')));
    Navigator.pop(context);
    setState(() {});
  }
}

// ==================== 购物车侧边栏 ====================

class CartDrawer extends StatefulWidget {
  final VoidCallback? onCartChanged;

  const CartDrawer({super.key, this.onCartChanged});

  @override
  State<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends State<CartDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade700,
            child: Row(
              children: [
                const Text(
                  '购物车',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Scaffold.of(context).closeEndDrawer(),
                ),
              ],
            ),
          ),
          Expanded(
            child: DataManager().cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '购物车是空的',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: DataManager().cartItems.length,
                    itemBuilder: (_, index) {
                      final item = DataManager().cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          title: Text(
                            item.productName,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '¥${item.price} × ${item.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      DataManager().removeFromCart(index);
                                    }
                                  });
                                  widget.onCartChanged?.call();
                                },
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                  });
                                  widget.onCartChanged?.call();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    DataManager().removeFromCart(index);
                                  });
                                  widget.onCartChanged?.call();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (DataManager().cartItems.isNotEmpty)
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '共${DataManager().totalCount}件商品',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '合计：¥${DataManager().totalPrice}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => DataManager().clearCart());
                            widget.onCartChanged?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('清空'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            DataManager().placeOrder();
                            setState(() {});
                            widget.onCartChanged?.call();
                            Scaffold.of(context).closeEndDrawer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('订单提交成功！')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('去结算'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// 显示购物车侧边栏的辅助函数
void showCartDialog(BuildContext context, [StateSetter? refreshParent]) {
  _HomeContentState.openCartDrawer();
}

// ==================== 订单历史页面 ====================

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final orders = DataManager().orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单历史'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无订单',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '订单号：${order.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.status == 'pending'
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status == 'pending' ? '待处理' : '已完成',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: order.status == 'pending'
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ...order.items.map(
                        (item) => ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          title: Text(item.productName),
                          subtitle: Text('¥${item.price} × ${item.quantity}'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '下单时间：${_formatDateTime(order.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '总计：¥${order.totalPrice}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== 收藏页面 ====================

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无收藏', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ==================== 用户中心页面 ====================

class UserCenterPage extends StatefulWidget {
  const UserCenterPage({super.key});

  @override
  State<UserCenterPage> createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  @override
  Widget build(BuildContext context) {
    final user = DataManager().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user?.username ?? '未登录',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.isSuperAdmin == true
                  ? '超级管理员'
                  : user?.isAdmin == true
                  ? '管理员'
                  : '普通用户',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue.shade700, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.blue),
            title: const Text('我的订单'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 切换到订单页面
              // 这里可以通过 GlobalKey 或其他方式实现
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.orange),
            title: const Text('收货地址'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('地址管理功能开发中...')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.green),
            title: const Text('联系客服'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('客服功能开发中...')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.purple),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

// ==================== 设置页面 ====================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final user = DataManager().currentUser;
    final isLoggedIn = user != null;
    final isAdmin = DataManager().isAdminUser;
    final isSuperAdmin = DataManager().isSuperUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        children: [
          // 用户登录状态
          ListTile(
            leading: Icon(
              isLoggedIn ? Icons.check_circle : Icons.cancel,
              color: isLoggedIn ? Colors.green : Colors.grey,
            ),
            title: Text(isLoggedIn ? '已登录' : '未登录'),
            subtitle: Text(
              isLoggedIn
                  ? (isSuperAdmin
                        ? '超级管理员：${user.username}'
                        : isAdmin
                        ? '管理员：${user.username}'
                        : '普通用户：${user.username}')
                  : '登录后可管理购物车、订单等',
            ),
            trailing: isLoggedIn
                ? ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    child: const Text('退出'),
                  )
                : ElevatedButton(
                    onPressed: () => _showLoginDialog(context),
                    child: const Text('登录'),
                  ),
          ),
          const Divider(),
          // 管理后台（仅管理员可见）
          if (isLoggedIn)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.red,
              ),
              title: const Text('管理后台'),
              subtitle: const Text('分类管理、产品管理等'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (DataManager().isAdminUser) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboardPage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('您没有管理权限，需要管理员账号')),
                  );
                }
              },
            ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('关于'),
            subtitle: Text('版本：1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理员登录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onSubmitted: (_) async {
                // 按回车键登录
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final success = await DataManager().login(
                    usernameController.text,
                    passwordController.text,
                  );
                  if (success) {
                    Navigator.pop(context);
                    setState(() {}); // 刷新页面
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('登录成功')));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('用户名或密码错误')));
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                final success = await DataManager().login(
                  usernameController.text,
                  passwordController.text,
                );
                if (success) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('登录成功')));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('用户名或密码错误')));
                }
              }
            },
            child: const Text('登录'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

// ==================== 管理员仪表板 ====================

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = DataManager().currentUser;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理后台'),
        backgroundColor: Colors.red.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildModuleCard(
            context,
            '分类管理',
            Icons.category,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryManagePage()),
            ),
          ),
          _buildModuleCard(
            context,
            '产品管理',
            Icons.inventory,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductManagePage()),
            ),
          ),
          if (isSuperAdmin)
            _buildModuleCard(
              context,
              '用户管理',
              Icons.people,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagePage()),
              ),
            ),
          if (isSuperAdmin)
            _buildModuleCard(
              context,
              '权限管理',
              Icons.security,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PermissionManagePage()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 分类管理页面 ====================

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  // 预设颜色列表 - 与主界面保持一致
  final List<Color> _tileColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.brown,
    Colors.grey,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    final categories = DataManager().categories;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 1000 ? 3 : 4);
    final childAspectRatio = screenWidth < 600 ? 0.9 : 1.2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (_, index) => _buildCategoryCard(categories[index]),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    // 使用与主界面相同的颜色（根据 category ID 索引）
    final tileColor = _tileColors[int.parse(category.id) % _tileColors.length];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _showEditCategoryDialog(category),
        child: Container(
          decoration: BoxDecoration(
            color: category.isEnabled ? tileColor : Colors.grey.shade300,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 40,
                color: category.isEnabled ? Colors.white : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: category.isEnabled ? Colors.white : Colors.grey,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.isEnabled
                      ? Colors.white
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  category.isEnabled ? '已启用' : '未启用',
                  style: TextStyle(
                    fontSize: 12,
                    color: category.isEnabled
                        ? Colors.green.shade700
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择图标:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIconOption(
                      Icons.square,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.square,
                    ),
                    _buildIconOption(
                      Icons.layers,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.layers,
                    ),
                    _buildIconOption(
                      Icons.grid_on,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.grid_on,
                    ),
                    _buildIconOption(
                      Icons.blur_on,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.blur_on,
                    ),
                    _buildIconOption(
                      Icons.apps,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.apps,
                    ),
                    _buildIconOption(
                      Icons.photo,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.photo,
                    ),
                    _buildIconOption(
                      Icons.table_rows,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.table_rows,
                    ),
                    _buildIconOption(
                      Icons.blur_circular,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.blur_circular,
                    ),
                    _buildIconOption(
                      Icons.star,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.star,
                    ),
                    _buildIconOption(
                      Icons.landscape,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.landscape,
                    ),
                    _buildIconOption(
                      Icons.crop,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.crop,
                    ),
                    _buildIconOption(
                      Icons.horizontal_rule,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.horizontal_rule,
                    ),
                    // 新增 12 个图标
                    _buildIconOption(
                      Icons.circle,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.circle,
                    ),
                    _buildIconOption(
                      Icons.change_history,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.change_history,
                    ),
                    _buildIconOption(
                      Icons.hexagon,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.hexagon,
                    ),
                    _buildIconOption(
                      Icons.category,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.category,
                    ),
                    _buildIconOption(
                      Icons.diamond,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.diamond,
                    ),
                    _buildIconOption(
                      Icons.rectangle,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.rectangle,
                    ),
                    _buildIconOption(
                      Icons.panorama,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.panorama,
                    ),
                    _buildIconOption(
                      Icons.wallpaper,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.wallpaper,
                    ),
                    _buildIconOption(
                      Icons.grid_view,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.grid_view,
                    ),
                    _buildIconOption(
                      Icons.dashboard,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.dashboard,
                    ),
                    _buildIconOption(
                      Icons.lightbulb,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.lightbulb,
                    ),
                    _buildIconOption(
                      Icons.light_mode,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.light_mode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择颜色:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildColorOption(
                      Colors.blue,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.blue,
                    ),
                    _buildColorOption(
                      Colors.green,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.green,
                    ),
                    _buildColorOption(
                      Colors.orange,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.orange,
                    ),
                    _buildColorOption(
                      Colors.purple,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.purple,
                    ),
                    _buildColorOption(
                      Colors.red,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.red,
                    ),
                    _buildColorOption(
                      Colors.teal,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.teal,
                    ),
                    _buildColorOption(
                      Colors.brown,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.brown,
                    ),
                    _buildColorOption(
                      Colors.grey,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.grey,
                    ),
                    _buildColorOption(
                      Colors.pink,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.pink,
                    ),
                    _buildColorOption(
                      Colors.amber,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.amber,
                    ),
                    _buildColorOption(
                      Colors.deepOrange,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.deepOrange,
                    ),
                    _buildColorOption(
                      Colors.cyan,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.cyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                DataManager().updateCategory(
                  category.id,
                  nameController.text,
                  selectedIcon,
                  selectedColor,
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('保存'),
            ),
            IconButton(
              icon: const Icon(Icons.toggle_on, size: 28),
              tooltip: category.isEnabled ? '禁用' : '启用',
              onPressed: () {
                DataManager().toggleCategory(category.id);
                Navigator.pop(context);
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDelete(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOption(
    IconData icon,
    IconData selected,
    StateSetter setDialogState,
    VoidCallback onSelect,
  ) {
    final isSelected = icon == selected;
    return InkWell(
      onTap: () {
        onSelect();
        setDialogState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _buildColorOption(
    Color color,
    Color selected,
    StateSetter setDialogState,
    VoidCallback onSelect,
  ) {
    final isSelected = color == selected;
    return InkWell(
      onTap: () {
        onSelect();
        setDialogState(() {});
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.square;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择图标:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIconOption(
                      Icons.square,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.square,
                    ),
                    _buildIconOption(
                      Icons.layers,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.layers,
                    ),
                    _buildIconOption(
                      Icons.grid_on,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.grid_on,
                    ),
                    _buildIconOption(
                      Icons.blur_on,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.blur_on,
                    ),
                    _buildIconOption(
                      Icons.apps,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.apps,
                    ),
                    _buildIconOption(
                      Icons.photo,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.photo,
                    ),
                    _buildIconOption(
                      Icons.table_rows,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.table_rows,
                    ),
                    _buildIconOption(
                      Icons.blur_circular,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.blur_circular,
                    ),
                    _buildIconOption(
                      Icons.star,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.star,
                    ),
                    _buildIconOption(
                      Icons.landscape,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.landscape,
                    ),
                    _buildIconOption(
                      Icons.crop,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.crop,
                    ),
                    _buildIconOption(
                      Icons.horizontal_rule,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.horizontal_rule,
                    ),
                    // 新增 12 个图标
                    _buildIconOption(
                      Icons.circle,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.circle,
                    ),
                    _buildIconOption(
                      Icons.change_history,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.change_history,
                    ),
                    _buildIconOption(
                      Icons.hexagon,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.hexagon,
                    ),
                    _buildIconOption(
                      Icons.category,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.category,
                    ),
                    _buildIconOption(
                      Icons.diamond,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.diamond,
                    ),
                    _buildIconOption(
                      Icons.rectangle,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.rectangle,
                    ),
                    _buildIconOption(
                      Icons.panorama,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.panorama,
                    ),
                    _buildIconOption(
                      Icons.wallpaper,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.wallpaper,
                    ),
                    _buildIconOption(
                      Icons.grid_view,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.grid_view,
                    ),
                    _buildIconOption(
                      Icons.dashboard,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.dashboard,
                    ),
                    _buildIconOption(
                      Icons.lightbulb,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.lightbulb,
                    ),
                    _buildIconOption(
                      Icons.light_mode,
                      selectedIcon,
                      setDialogState,
                      () => selectedIcon = Icons.light_mode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择颜色:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildColorOption(
                      Colors.blue,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.blue,
                    ),
                    _buildColorOption(
                      Colors.green,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.green,
                    ),
                    _buildColorOption(
                      Colors.orange,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.orange,
                    ),
                    _buildColorOption(
                      Colors.purple,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.purple,
                    ),
                    _buildColorOption(
                      Colors.red,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.red,
                    ),
                    _buildColorOption(
                      Colors.teal,
                      selectedColor,
                      setDialogState,
                      () => selectedColor = Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newCategory = Category(
                    id: (DataManager().categories.length + 1).toString(),
                    name: nameController.text,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  DataManager().categories.add(newCategory);
                  DataManager()._saveCategories();
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${category.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().deleteCategory(category.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ==================== 产品管理页面 ====================

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({super.key});

  @override
  State<ProductManagePage> createState() => _ProductManagePageState();
}

class _ProductManagePageState extends State<ProductManagePage> {
  String? _selectedCategoryId;
  final _searchController = TextEditingController();
  String _searchKeyword = '';

  List<Product> _getFilteredProducts() {
    if (_selectedCategoryId == null) return [];
    var products = DataManager().getProductsByCategory(_selectedCategoryId!);
    if (_searchKeyword.isEmpty) return products;
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
              p.brand.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
              p.spec.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
              p.material.toLowerCase().contains(_searchKeyword.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = DataManager().categories;
    final products = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('产品管理'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: DropdownButton<String>(
              hint: const Text('选择分类'),
              value: _selectedCategoryId,
              isExpanded: true,
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat.id, child: Text(cat.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _searchKeyword = '';
                  _searchController.clear();
                });
              },
            ),
          ),
          // 搜索栏
          if (_selectedCategoryId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索产品名称、品牌、规格、材质...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchKeyword = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchKeyword = value.trim());
                },
              ),
            ),
          // 产品列表
          Expanded(
            child: _selectedCategoryId == null
                ? const Center(child: Text('请选择一个分类'))
                : products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchKeyword.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchKeyword.isEmpty ? '该分类下暂无产品' : '未找到匹配的产品',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: products.length,
                    itemBuilder: (_, index) {
                      final product = products[index];
                      final category = DataManager().categories.firstWhere(
                        (c) => c.id == product.categoryId,
                      );
                      return _buildProductCard(product, category);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, Category category) {
    return Container(
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category.color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 产品图片区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(category),
                      )
                    : _buildPlaceholder(category),
              ),
            ),
          ),
          // 产品信息 - 中下方显示
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white.withOpacity(0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '¥${product.price}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    Text(
                      product.spec,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product.brand,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showEditProductDialog(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: category.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('编辑', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteProduct(product),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Category category) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: category.color),
          const SizedBox(height: 8),
          Text(
            '暂无图片',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final brandController = TextEditingController(text: '诺贝尔瓷砖');
    final specController = TextEditingController(text: '800×800mm');
    final materialController = TextEditingController(text: '陶瓷');
    final originController = TextEditingController(text: '广东佛山');
    String? selectedCategoryId;
    String? selectedImageUrl;

    // 选择图片
    Future<void> pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 读取文件并转换为 Base64
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        selectedImageUrl = 'data:image/jpeg;base64,$base64String';
        setState(() {});
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加产品'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '所属分类',
                    border: OutlineInputBorder(),
                  ),
                  items: DataManager().categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) => selectedCategoryId = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '产品名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: '价格',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: '品牌',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specController,
                  decoration: const InputDecoration(
                    labelText: '规格',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: materialController,
                  decoration: const InputDecoration(
                    labelText: '材质',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: originController,
                  decoration: const InputDecoration(
                    labelText: '产地',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // 图片选择按钮
                if (selectedImageUrl != null)
                  Container(
                    width: double.infinity,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(selectedImageUrl!.split(',').last),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('选择产品图片'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCategoryId != null &&
                    nameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  DataManager().addProduct(
                    Product(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      categoryId: selectedCategoryId!,
                      name: nameController.text,
                      price: int.tryParse(priceController.text) ?? 0,
                      brand: brandController.text,
                      spec: specController.text,
                      material: materialController.text,
                      origin: originController.text,
                      imageUrl: selectedImageUrl,
                    ),
                  );
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final brandController = TextEditingController(text: product.brand);
    final specController = TextEditingController(text: product.spec);
    final materialController = TextEditingController(text: product.material);
    final originController = TextEditingController(text: product.origin);
    String? selectedImageUrl = product.imageUrl;

    // 选择图片
    Future<void> pickImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        selectedImageUrl = 'data:image/jpeg;base64,$base64String';
        setState(() {});
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑产品'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图片预览
                if (selectedImageUrl != null && selectedImageUrl!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: selectedImageUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(selectedImageUrl!.split(',').last),
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              selectedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('选择产品图片'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '产品名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: '价格',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: '品牌',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specController,
                  decoration: const InputDecoration(
                    labelText: '规格',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: materialController,
                  decoration: const InputDecoration(
                    labelText: '材质',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: originController,
                  decoration: const InputDecoration(
                    labelText: '产地',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                DataManager().updateProduct(
                  Product(
                    id: product.id,
                    categoryId: product.categoryId,
                    name: nameController.text,
                    price: int.tryParse(priceController.text) ?? product.price,
                    brand: brandController.text,
                    spec: specController.text,
                    material: materialController.text,
                    origin: originController.text,
                    stock: product.stock,
                    imageUrl: selectedImageUrl,
                  ),
                );
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除产品"${product.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().deleteProduct(product.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ==================== 用户管理页面 ====================

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  @override
  Widget build(BuildContext context) {
    final users = DataManager().users;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.isSuperAdmin
                    ? Colors.red
                    : user.isAdmin
                    ? Colors.blue
                    : Colors.grey,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.username),
              subtitle: Text(
                user.isSuperAdmin
                    ? '超级管理员'
                    : user.isAdmin
                    ? '管理员'
                    : '普通用户',
              ),
              trailing: user.isSuperAdmin
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteUser(user),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户"${user.username}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              DataManager().users.remove(user);
              DataManager()._saveUsers();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ==================== 权限管理页面 ====================

class PermissionManagePage extends StatefulWidget {
  const PermissionManagePage({super.key});

  @override
  State<PermissionManagePage> createState() => _PermissionManagePageState();
}

class _PermissionManagePageState extends State<PermissionManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限管理'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: const Center(child: Text('权限管理功能开发中...')),
    );
  }
}

// ==================== 滚动文本组件 ====================

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const ScrollingText({super.key, required this.text, required this.style});

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1, end: -1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _animation.value * MediaQuery.of(context).size.width,
              0,
            ),
            child: child,
          );
        },
        child: Text(widget.text, style: widget.style, maxLines: 1),
      ),
    );
  }
}

// ==================== 红点提示组件 ====================

class NotificationDot extends StatefulWidget {
  final Widget child;

  const NotificationDot({super.key, required this.child});

  @override
  State<NotificationDot> createState() => _NotificationDotState();
}

class _NotificationDotState extends State<NotificationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTransition(
          scale: _animation,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: widget.child),
      ],
    );
  }
}

// ==================== 搜索结果页面 ====================

class SearchResultsPage extends StatefulWidget {
  final String query;
  final List<Product> products;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.products,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Product> get _filteredProducts {
    final queryLower = widget.query.toLowerCase();
    return widget.products.where((product) {
      final name = product.name.toLowerCase();
      final brand = product.brand.toLowerCase();
      final spec = product.spec.toLowerCase();
      // 模糊匹配：只要任何字段包含查询字符串就匹配
      return name.contains(queryLower) ||
          brand.contains(queryLower) ||
          spec.contains(queryLower) ||
          product.id.contains(widget.query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text('搜索："${widget.query}"'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: results.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '未找到相关产品',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Container(
              color: Colors.grey.shade100,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: results.length,
                itemBuilder: (_, index) {
                  final product = results[index];
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
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child:
                                  product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? product.imageUrl!.startsWith('data:image')
                                        ? Image.memory(
                                            base64Decode(
                                              product.imageUrl!.split(',').last,
                                            ),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            product.imageUrl!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.image,
                                                        size: 50,
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        product.name,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
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
                                product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.spec,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '¥${product.price}',
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
                                      final category = DataManager()
                                          .getCategoryById(product.categoryId);
                                      DataManager().addToCart(
                                        CartItem(
                                          categoryId: product.categoryId,
                                          categoryName:
                                              category?.name ?? '未知分类',
                                          productName: product.name,
                                          price: product.price,
                                          brand: product.brand,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '已添加${product.name}到购物车',
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
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ==================== 会员中心页面 ====================

class MemberCenterPage extends StatelessWidget {
  const MemberCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = DataManager().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('会员中心'),
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null
          ? const Center(child: Text('请先登录'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 用户信息卡片
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isSuperAdmin
                                  ? '超级管理员'
                                  : user.isAdmin
                                  ? '管理员'
                                  : '普通会员',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 功能列表
                  _buildFunctionCard(
                    context,
                    '我的订单',
                    Icons.receipt_long,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryPage(),
                        ),
                      );
                    },
                  ),
                  _buildFunctionCard(
                    context,
                    '购物车',
                    Icons.shopping_cart,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  _buildFunctionCard(
                    context,
                    '我的收藏',
                    Icons.favorite,
                    Colors.red,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('收藏功能开发中...')),
                      );
                    },
                  ),
                  _buildFunctionCard(
                    context,
                    '地址管理',
                    Icons.location_on,
                    Colors.orange,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('地址管理功能开发中...')),
                      );
                    },
                  ),
                  if (user.isAdmin || user.isSuperAdmin)
                    _buildFunctionCard(
                      context,
                      '管理后台',
                      Icons.admin_panel_settings,
                      Colors.purple,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardPage(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFunctionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
