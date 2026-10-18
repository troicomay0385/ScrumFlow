import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_retro_item_model.dart';
import '../bloc/retro_bloc.dart';
import '../bloc/retro_event.dart';
import '../bloc/retro_state.dart';

/// Card Slider hiển thị danh sách ý kiến Retro theo 1 cột dưới dạng PageView ngang.
/// Double Tap vào thẻ → bắn [VoteRetroOpinionEvent] + animation tim nảy nhẹ.
class RetroOpinionSlider extends StatelessWidget {
  final List<SprintRetroItemModel> items;
  final String currentUserId;
  final Color accentColor;
  final Color cardBg;
  final String emptyMsg;

  const RetroOpinionSlider({
    super.key,
    required this.items,
    required this.currentUserId,
    required this.accentColor,
    required this.cardBg,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined,
                  size: 56, color: accentColor.withValues(alpha: 0.4)),
              const SizedBox(height: 14),
              Text(
                emptyMsg,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final state = context.watch<RetroBloc>().state;
    final votedId = state is RetroVoteAnimated ? state.votedOpinionId : null;

    return PageView.builder(
      controller: PageController(viewportFraction: 0.85),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isAnimating = votedId == item.id;
        return _RetroCard(
          item: item,
          currentUserId: currentUserId,
          accentColor: accentColor,
          cardBg: cardBg,
          isVoteAnimating: isAnimating,
        );
      },
    );
  }
}

/// Một thẻ ý kiến Retro với GestureDetector double-tap để vote.
class _RetroCard extends StatefulWidget {
  final SprintRetroItemModel item;
  final String currentUserId;
  final Color accentColor;
  final Color cardBg;
  final bool isVoteAnimating;

  const _RetroCard({
    required this.item,
    required this.currentUserId,
    required this.accentColor,
    required this.cardBg,
    required this.isVoteAnimating,
  });

  @override
  State<_RetroCard> createState() => _RetroCardState();
}

class _RetroCardState extends State<_RetroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _heartController, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(covariant _RetroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVoteAnimating && !oldWidget.isVoteAnimating) {
      _heartController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onDoubleTap(BuildContext context) {
    context.read<RetroBloc>().add(VoteRetroOpinionEvent(
          opinionId: widget.item.id,
          userId: widget.currentUserId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasVoted = item.voterIds.contains(widget.currentUserId);
    final accent = widget.accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: GestureDetector(
        onDoubleTap: () => _onDoubleTap(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Thân thẻ ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge cột
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.column.label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nội dung
                  Expanded(
                    child: Text(
                      item.content,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Footer: tác giả + vote
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: accent.withValues(alpha: 0.15),
                        child: Text(
                          item.authorName.isNotEmpty
                              ? item.authorName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.authorName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // Vote badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasVoted
                              ? accent.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasVoted
                                ? accent
                                : AppColors.outline.withValues(alpha: 0.25),
                            width: hasVoted ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasVoted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15,
                              color: hasVoted
                                  ? accent
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${item.votesCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: hasVoted
                                    ? accent
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hint double tap
                  Center(
                    child: Text(
                      'Double tap để vote ❤️',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Overlay animation tim khi double tap ──
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _heartController,
                builder: (_, child) {
                  if (!_heartController.isAnimating &&
                      _heartController.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Opacity(
                    opacity: _fadeAnim.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 80,
                        color: widget.accentColor.withValues(alpha: 0.85),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
