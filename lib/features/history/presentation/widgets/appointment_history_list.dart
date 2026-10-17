import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/history_failure.dart';
import '../controllers/history_controller.dart';
import 'appointment_history_tile.dart';

/// Corpo do histórico com carregamento, vazio, erro e paginação incremental.
/// Compartilhado pelas visões do paciente e do profissional.
class AppointmentHistoryList extends StatefulWidget {
  const AppointmentHistoryList({
    required this.controller,
    required this.emptyTitle,
    required this.emptyMessage,
    super.key,
  });

  final HistoryController controller;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<AppointmentHistoryList> createState() => _AppointmentHistoryListState();
}

class _AppointmentHistoryListState extends State<AppointmentHistoryList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      widget.controller.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.isLoadingFirstPage) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, _) => const AppLoadingSkeleton(),
          );
        }

        final failure = controller.failure;
        if (failure != null) {
          return _FailureView(
            failure: failure,
            onRetry: controller.loadFirstPage,
          );
        }

        if (controller.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadFirstPage,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: EmptyState(
                    icon: Icons.history,
                    title: widget.emptyTitle,
                    message: widget.emptyMessage,
                  ),
                ),
              ),
            ),
          );
        }

        final items = controller.items;
        return RefreshIndicator(
          onRefresh: controller.loadFirstPage,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index < items.length) {
                return AppointmentHistoryTile(entry: items[index]);
              }
              return _ListFooter(controller: controller);
            },
          ),
        );
      },
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.controller});

  final HistoryController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.canLoadMore) {
      // A lista não rolou o suficiente para disparar a próxima página.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.loadNextPage(),
      );
    }

    final Widget child;
    if (controller.loadMoreFailure != null) {
      child = Column(
        children: [
          Text(
            historyFailureMessage(controller.loadMoreFailure!),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Tentar novamente',
            icon: Icons.refresh,
            onPressed: controller.retryLoadMore,
            expand: false,
          ),
        ],
      );
    } else if (controller.hasReachedEnd) {
      child = Text(
        'Você chegou ao fim do histórico.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
      );
    } else {
      child = const Center(
        child: SizedBox.square(
          dimension: 32,
          child: CircularProgressIndicator(semanticsLabel: 'Carregando mais'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: child,
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.failure, required this.onRetry});

  final HistoryFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ErrorState(
          title: failure == HistoryFailure.accessDenied
              ? 'Histórico indisponível'
              : 'Não foi possível carregar',
          message: historyFailureMessage(failure),
          onRetry: failure == HistoryFailure.accessDenied ? null : onRetry,
        ),
      ),
    );
  }
}

String historyFailureMessage(HistoryFailure failure) {
  return switch (failure) {
    HistoryFailure.accessDenied =>
      'Você não tem acesso a este histórico ou ele não está disponível.',
    HistoryFailure.sessionExpired =>
      'Sua sessão expirou. Entre novamente para continuar.',
    HistoryFailure.network =>
      'Verifique sua conexão com a internet e tente novamente.',
    HistoryFailure.unexpected =>
      'Ocorreu um erro inesperado. Tente novamente em instantes.',
  };
}
