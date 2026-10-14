import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// Skeleton loading cho danh sách (US-064): vài khối giả lập thẻ nội dung
/// "nhấp nháy" nhẹ trong lúc chờ dữ liệu lần đầu.
///
/// Chỉ dùng **một** [AnimationController] + [FadeTransition] cho cả danh
/// sách (không rebuild từng khung hình), nên nhẹ trên máy cấu hình thấp. Khi
/// người dùng bật "Giảm chuyển động" (`MediaQuery.disableAnimations`), khối
/// skeleton đứng yên.
class SkeletonList extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải dữ liệu',
      liveRegion: true,
      child: FadeTransition(
        opacity: _controller,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _SkeletonCard(
            height: widget.itemHeight,
            // Độ dài dòng chữ giả thay đổi nhẹ cho tự nhiên.
            titleFactor: index.isEven ? 0.7 : 0.55,
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  final double titleFactor;

  const _SkeletonCard({required this.height, required this.titleFactor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const _Block(width: 40, height: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Block(width: constraints.maxWidth * titleFactor, height: 12),
                  const SizedBox(height: 10),
                  _Block(width: constraints.maxWidth * 0.9, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Block({required this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
