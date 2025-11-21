import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';
import '../providers/app_providers.dart';

/// Login Screen - RBS Cover-Ebene Design
///
/// Gemäß RBS Styleguide 1.2:
/// - Dynamic Red Hintergrund (verpflichtend)
/// - Keyvisual (45° Pattern)
/// - Tag "#induscore" rechts oben
/// - Headline + Subheadline (Roboto Condensed Bold)
/// - Weißer Login-Bereich mit RBS-Inputs
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final input = _emailController.text.trim();

      // Wenn Kürzel (2-4 Buchstaben ohne @), konvertiere zu Email
      final email = input.contains('@')
          ? input
          : '${input.toLowerCase()}@induscore.de';

      await authService.signInWithEmailPassword(
        email: email,
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/'); // Navigate to home after successful login
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPasswordResetDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => RBSDialog(
        title: 'Passwort zurücksetzen',
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Geben Sie Ihre E-Mail-Adresse oder Ihr Lehrerkürzel ein. Sie erhalten einen Link zum Zurücksetzen Ihres Passworts.',
                style: RBSTypography.bodyMedium,
              ),
              const SizedBox(height: RBSSpacing.lg),
              RBSInput(
                label: 'E-Mail oder Lehrerkürzel',
                hint: 'BU oder lehrer@berufsschule.de',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte E-Mail oder Kürzel eingeben';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          RBSButton(
            label: 'Link senden',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final authService = ref.read(authServiceProvider);
                  final input = emailController.text.trim();

                  // Kürzel-Konvertierung wie beim Login
                  final email = input.contains('@')
                      ? input
                      : '${input.toLowerCase()}@induscore.de';

                  await authService.sendPasswordResetEmail(email);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Passwort-Reset-Link wurde gesendet. Bitte prüfen Sie Ihre E-Mails.',
                        ),
                        backgroundColor: RBSColors.courtGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: RBSColors.dynamicRed,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showRegisterDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await RBSDialog.show(
      context: context,
      title: 'Konto erstellen',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RBSInput(
              label: 'E-Mail oder Lehrerkürzel',
              hint: 'BU oder lehrer@berufsschule.de',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.person_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte E-Mail oder Kürzel eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: RBSSpacing.md),
            RBSInput(
              label: 'Passwort',
              hint: '••••••',
              controller: passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Passwort eingeben';
                }
                if (value.length < 6) {
                  return 'Passwort muss mindestens 6 Zeichen lang sein';
                }
                return null;
              },
            ),
            const SizedBox(height: RBSSpacing.md),
            RBSInput(
              label: 'Passwort bestätigen',
              hint: 'Passwort wiederholen',
              controller: confirmPasswordController,
              obscureText: true,
              prefixIcon: Icons.lock_outlined,
              validator: (value) {
                if (value != passwordController.text) {
                  return 'Passwörter stimmen nicht überein';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        RBSButton(
          label: 'Registrieren',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;

            try {
              final authService = ref.read(authServiceProvider);
              final input = emailController.text.trim();

              // Wenn Kürzel (2-4 Buchstaben ohne @), konvertiere zu Email
              final email = input.contains('@')
                  ? input
                  : '${input.toLowerCase()}@induscore.de';

              await authService.registerWithEmailPassword(
                email: email,
                password: passwordController.text,
              );

              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konto erfolgreich erstellt!'),
                    backgroundColor: RBSColors.success,
                  ),
                );
                context.go('/'); // Navigate to home
              }
            } catch (e) {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: RBSColors.error,
                  ),
                );
              }
            }
          },
        ),
      ],
    );

    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // COVER-EBENE: Dynamic Red Hintergrund
          Container(
            width: double.infinity,
            height: double.infinity,
            color: RBSColors.dynamicRed,
          ),

          // KEYVISUAL: 45° Pattern (vereinfacht als Streifen)
          Positioned(
            right: -100,
            top: -100,
            child: Transform.rotate(
              angle: 0.785398, // 45° in Radiant
              child: Container(
                width: 400,
                height: size.height + 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),

          // TAG: #induscore (rechts oben)
          Positioned(
            top: RBSSpacing.lg,
            right: RBSSpacing.lg,
            child: RBSTag(label: '#induscore', color: RBSColors.white),
          ),

          // CONTENT: Login-Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? RBSSpacing.md : RBSSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADLINE (Roboto Condensed Bold, weiß)
                    Text(
                      'InduScore',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: RBSColors.textOnRed,
                        fontSize: isMobile ? 32 : 48,
                      ),
                    ),
                    const SizedBox(height: RBSSpacing.sm),

                    // SUBHEADLINE (Roboto Condensed Bold, weiß)
                    Text(
                      'Bewertungen. Klassen. Übersicht.',
                      style: Theme.of(context).textTheme.headlineMedium!
                          .copyWith(
                            color: RBSColors.textOnRed,
                            fontWeight: FontWeight.w400,
                          ),
                    ),

                    const SizedBox(height: RBSSpacing.xxl),

                    // LOGIN-CARD (weißer Bereich)
                    Container(
                      padding: EdgeInsets.all(
                        isMobile ? RBSSpacing.lg : RBSSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        color: RBSColors.white,
                        borderRadius: BorderRadius.circular(
                          RBSBorderRadius.medium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // E-Mail oder Lehrerkürzel Input
                            RBSInput(
                              label: 'E-Mail oder Lehrerkürzel',
                              hint: 'BU oder lehrer@berufsschule.de',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.person_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte E-Mail oder Kürzel eingeben';
                                }
                                // Kein Validierungs-Zwang - Backend prüft
                                return null;
                              },
                            ),

                            const SizedBox(height: RBSSpacing.md),

                            // Passwort Input
                            RBSInput(
                              label: 'Passwort',
                              hint: '••••••',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_outlined,
                              onSubmitted: (_) => _handleLogin(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte Passwort eingeben';
                                }
                                if (value.length < 6) {
                                  return 'Passwort muss mindestens 6 Zeichen lang sein';
                                }
                                return null;
                              },
                            ),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  'Fehler: ${_errorMessage!.replaceAll("Exception:", "").replaceAll("FirebaseAuthException:", "").replaceAll("[firebase_auth/", "").replaceAll("]", "").trim()}',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: RBSSpacing.lg),

                            // Login Button (RBS Dynamic Red)
                            SizedBox(
                              width: double.infinity,
                              child: RBSButton(
                                label: 'Anmelden',
                                onPressed: _handleLogin,
                                isLoading: _isLoading,
                                icon: Icons.login,
                              ),
                            ),

                            const SizedBox(height: RBSSpacing.md),

                            // Registrierung & Passwort vergessen
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: _showRegisterDialog,
                                    child: Text(
                                      'Konto erstellen',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: RBSColors.dynamicRed,
                                            decoration: TextDecoration.underline,
                                          ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        _showPasswordResetDialog(context, ref),
                                    child: Text(
                                      'Passwort vergessen?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: RBSColors.dynamicRed,
                                            decoration: TextDecoration.underline,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: RBSSpacing.lg),

                    // Info-Text (weiß)
                    Center(
                      child: Text(
                        'Referat für Bildung und Sport\nLandeshauptstadt München',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: RBSColors.textOnRed.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
