import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.fieldKey,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.action,
    this.helper,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.last = false,
    super.key,
  });

  final String label;
  final String fieldKey;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Widget? action;
  final Widget? helper;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                label: label,
                child: TextFormField(
                  key: ValueKey(fieldKey),
                  controller: controller,
                  focusNode: focusNode,
                  validator: validator,
                  obscureText: obscureText,
                  enabled: enabled,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textInputAction: last
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onFieldSubmitted: onSubmitted,
                  onChanged: onChanged,
                  scrollPadding: const EdgeInsets.all(90),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    suffixIcon: suffixIcon,
                    errorText: errorText,
                  ),
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 9), action!],
          ],
        ),
        if (helper != null) ...[const SizedBox(height: 7), helper!],
      ],
    ),
  );
}
