import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/ranking_provider.dart';
import '../../data/models/ranking_model.dart';
import '../../data/repositories/ranking_repository.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  bool _isGlobal = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddFriend() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFriendSheet(
        onFriendAdded: () {
          ref.invalidate(friendsRankingProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(
        _isGlobal ? globalRankingProvider : friendsRankingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L.of(context).rank_elite,
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              )),
                          Text(L.of(context).rank_titulo,
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                      const Spacer(),
                      // Botão adicionar amigo (só na aba amigos)
                      if (!_isGlobal)
                        GestureDetector(
                          onTap: _openAddFriend,
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.person_add_outlined,
                                color: AppColors.primary, size: 20),
                          ),
                        ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: AppColors.primary, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Toggle chips ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.surfaceContainerHigh),
                    ),
                    child: Row(
                      children: [
                        _ToggleChip(
                          label: L.of(context).rank_global,
                          active: _isGlobal,
                          onTap: () => setState(() {
                            _isGlobal = true;
                            _searchCtrl.clear();
                            _query = '';
                          }),
                        ),
                        _ToggleChip(
                          label: L.of(context).rank_amigos,
                          active: !_isGlobal,
                          onTap: () => setState(() {
                            _isGlobal = false;
                            _searchCtrl.clear();
                            _query = '';
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Search ─────────────────────────────────────
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: AppColors.surfaceContainerHigh),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTypography.bodyMd,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: L.of(context).rank_buscarAtleta,
                        hintStyle: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.onSurfaceVariant, size: 18),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: ranking.when(
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
                    Text(L.of(context).rank_erroCarregar,
                        style: AppTypography.bodyMd),
                  ],
                )),
                data: (list) {
                  final filtered = _query.isEmpty
                      ? list
                      : list
                          .where((e) => e.userName
                              .toLowerCase()
                              .contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline,
                              color: AppColors.onSurfaceVariant,
                              size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _isGlobal
                                ? L.of(context).rank_nenhumCompetidor
                                : L.of(context).rank_adicioneAmigos,
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                          if (!_isGlobal) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openAddFriend,
                              icon: const Icon(Icons.person_add, size: 18),
                              label: Text(L.of(context).rank_adicionarAmigo),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      if (filtered.length >= 3 && _query.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: _Podium(
                                top3: filtered.take(3).toList()),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(24, 8, 24,
                            80 + MediaQuery.of(context).padding.bottom),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final start = (filtered.length >= 3 &&
                                      _query.isEmpty)
                                  ? 3
                                  : 0;
                              final idx = i + start;
                              if (idx >= filtered.length) return null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _AthleteRow(
                                    entry: filtered[idx],
                                    isGlobal: _isGlobal,
                                    onRemoveFriend: !_isGlobal
                                        ? () async {
                                            await ref
                                                .read(
                                                    rankingRepositoryProvider)
                                                .removeFriend(
                                                    filtered[idx].userId);
                                            ref.invalidate(
                                                friendsRankingProvider);
                                          }
                                        : null),
                              );
                            },
                            childCount:
                                filtered.length >= 3 && _query.isEmpty
                                    ? filtered.length - 3
                                    : filtered.length,
                          ),
                        ),
                      ),
                    ],
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

// ── Add Friend Sheet ──────────────────────────────────────────────────────────

class _AddFriendSheet extends ConsumerStatefulWidget {
  final VoidCallback onFriendAdded;
  const _AddFriendSheet({required this.onFriendAdded});

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _ctrl   = TextEditingController();
  List<UserSearchResult> _results  = [];
  final Set<String> _loadingIds    = {};
  final Set<String> _addedIds      = {};
  bool _isSearching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final r = await ref.read(rankingRepositoryProvider).searchUsers(q);
      if (mounted) setState(() => _results = r);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _addFriend(UserSearchResult user) async {
    setState(() => _loadingIds.add(user.userId));
    try {
      await ref.read(rankingRepositoryProvider).sendFriendRequest(user.userId);
      if (mounted) {
        setState(() {
          _addedIds.add(user.userId);
          _loadingIds.remove(user.userId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingIds.remove(user.userId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L.of(context).comum_erro}: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.of(context).rank_adicionar,
                          style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700)),
                      Text(L.of(context).rank_amigo,
                          style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: AppTypography.bodyMd,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: L.of(context).rank_buscarPorNome,
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.onSurfaceVariant, size: 20),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ))
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Results
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: _results.isEmpty && !_isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search,
                              color: AppColors.onSurfaceVariant, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            _ctrl.text.length < 2
                                ? L.of(context).rank_digite2Letras
                                : L.of(context).rank_nenhumUsuario,
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final user = _results[i];
                        final isAdded  = _addedIds.contains(user.userId) || user.isFriend;
                        final isPending = !isAdded && (_addedIds.contains(user.userId) || user.isPending);
                        final isLoading = _loadingIds.contains(user.userId);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isAdded
                                ? AppColors.primary.withOpacity(0.07)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAdded
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.surfaceContainerHigh,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceContainerHigh,
                                  border: Border.all(
                                      color: AppColors.outlineVariant),
                                ),
                                child: user.avatarUrl != null
                                    ? ClipOval(
                                        child: Image.network(user.avatarUrl!,
                                            fit: BoxFit.cover))
                                    : const Icon(Icons.person,
                                        color: AppColors.onSurfaceVariant,
                                        size: 20),
                              ),
                              const SizedBox(width: 12),
                              // Name & points
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(user.userName,
                                        style:
                                            AppTypography.bodyMd.copyWith(
                                          fontWeight: FontWeight.w600,
                                        )),
                                    Text('${user.totalPoints} ${L.of(context).rank_pts}',
                                        style:
                                            AppTypography.bodySm.copyWith(
                                          color:
                                              AppColors.onSurfaceVariant,
                                        )),
                                  ],
                                ),
                              ),
                              // Action button
                              if (isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                )
                              else if (isAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check,
                                          size: 12,
                                          color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(L.of(context).rank_amigo,
                                          style: AppTypography.labelSm.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ],
                                  ),
                                )
                              else if (isPending || user.isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.onSurfaceVariant.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.onSurfaceVariant.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 12,
                                          color: AppColors.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(L.of(context).rank_aguardando,
                                          style: AppTypography.labelSm.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ],
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () => _addFriend(user),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(L.of(context).rank_maisAdicionar,
                                        style: AppTypography.labelSm
                                            .copyWith(
                                          color: AppColors.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ),
                            ],
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

// ── Toggle chip ───────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMd.copyWith(
              color: active
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<RankingEntryModel> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final second = top3[1];
    final first  = top3[0];
    final third  = top3[2];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.surfaceContainerLowest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumColumn(entry: second, height: 80,  place: 2),
          _PodiumColumn(entry: first,  height: 112, place: 1),
          _PodiumColumn(entry: third,  height: 64,  place: 3),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final RankingEntryModel entry;
  final double height;
  final int place;
  const _PodiumColumn(
      {required this.entry, required this.height, required this.place});

  Color get _placeColor {
    switch (place) {
      case 1:  return const Color(0xFFFFD700);
      case 2:  return const Color(0xFFC0C0C0);
      case 3:  return const Color(0xFFCD7F32);
      default: return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: place == 1 ? 64 : 52,
              height: place == 1 ? 64 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _placeColor, width: 2.5),
                color: AppColors.surfaceContainerHigh,
              ),
              child: entry.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(entry.avatarUrl!,
                          fit: BoxFit.cover))
                  : Icon(Icons.person,
                      color: _placeColor,
                      size: place == 1 ? 32 : 24),
            ),
            if (entry.isCurrentUser)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: AppColors.onPrimary, size: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.userName.split(' ').first.toUpperCase(),
          style: AppTypography.labelSm.copyWith(
            fontSize: place == 1 ? 11 : 9,
            color: entry.isCurrentUser
                ? AppColors.primary
                : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text('${entry.points}',
            style:
                AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
        const SizedBox(height: 6),
        Container(
          width: place == 1 ? 80 : 64,
          height: height,
          decoration: BoxDecoration(
            color: _placeColor.withOpacity(0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            // Borda uniforme: o Flutter não permite borderRadius com bordas de
            // cores diferentes por lado. O topo destacado vira um boxShadow.
            border: Border.all(color: _placeColor.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: _placeColor.withOpacity(0.5),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: Text('#$place',
                style: AppTypography.headlineSm.copyWith(
                  color: _placeColor,
                  fontSize: place == 1 ? 22 : 16,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ],
    );
  }
}

// ── Athlete row ───────────────────────────────────────────────────────────────

class _AthleteRow extends StatelessWidget {
  final RankingEntryModel entry;
  final bool isGlobal;
  final Future<void> Function()? onRemoveFriend;
  const _AthleteRow(
      {required this.entry, required this.isGlobal, this.onRemoveFriend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.surfaceContainerHigh,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 36,
            child: Text('#${entry.position}',
                style: AppTypography.labelMd.copyWith(
                  color: entry.isCurrentUser
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
          ),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.outlineVariant,
              ),
              color: AppColors.surfaceContainerHigh,
            ),
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(entry.avatarUrl!,
                        fit: BoxFit.cover))
                : const Icon(Icons.person,
                    color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName.toUpperCase(),
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: entry.isCurrentUser
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                if (entry.isCurrentUser)
                  Text(L.of(context).rank_voce,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                      )),
              ],
            ),
          ),
          // Points
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${entry.points} ${L.of(context).rank_pts}',
                style: AppTypography.labelSm.copyWith(
                  color: entry.isCurrentUser
                      ? AppColors.primary
                      : AppColors.onSurface,
                  fontSize: 11,
                )),
          ),
          // Remove friend button
          if (!isGlobal && !entry.isCurrentUser && onRemoveFriend != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    // context do próprio diálogo no pop — evita remover a
                    // página da navegação (tela preta) em vez do diálogo
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: AppColors.surfaceContainerLow,
                      title: Text(L.of(context).rank_removerAmigo),
                      content: Text(
                          L.of(context).rank_seraRemovido(entry.userName)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: Text(L.of(context).rank_cancelar),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: Text(L.of(context).rank_remover,
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) onRemoveFriend!();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_remove_outlined,
                      color: AppColors.error, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
