import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ranking/data/repositories/ranking_repository.dart';
import '../../../ranking/presentation/providers/ranking_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.onSurface, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOTIFI-',
                          style: AppTypography.headlineLg.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          )),
                      Text('CAÇÕES',
                          style: AppTypography.headlineLg.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: AppColors.primary, size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Seção: Solicitações de amizade ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: AppColors.onSurfaceVariant, size: 16),
                  const SizedBox(width: 8),
                  Text('SOLICITAÇÕES DE AMIZADE',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      )),
                ],
              ),
            ),

            // ── Lista ────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
                onRefresh: () async {
                  ref.invalidate(pendingRequestsProvider);
                  ref.invalidate(pendingRequestsCountProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: requests.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off,
                          color: AppColors.onSurfaceVariant, size: 40),
                      const SizedBox(height: 12),
                      Text('Erro ao carregar',
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none,
                                color: AppColors.primary, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text('Tudo em dia!',
                              style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('Nenhuma solicitação pendente',
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        24, 8, 24,
                        80 + MediaQuery.of(context).padding.bottom),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RequestCard(
                      request: list[i],
                      onAccept: () async {
                        await ref
                            .read(rankingRepositoryProvider)
                            .acceptFriendRequest(list[i].requestId);
                        ref.invalidate(pendingRequestsProvider);
                        ref.invalidate(pendingRequestsCountProvider);
                        ref.invalidate(friendsRankingProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${list[i].requesterName} adicionado(a)!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      onReject: () async {
                        await ref
                            .read(rankingRepositoryProvider)
                            .rejectFriendRequest(list[i].requestId);
                        ref.invalidate(pendingRequestsProvider);
                        ref.invalidate(pendingRequestsCountProvider);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  final FriendRequestModel request;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _accepting = false;
  bool _rejecting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.5), width: 2),
              color: AppColors.surfaceContainerHigh,
            ),
            child: widget.request.requesterAvatar != null
                ? ClipOval(
                    child: Image.network(
                        widget.request.requesterAvatar!,
                        fit: BoxFit.cover))
                : const Icon(Icons.person,
                    color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.requesterName.toUpperCase(),
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.request.requesterPoints} pts',
                  style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'quer ser seu amigo',
                  style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11),
                ),
              ],
            ),
          ),

          // Botões
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Aceitar
              GestureDetector(
                onTap: _accepting || _rejecting
                    ? null
                    : () async {
                        setState(() => _accepting = true);
                        await widget.onAccept();
                      },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _accepting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary),
                          ))
                      : Text('ACEITAR',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
              const SizedBox(height: 6),
              // Recusar
              GestureDetector(
                onTap: _accepting || _rejecting
                    ? null
                    : () async {
                        setState(() => _rejecting = true);
                        await widget.onReject();
                      },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: _rejecting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error),
                          ))
                      : Text('RECUSAR',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
