import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _keyWarningAcknowledged = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre environnement numérique vous suit partout',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Avertissement clé privée
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.key, color: AppColors.warning, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Clé de chiffrement privée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Une clé privée sera générée et vous sera communiquée UNE SEULE FOIS. Sauvegardez-la dans un endroit sûr — elle ne peut pas être récupérée.',
                        style: TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _keyWarningAcknowledged,
                            onChanged: (v) => setState(
                                () => _keyWarningAcknowledged = v ?? false),
                            activeColor: AppColors.warning,
                          ),
                          const Expanded(
                            child: Text(
                              "J'ai compris et je sauvegarderai ma clé privée",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Prénom
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 14),

                // Nom
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom de famille',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirmation
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                if (authState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: (authState.isLoading || !_keyWarningAcknowledged)
                      ? null
                      : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
