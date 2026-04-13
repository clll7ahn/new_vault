import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 미읽음 알림 수
// ──────────────────────────────────────────────────────────────────────────────

final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});

// ──────────────────────────────────────────────────────────────────────────────
// 알림 목록 (페이지네이션 Notifier)
// ──────────────────────────────────────────────────────────────────────────────

class NotificationsState {
  const NotificationsState({
    required this.items,
    required this.total,
    required this.page,
    required this.isLoading,
    this.error,
  });

  final List<NotificationModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final String? error;

  bool get hasMore => items.length < total;
  bool get isEmpty => items.isEmpty && !isLoading;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  static const _limit = 20;

  NotificationRepository get _repo =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationsState> build() async {
    return _fetchPage(1, replace: true);
  }

  // 첫 페이지 (새로고침)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchPage(1, replace: true),
    );
  }

  // 다음 페이지 로드
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoading || !current.hasMore) return;

    final nextPage = current.page + 1;
    state = AsyncData(current.copyWith(isLoading: true, clearError: true));

    try {
      final next = await _fetchPage(nextPage, replace: false);
      state = AsyncData(next);
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          error: '추가 알림을 불러오지 못했습니다.',
        ),
      );
    }
  }

  // 특정 알림 읽음 처리
  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // 낙관적 업데이트
    final updated = current.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = AsyncData(current.copyWith(items: updated));

    try {
      await _repo.markAsRead(id);
      ref.invalidate(unreadCountProvider);
    } catch (_) {
      // 롤백
      state = AsyncData(current);
    }
  }

  // 전체 읽음 처리
  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated =
        current.items.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncData(current.copyWith(items: updated));

    try {
      await _repo.markAllAsRead();
      ref.invalidate(unreadCountProvider);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<NotificationsState> _fetchPage(
    int page, {
    required bool replace,
  }) async {
    final result = await _repo.getNotifications(page: page, limit: _limit);
    final prev =
        replace ? <NotificationModel>[] : (state.valueOrNull?.items ?? []);

    return NotificationsState(
      items: [...prev, ...result.items],
      total: result.total,
      page: page,
      isLoading: false,
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
