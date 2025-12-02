import 'package:flutter/material.dart';
import '../../models/land_parcel.dart';
import '../../utils/colors.dart';

class ParcelEditDialog extends StatefulWidget {
  final LandParcel parcel;
  final List<String> availableCropTypes;

  const ParcelEditDialog({
    super.key,
    required this.parcel,
    required this.availableCropTypes,
  });

  @override
  State<ParcelEditDialog> createState() => _ParcelEditDialogState();
}

class _ParcelEditDialogState extends State<ParcelEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _cropTypeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.parcel.name);
    _cropTypeController = TextEditingController(text: widget.parcel.cropType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cropTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تعديل بيانات الأرض',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الأرض',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم الأرض';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue:
                    TextEditingValue(text: widget.parcel.cropType ?? ''),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return widget.availableCropTypes.where((String option) {
                    return option.contains(textEditingValue.text);
                  });
                },
                onSelected: (String selection) {
                  _cropTypeController.text = selection;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  // Sync initial value if needed
                  if (controller.text.isEmpty &&
                      _cropTypeController.text.isNotEmpty) {
                    controller.text = _cropTypeController.text;
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'نوع المحصول',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grass),
                    ),
                    onChanged: (value) {
                      _cropTypeController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updatedParcel = widget.parcel.copyWith(
        name: _nameController.text.trim(),
        cropType: _cropTypeController.text.trim().isEmpty
            ? null
            : _cropTypeController.text.trim(),
      );
      Navigator.pop(context, updatedParcel);
    }
  }
}
