import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hide = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _hide,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        final key = widget.validator?.call(value);
        return key?.tr;
      },
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label.tr,
        suffixIcon: widget.obscure
            ? IconButton(
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(
                  _hide ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                ),
              )
            : null,
      ),
    );
  }
}

class OtpField extends StatelessWidget {
  const OtpField({required this.controller, required this.validator, super.key});

  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        final key = validator?.call(value);
        return key?.tr;
      },
      style: context.text.headlineSmall,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: 'auth.otp'.tr,
        counterText: '',
      ),
    );
  }
}
