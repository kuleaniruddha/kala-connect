import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/profile/artisan_follow_repository.dart';
import '../features/auth/email_auth_dialog.dart';
import '../state/app_flow_controller.dart';
import '../state/auth_controller.dart';
import '../theme/kala_theme.dart';

class ArtisanFollowButton extends StatefulWidget {
  const ArtisanFollowButton({
    required this.artisanId,
    this.artisanName = 'Artisan',
    this.showCount = true,
    super.key,
  });

  final String artisanId;
  final String artisanName;
  final bool showCount;

  @override
  State<ArtisanFollowButton> createState() => _ArtisanFollowButtonState();
}

class _ArtisanFollowButtonState extends State<ArtisanFollowButton> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final appFlow = context.watch<AppFlowController>();
    final followRepo = context.read<ArtisanFollowRepository>();
    final userId = auth.identity?.uid;
    final currentProfileName = appFlow.profile?.name.trim().toLowerCase();
    final targetName = widget.artisanName.trim().toLowerCase();

    final targetArtisanId = widget.artisanId.isNotEmpty
        ? widget.artisanId
        : targetName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final isSameAccount = userId != null && (
      (widget.artisanId.isNotEmpty && (userId == widget.artisanId || appFlow.isBoundTo(widget.artisanId))) ||
      (currentProfileName != null && currentProfileName.isNotEmpty && currentProfileName == targetName)
    );

    if (isSameAccount) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: 'You cannot follow your own account',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Follow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showCount) ...[
            const SizedBox(height: 3),
            StreamBuilder<int>(
              stream: followRepo.watchFollowerCount(artisanId: targetArtisanId),
              builder: (context, countSnapshot) {
                final count = countSnapshot.data ?? 0;
                return Text(
                  count == 1 ? '1 follower' : '$count followers',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B6572),
                  ),
                );
              },
            ),
          ],
        ],
      );
    }

    return StreamBuilder<bool>(
      stream: followRepo.isFollowing(artisanId: targetArtisanId, userId: userId),
      builder: (context, followSnapshot) {
        final isFollowing = followSnapshot.data ?? false;

        return StreamBuilder<int>(
          stream: followRepo.watchFollowerCount(artisanId: targetArtisanId),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isToggling
                        ? null
                        : () async {
                            if (!auth.isSignedIn) {
                              final signedIn = await EmailAuthDialog.show(context);
                              if (!context.mounted || !signedIn) return;
                            }

                            setState(() => _isToggling = true);
                            try {
                              final currentUserId = context.read<AuthController>().identity?.uid;
                              if (currentUserId != null) {
                                final nowFollowing = await followRepo.toggleFollow(
                                  artisanId: targetArtisanId,
                                  userId: currentUserId,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      nowFollowing
                                          ? 'Now following ${widget.artisanName}!'
                                          : 'Unfollowed ${widget.artisanName}',
                                    ),
                                    backgroundColor: nowFollowing ? KalaColors.leaf : Colors.black87,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isToggling = false);
                            }
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? KalaColors.leaf.withValues(alpha: 0.12)
                            : KalaColors.terracotta,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFollowing ? KalaColors.leaf : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFollowing ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                            size: 14,
                            color: isFollowing ? KalaColors.leaf : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isFollowing ? KalaColors.leaf : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.showCount) ...[
                  const SizedBox(height: 3),
                  Text(
                    count == 1 ? '1 follower' : '$count followers',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B6572),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
