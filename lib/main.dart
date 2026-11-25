import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ВАЖЛИВО: замініть на свій субдомен з https://requestcatcher.com/
const String kSubdomain = 'lab13-okhman';
const String kBaseUrl = 'https://$kSubdomain.requestcatcher.com';

void main() {
  runApp(const AuthApp());
}

/// Сервіс для взаємодії з бекендом через dio
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<void> login(String email, String password) =>
      _dio.post('/login', data: {'email': email, 'password': password});

  Future<void> signUp(String name, String email, String password) =>
      _dio.post('/signup',
          data: {'name': name, 'email': email, 'password': password});

  Future<void> resetPassword(String email) =>
      _dio.post('/reset', data: {'email': email});
}

/// Виконує запит, показує SnackBar з результатом
Future<void> sendRequest(
    BuildContext context,
    Future<void> Function() request,
    String successMessage,
    ) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await request();
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  } on DioException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Помилка запиту: ${e.message ?? e.type.name}')),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Помилка: $e')));
  }
}

class AuthApp extends StatelessWidget {
  const AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.grey[50],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

// Допоміжні функції валідації
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Будь ласка, введіть Email';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Введіть коректну електронну пошту (наприклад, user@mail.com)';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Будь ласка, введіть пароль';
  }
  if (value.length < 7) {
    return 'Пароль має бути не менше 7 символів';
  }
  return null;
}

/// Кнопка з індикатором завантаження
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      )
          : Text(label),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await sendRequest(
      context,
          () => ApiService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      ),
      'Дані входу надіслано!',
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://cdni.iconscout.com/illustration/premium/thumb/user-login-illustration-download-in-svg-png-gif-file-formats--security-password-account-access-mobile-pack-network-illustrations-5749293.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.deepPurple),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Вхід у систему',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Електронна пошта',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Увійти',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot'),
                  child: const Text('Забули пароль?'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Створити акаунт (Реєстрація)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await sendRequest(
      context,
          () => ApiService.instance.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      ),
      'Дані реєстрації надіслано!',
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Реєстрація нового користувача',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Ім'я користувача",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Введіть ваше ім'я";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Електронна пошта',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль (мін. 7 символів)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Зареєструватися',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Вже маєте акаунт? Увійти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await sendRequest(
      context,
          () => ApiService.instance.resetPassword(_emailController.text.trim()),
      'Запит на скидання пароля надіслано!',
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Відновлення паролю')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset,
                    size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text(
                  'Забули пароль?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Введіть електронну пошту для скидання пароля.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Електронна пошта',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  loading: _loading,
                  onPressed: _submit,
                  label: 'Скинути пароль',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Повернутися до входу'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}