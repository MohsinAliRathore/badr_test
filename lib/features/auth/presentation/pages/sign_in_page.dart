import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthSignInSubmitted(
            email: _email.text,
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3D2E), Color(0xFF145C45), Color(0xFF1A6B52)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state.status == AuthStatus.loading ||
                        state.status == AuthStatus.unknown;
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'badrgo',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ops Console',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            enabled: !loading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Email required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            enabled: !loading,
                            obscureText: _obscure,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Password required' : null,
                          ),
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Material(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Sign in'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
