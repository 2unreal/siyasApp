import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final String correctPin;
  final VoidCallback? onUnlocked;

  const PinLockScreen({
    super.key,
    this.correctPin = '1234',
    this.onUnlocked,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  int _failedAttempts = 0;
  String? _errorMessage;

  void _onKeyPress(String digit) {
    if (_failedAttempts >= 5) {
      setState(() {
        _errorMessage = 'Too many attempts. Security lockout active.';
      });
      return;
    }

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    if (_enteredPin == widget.correctPin) {
      ref.read(authProvider.notifier).unlockApp();
      widget.onUnlocked?.call();
    } else {
      setState(() {
        _failedAttempts++;
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Attempt $_failedAttempts of 5.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivoryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 64),
                const SizedBox(height: 16),
                const Text(
                  'House of SIYA\'s',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryWine,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter 4-Digit Security PIN',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppColors.primaryWine : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? AppColors.primaryWine : AppColors.textSecondary,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),

                const SizedBox(height: 32),

                // Keypad
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      _buildKeyRow(['1', '2', '3']),
                      const SizedBox(height: 16),
                      _buildKeyRow(['4', '5', '6']),
                      const SizedBox(height: 16),
                      _buildKeyRow(['7', '8', '9']),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(Icons.clear, 'Clear', _onClear),
                          _buildNumberButton('0'),
                          _buildActionButton(Icons.backspace_outlined, 'Delete', _onBackspace),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberButton(d)).toList(),
    );
  }

  Widget _buildNumberButton(String digit) {
    return SizedBox(
      width: 64,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
          backgroundColor: Colors.white,
        ),
        onPressed: () => _onKeyPress(digit),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryWine),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 64,
      height: 64,
      child: IconButton(
        icon: Icon(icon, color: AppColors.textSecondary),
        onPressed: onPressed,
      ),
    );
  }
}
