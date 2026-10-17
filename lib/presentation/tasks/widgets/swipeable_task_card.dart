import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/task_status.dart';
import '../../../data/models/task_model.dart';
import '../utils/task_status_style.dart';

/// Thẻ Task hỗ trợ cử chỉ vuốt ngang để đổi trạng thái nhanh (US-066).
///
/// Widget độc lập, KHÔNG phụ thuộc Bloc hoặc Firebase.
/// - Hướng vuốt theo trạng thái hiện tại:
///   * 'To Do'       -> chỉ vuốt sang phải (startToEnd) chuyển sang 'In Progress'
///   * 'In Progress' -> vuốt sang phải chuyển 'Done', vuốt sang trái chuyển 'To Do'
///   * 'Done'        -> chỉ vuốt sang trái (endToStart) chuyển về 'In Progress'
/// - Vuốt đủ ngưỡng (35%) kích hoạt rung phản hồi và gọi [onStatusChange]. Thẻ
///   không bị xoá khỏi cây widget (`confirmDismiss` trả về `false`).
class SwipeableTaskCard extends StatefulWidget {
  final TaskModel task;
  final Widget child;
  final void Function(String newStatus) onStatusChange;

  const SwipeableTaskCard({
    super.key,
    required this.task,
    required this.child,
    required this.onStatusChange,
  });

  @override
  State<SwipeableTaskCard> createState() => _SwipeableTaskCardState();
}

class _SwipeableTaskCardState extends State<SwipeableTaskCard> {
  bool _thresholdReached = false;

  void _handleUpdate(DismissUpdateDetails details) {
    if (details.reached && !_thresholdReached) {
      _thresholdReached = true;
      HapticFeedback.selectionClick();
    } else if (!details.reached && _thresholdReached) {
      _thresholdReached = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = TaskStatus.normalize(widget.task.status);
    final nextStatus = TaskStatus.next(status);
    final prevStatus = TaskStatus.previous(status);

    final DismissDirection direction;
    if (status == TaskStatus.todo) {
      direction = DismissDirection.startToEnd;
    } else if (status == TaskStatus.inProgress) {
      direction = DismissDirection.horizontal;
    } else if (status == TaskStatus.done) {
      direction = DismissDirection.endToStart;
    } else {
      direction = DismissDirection.none;
    }

    final customActions = <CustomSemanticsAction, VoidCallback>{};
    if (nextStatus != null) {
      customActions[CustomSemanticsAction(label: 'Chuyển sang $nextStatus')] = () {
        widget.onStatusChange(nextStatus);
      };
    }
    if (prevStatus != null) {
      customActions[CustomSemanticsAction(label: 'Chuyển sang $prevStatus')] = () {
        widget.onStatusChange(prevStatus);
      };
    }

    return Semantics(
      customSemanticsActions: customActions,
      child: Dismissible(
        key: ValueKey('swipe_${widget.task.id}'),
        direction: direction,
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.35,
          DismissDirection.endToStart: 0.35,
        },
        onUpdate: _handleUpdate,
        confirmDismiss: (dismissDirection) async {
          _thresholdReached = false;
          final String? target;
          if (dismissDirection == DismissDirection.startToEnd) {
            target = nextStatus;
          } else if (dismissDirection == DismissDirection.endToStart) {
            target = prevStatus;
          } else {
            target = null;
          }

          if (target != null) {
            HapticFeedback.mediumImpact();
            widget.onStatusChange(target);
          }
          return false;
        },
        background: _buildBackground(
          context: context,
          targetStatus: nextStatus,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildBackground(
          context: context,
          targetStatus: prevStatus,
          alignment: Alignment.centerRight,
        ),
        child: widget.child,
      ),
    );
  }

  Widget _buildBackground({
    required BuildContext context,
    required String? targetStatus,
    required Alignment alignment,
  }) {
    if (targetStatus == null) return const SizedBox.shrink();

    final color = taskStatusColor(context, targetStatus);
    final icon = taskStatusIcon(targetStatus);
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) ...[
            Flexible(
              child: Text(
                targetStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.white, size: 16),
          ] else ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                targetStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
