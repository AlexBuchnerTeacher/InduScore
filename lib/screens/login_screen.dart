import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/rbs_theme.dart';
import '../core/widgets/rbs_components.dart';

/// Login Screen - RBS Cover-Ebene Design
/// 
/// Gemäß RBS Styleguide 1.2:
/// - Dynamic Red Hintergrund (verpflichtend)
/// - Keyvisual (45° Pattern)
/// - Tag "#notentool" rechts oben
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
      // TODO: Implement Firebase Auth login
      // final authService = ref.read(authServiceProvider);
      // await authService.signInWithEmailPassword(
      //   email: _emailController.text.trim(),
      //   password: _passwordController.text,
      // );
      
      await Future.delayed(const Duration(seconds: 1)); // Placeholder
      
      if (mounted) {
        // Navigation wird durch authStateProvider automatisch getriggert
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
          
          // TAG: #notentool (rechts oben)
          Positioned(
            top: RBSSpacing.lg,
            right: RBSSpacing.lg,
            child: RBSTag(
              label: '#notentool',
              color: RBSColors.white,
            ),
          ),
          
          // CONTENT: Login-Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? RBSSpacing.md : RBSSpacing.xxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADLINE (Roboto Condensed Bold, weiß)
                    Text(
                      'Notentool Web',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: RBSColors.textOnRed,
                        fontSize: isMobile ? 32 : 48,
                      ),
                    ),
                    const SizedBox(height: RBSSpacing.sm),
                    
                    // SUBHEADLINE (Roboto Condensed Bold, weiß)
                    Text(
                      'Bewertungen. Klassen. Übersicht.',
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: RBSColors.textOnRed,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: RBSSpacing.xxl),
                    
                    // LOGIN-CARD (weißer Bereich)
                    Container(
                      padding: EdgeInsets.all(isMobile ? RBSSpacing.lg : RBSSpacing.xl),
                      decoration: BoxDecoration(
                        color: RBSColors.white,
                        borderRadius: BorderRadius.circular(RBSBorderRadius.medium),
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
                            // E-Mail Input
                            RBSInput(
                              label: 'E-Mail',
                              hint: 'lehrer@berufsschule.de',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte E-Mail eingeben';
                                }
                                if (!value.contains('@')) {
                                  return 'Ungültige E-Mail-Adresse';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: RBSSpacing.md),
                            
                            // Passwort Input
                            RBSInput(
                              label: 'Passwort',
                              hint: '••••••••',
                              controller: _passwordController,
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
                            
                            if (_errorMessage != null) ...[
                              const SizedBox(height: RBSSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(RBSSpacing.sm),
                                decoration: BoxDecoration(
                                  color: RBSColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(RBSBorderRadius.small),
                                  border: Border.all(
                                    color: RBSColors.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: RBSColors.error,
                                  ),
                                ),
                              ),
                            ],
                            
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
                            
                            // Passwort vergessen Link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Passwort-Reset-Dialog
                                },
                                child: Text(
                                  'Passwort vergessen?',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: RBSColors.dynamicRed,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
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
