import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/optimization_model.dart';
import 'optimization_details_bottom_sheet.dart';

class OptimizationHistoryListItem extends StatelessWidget {
  final OptimizationModel opt;
  final String genName;
  final List<dynamic> generators;
  final VoidCallback onDelete;

  const OptimizationHistoryListItem({
    super.key,
    required this.opt,
    required this.genName,
    required this.generators,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(opt.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showOptimizationDetailsBottomSheet(context, opt, genName, generators),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Иконка слева
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.trending_down, color: Colors.blue.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              
              // Центральная часть: название, дата, комментарий
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      genName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    if (opt.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        opt.comment,
                        maxLines: 2, // 🆕 ИЗМЕНЕНО: увеличено с 1 до 2 строк
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ]
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Правая часть: сумма и кнопка удаления
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '-${opt.fuelAmount.toStringAsFixed(2)} л',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}