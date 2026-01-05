import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_client.dart';
import '../../../services/auth_controller.dart';
import 'widgets/authenticated_image.dart';

final clubAdminOverviewProvider =
    FutureProvider.autoDispose.family<ClubAdminOverview, String>((ref, slug) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/clubs/$slug/admin');
  final data = response.data ?? <String, dynamic>{};
  return ClubAdminOverview.fromJson(data);
});

Map<String, String> _buildImageHeaders(WidgetRef ref) {
  final token = ref.read(authControllerProvider).accessToken;
  if (token == null || token.isEmpty) {
    return const {};
  }
  return {'Authorization': 'Bearer $token'};
}

const double _clubAdminLogoDisplaySize = 160;
const LatLng _defaultClubLocation = LatLng(-36.5, -59.0);

class ClubAdminPage extends ConsumerStatefulWidget {
  const ClubAdminPage({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<ClubAdminPage> createState() => _ClubAdminPageState();
}

class _ClubAdminPageState extends ConsumerState<ClubAdminPage> {
  int? _leavingTournamentId;

  Future<void> _openJoinTournamentDialog(ClubAdminOverview overview) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClubJoinTournamentDialog(club: overview.club),
    );
    if (result == true) {
      ref.invalidate(clubAdminOverviewProvider(widget.slug));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club agregado al torneo correctamente.')),
      );
    }
  }

  Future<void> _openRosterEditor(
    ClubAdminOverview overview,
    ClubAdminTournament tournament,
    ClubAdminCategory category,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ClubRosterEditorDialog(
        club: overview.club,
        tournament: tournament,
        category: category,
      ),
    );
    if (result == true) {
      ref.invalidate(clubAdminOverviewProvider(widget.slug));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Habilitaciones actualizadas para ${category.categoryName}.',
          ),
        ),
      );
    }
  }

  Future<void> _openRosterViewer(
    ClubAdminOverview overview,
    ClubAdminTournament tournament,
    ClubAdminCategory category,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ClubRosterViewerDialog(
        club: overview.club,
        tournament: tournament,
        category: category,
      ),
    );
  }

  Future<void> _confirmLeaveTournament(
    ClubAdminOverview overview,
    ClubAdminTournament tournament,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar del torneo'),
        content: Text(
          '¿Estás seguro de eliminar al club del torneo ${tournament.name}? Esta acción quitará todas las categorías asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _leavingTournamentId = tournament.id;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.delete(
        '/clubs/${overview.club.id}/tournaments/${tournament.id}',
      );
      ref.invalidate(clubAdminOverviewProvider(widget.slug));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El club fue eliminado del torneo ${tournament.name}.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el club del torneo: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _leavingTournamentId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;
    final isAuthenticated = authState.isAuthenticated;
    final overviewAsync = ref.watch(clubAdminOverviewProvider(widget.slug));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: overviewAsync.maybeWhen(
        data: (overview) => isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _openJoinTournamentDialog(overview),
                icon: const Icon(Icons.add),
                label: const Text('Agregar a torneo'),
              )
            : null,
        orElse: () => null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: overviewAsync.when(
          data: (overview) {
            return _ClubAdminContent(
              overview: overview,
              isAdmin: isAdmin,
              isAuthenticated: isAuthenticated,
              leavingTournamentId: _leavingTournamentId,
              onEditCategory: (tournament, category) =>
                  _openRosterEditor(overview, tournament, category),
              onViewCategory: (tournament, category) =>
                  _openRosterViewer(overview, tournament, category),
              onRemoveTournament: (tournament) =>
                  _confirmLeaveTournament(overview, tournament),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ClubAdminErrorState(
            error: error,
            onRetry: () => ref.invalidate(clubAdminOverviewProvider(widget.slug)),
          ),
        ),
      ),
    );
  }
}

class _ClubAdminContent extends StatelessWidget {
  const _ClubAdminContent({
    required this.overview,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.leavingTournamentId,
    required this.onEditCategory,
    required this.onViewCategory,
    required this.onRemoveTournament,
  });

  final ClubAdminOverview overview;
  final bool isAdmin;
  final bool isAuthenticated;
  final int? leavingTournamentId;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onEditCategory;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onViewCategory;
  final void Function(ClubAdminTournament tournament) onRemoveTournament;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administración de club',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisá la información del club y gestioná las habilitaciones por categoría en cada torneo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _ClubSummaryCard(club: overview.club),
          const SizedBox(height: 24),
          if (overview.tournaments.isEmpty)
            _ClubAdminEmptyState(isAdmin: isAdmin)
          else
            _ClubTournamentsAccordion(
              tournaments: overview.tournaments,
              isAdmin: isAdmin,
              isAuthenticated: isAuthenticated,
              leavingTournamentId: leavingTournamentId,
              onEditCategory: onEditCategory,
              onViewCategory: onViewCategory,
              onRemoveTournament: onRemoveTournament,
            ),
        ],
      ),
    );
  }
}

class _ClubAdminErrorState extends StatelessWidget {
  const _ClubAdminErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'Ocurrió un error al cargar la información del club.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          )
        ],
      ),
    );
  }
}

class _ClubAdminEmptyState extends StatelessWidget {
  const _ClubAdminEmptyState({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final description = isAdmin
        ? 'Sumá al club a un torneo desde el botón flotante para comenzar a gestionar las habilitaciones.'
        : 'Aún no hay torneos asociados a este club.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_busy, size: 48),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin torneos asociados',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubSummaryCard extends StatelessWidget {
  const _ClubSummaryCard({required this.club});

  final ClubAdminSummary club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceVariant =
        theme.colorScheme.surfaceVariant.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.6);

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final mapPanel = _ClubLocationCard(club: club);
          final infoPanel = _ClubInformationPanel(club: club);

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoPanel,
                const SizedBox(height: 24),
                mapPanel,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: infoPanel),
              const SizedBox(width: 24),
              Flexible(
                fit: FlexFit.loose,
                child: LayoutBuilder(
                  builder: (context, mapConstraints) {
                    final availableWidth = mapConstraints.maxWidth;
                    final width = availableWidth.isFinite
                        ? math.min(availableWidth, 420.0)
                        : 420.0;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: width, child: mapPanel),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClubInformationPanel extends StatelessWidget {
  const _ClubInformationPanel({required this.club});

  final ClubAdminSummary club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = club.primaryColor;
    final secondary = club.secondaryColor;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Chip(
            shape: StadiumBorder(
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
            ),
            backgroundColor:
                club.active ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
            label: Text(
              club.active ? 'Activo' : 'Inactivo',
              style: theme.textTheme.labelLarge?.copyWith(
                color: club.active ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            avatar: Icon(
              club.active ? Icons.check_circle : Icons.pause_circle_filled,
              color: club.active ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ClubLogo(logoUrl: club.logoUrl, name: club.name),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    club.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded,
                              size: 18, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            club.slug != null
                                ? 'Slug: ${club.slug}'
                                : 'Sin identificador público',
                            style:
                                theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: theme.colorScheme.outline.withOpacity(0.1)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ColorBadge(
              color: primary,
              hex: club.primaryHex,
            ),
            _ColorBadge(
              color: secondary,
              hex: club.secondaryHex,
            ),
            if ((club.facebookUrl?.isNotEmpty ?? false) ||
                (club.instagramUrl?.isNotEmpty ?? false) ||
                club.mapsUrl != null)
              _ClubContactLinks(club: club),
          ],
        ),
      ],
    );
  }
}

class _ClubLocationCard extends StatelessWidget {
  const _ClubLocationCard({required this.club});

  final ClubAdminSummary club;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation = club.latitude != null && club.longitude != null;
    final center = hasLocation
        ? LatLng(club.latitude!, club.longitude!)
        : _defaultClubLocation;
    final zoom = hasLocation ? 13.0 : 6.3;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Ubicación',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (club.mapsUrl != null)
                TextButton.icon(
                  onPressed: () => _launchExternalUrl(context, club.mapsUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir en Maps'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                  interactionOptions: const InteractionOptions(enableMultiFingerGestureRace: true),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ligas_app',
                  ),
                  if (hasLocation)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(club.latitude!, club.longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (!hasLocation) ...[
            const SizedBox(height: 12),
            Text(
              'Este club aún no tiene ubicación asignada. Se muestra la provincia de Buenos Aires como referencia.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryIconBadge extends StatelessWidget {
  const _SummaryIconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: foreground, size: 24),
    );
  }
}

class _ClubLogo extends ConsumerWidget {
  const _ClubLogo({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _clubAdminLogoDisplaySize,
      height: _clubAdminLogoDisplaySize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: logoUrl != null && logoUrl!.isNotEmpty
            ? AuthenticatedImage(
                imageUrl: logoUrl!,
                fit: BoxFit.contain,
                headers: _buildImageHeaders(ref),
                placeholder: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                error: DecoratedBox(
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant),
                  child: _LogoFallback(name: name),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant),
                child: _LogoFallback(name: name),
              ),
      ),
    );
  }
}

Future<void> _launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace.')),
    );
    return;
  }
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace.')),
    );
  }
}

class _ClubContactLinks extends StatelessWidget {
  const _ClubContactLinks({required this.club});

  final ClubAdminSummary club;

  @override
  Widget build(BuildContext context) {
    final links = <Widget>[];
    if (club.facebookUrl?.isNotEmpty ?? false) {
      links.add(
        _IconLinkButton(
          icon: Icons.facebook,
          tooltip: 'Abrir Facebook',
          url: club.facebookUrl!,
        ),
      );
    }
    if (club.instagramUrl?.isNotEmpty ?? false) {
      links.add(
        _IconLinkButton(
          icon: Icons.photo_camera,
          tooltip: 'Abrir Instagram',
          url: club.instagramUrl!,
        ),
      );
    }
    if (club.mapsUrl != null) {
      links.add(
        _IconLinkButton(
          icon: Icons.location_on_outlined,
          tooltip: 'Ver ubicación en Google Maps',
          url: club.mapsUrl!,
        ),
      );
    }

    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      children: links,
    );
  }
}

class _IconLinkButton extends StatelessWidget {
  const _IconLinkButton({
    required this.icon,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final String tooltip;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () => _launchExternalUrl(context, url),
        icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        iconSize: 32,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minHeight: 52, minWidth: 52),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .where((segment) => segment.trim().isNotEmpty)
            .map((segment) => segment.trim().characters.first.toUpperCase())
            .take(2)
            .join()
        : '?';
    return Center(
      child: Text(
        initials,
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ColorBadge extends StatelessWidget {
  const _ColorBadge({required this.color, required this.hex});

  final Color? color;
  final String? hex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.surfaceVariant;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: displayColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          const SizedBox(width: 10),
          SelectableText(
            hex ?? '—',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ClubTournamentsAccordion extends StatefulWidget {
  const _ClubTournamentsAccordion({
    required this.tournaments,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.leavingTournamentId,
    required this.onEditCategory,
    required this.onViewCategory,
    required this.onRemoveTournament,
  });

  final List<ClubAdminTournament> tournaments;
  final bool isAdmin;
  final bool isAuthenticated;
  final int? leavingTournamentId;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onEditCategory;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onViewCategory;
  final void Function(ClubAdminTournament tournament) onRemoveTournament;

  @override
  State<_ClubTournamentsAccordion> createState() => _ClubTournamentsAccordionState();
}

class _ClubTournamentsAccordionState extends State<_ClubTournamentsAccordion> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionPanelList.radio(
        expandedHeaderPadding: EdgeInsets.zero,
        initialOpenPanelValue: _expandedIndex,
        children: [
          for (var i = 0; i < widget.tournaments.length; i++)
            ExpansionPanelRadio(
              value: i,
              headerBuilder: (context, isExpanded) {
                final tournament = widget.tournaments[i];
                final isGreen = tournament.isCompliant;
                final iconColor = isGreen ? Colors.green : Colors.red;
                final tooltipMessage = isGreen
                    ? 'Todas las categorías obligatorias cumplen con el mínimo de jugadores.'
                    : 'Hay categorías obligatorias con menos jugadores habilitados que el mínimo.';
                return ListTile(
                  leading: Tooltip(
                    message: tooltipMessage,
                    child: Icon(Icons.circle, color: iconColor, size: 16),
                  ),
                  title: Text(
                    '${tournament.leagueName} - ${tournament.name}',
                  ),
                  subtitle: Text(
                    tournament.categories.isEmpty
                        ? 'Sin categorías asignadas'
                        : '${tournament.mandatoryReadyCount}/${tournament.mandatoryCount} categorías obligatorias en verde',
                  ),
                );
              },
              body: _TournamentCategoriesList(
                tournament: widget.tournaments[i],
                isAdmin: widget.isAdmin,
                isAuthenticated: widget.isAuthenticated,
                isRemoving: widget.leavingTournamentId == widget.tournaments[i].id,
                onEditCategory: widget.onEditCategory,
                onViewCategory: widget.onViewCategory,
                onRemoveTournament: widget.onRemoveTournament,
              ),
            ),
        ],
      ),
    );
  }
}

class _TournamentCategoriesList extends StatelessWidget {
  const _TournamentCategoriesList({
    required this.tournament,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.isRemoving,
    required this.onEditCategory,
    required this.onViewCategory,
    required this.onRemoveTournament,
  });

  final ClubAdminTournament tournament;
  final bool isAdmin;
  final bool isAuthenticated;
  final bool isRemoving;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onEditCategory;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onViewCategory;
  final void Function(ClubAdminTournament tournament) onRemoveTournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zone = tournament.zone;
    final showHeader = zone != null || isAdmin;
    final hasCategories = tournament.categories.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone != null ? 'Zona asignada' : 'Sin zona asignada',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone != null
                              ? '${zone.name} · ${zone.statusLabel}'
                              : 'El club no está asignado a ninguna zona en este torneo.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin && tournament.canLeave)
                    FilledButton.tonalIcon(
                      onPressed:
                          isRemoving ? null : () => onRemoveTournament(tournament),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      icon: isRemoving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(isRemoving ? 'Eliminando…' : 'Eliminar del torneo'),
                    ),
                ],
              ),
            ),
          if (!showHeader) const SizedBox(height: 16),
          if (!hasCategories)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Este club aún no tiene categorías asignadas en este torneo.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (final category in tournament.categories)
              _CategoryRow(
                tournament: tournament,
                category: category,
                isAdmin: isAdmin,
                isAuthenticated: isAuthenticated,
                onEditCategory: onEditCategory,
                onViewCategory: onViewCategory,
              ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.tournament,
    required this.category,
    required this.isAdmin,
    required this.isAuthenticated,
    required this.onEditCategory,
    required this.onViewCategory,
  });

  final ClubAdminTournament tournament;
  final ClubAdminCategory category;
  final bool isAdmin;
  final bool isAuthenticated;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onEditCategory;
  final void Function(ClubAdminTournament tournament, ClubAdminCategory category)
      onViewCategory;

  @override
  Widget build(BuildContext context) {
    final iconColor = category.isCompliant ? Colors.green : Colors.red;
    final tooltip = category.isCompliant
        ? 'Habilitados suficientes para cumplir el mínimo.'
        : category.mandatory
            ? 'Faltan jugadores habilitados para alcanzar el mínimo requerido.'
            : 'Categoría opcional con menos del mínimo configurado.';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Tooltip(
              message: tooltip,
              child: Icon(Icons.circle, color: iconColor, size: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.birthYearRangeLabel} · ${category.genderLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Habilitados: ${category.enabledCount} · Mínimo requerido: ${category.minPlayers}' +
                        (category.mandatory ? ' · Obligatoria' : ' · Opcional'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              children: [
                if (isAuthenticated)
                  OutlinedButton(
                    onPressed: () => onViewCategory(tournament, category),
                    child: const Text('Ver'),
                  ),
                if (isAdmin)
                  FilledButton(
                    onPressed: () => onEditCategory(tournament, category),
                    child: const Text('Editar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClubAdminOverview {
  ClubAdminOverview({required this.club, required this.tournaments});

  factory ClubAdminOverview.fromJson(Map<String, dynamic> json) {
    final tournaments = (json['tournaments'] as List<dynamic>? ?? [])
        .map((item) => ClubAdminTournament.fromJson(item as Map<String, dynamic>))
        .toList();
    return ClubAdminOverview(
      club: ClubAdminSummary.fromJson(json['club'] as Map<String, dynamic>),
      tournaments: tournaments,
    );
  }

  final ClubAdminSummary club;
  final List<ClubAdminTournament> tournaments;
}

class ClubAdminSummary {
  ClubAdminSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
    required this.primaryHex,
    required this.secondaryHex,
    this.logoUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.latitude,
    this.longitude,
  });

  factory ClubAdminSummary.fromJson(Map<String, dynamic> json) {
    return ClubAdminSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      active: json['active'] as bool? ?? true,
      primaryHex: json['primaryColor'] as String?,
      secondaryHex: json['secondaryColor'] as String?,
      logoUrl: json['logoUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
    );
  }

  final int id;
  final String name;
  final String? slug;
  final bool active;
  final String? primaryHex;
  final String? secondaryHex;
  final String? logoUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final double? latitude;
  final double? longitude;

  Color? get primaryColor => _parseHexColor(primaryHex);
  Color? get secondaryColor => _parseHexColor(secondaryHex);
  String? get mapsUrl {
    if (latitude == null || longitude == null) {
      return null;
    }
    final lat = latitude!.toStringAsFixed(6);
    final lng = longitude!.toStringAsFixed(6);
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
}

class ClubAdminTournament {
  ClubAdminTournament({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueId,
    required this.leagueName,
    required this.categories,
    this.zone,
    required this.canLeave,
  });

  factory ClubAdminTournament.fromJson(Map<String, dynamic> json) {
    return ClubAdminTournament(
      id: json['id'] as int,
      name: json['name'] as String,
      year: json['year'] as int,
      leagueId: json['leagueId'] as int,
      leagueName: json['leagueName'] as String? ?? '—',
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((item) => ClubAdminCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
      zone: json['zone'] is Map<String, dynamic>
          ? ClubAdminZone.fromJson(json['zone'] as Map<String, dynamic>)
          : null,
      canLeave: json['canLeave'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final int year;
  final int leagueId;
  final String leagueName;
  final List<ClubAdminCategory> categories;
  final ClubAdminZone? zone;
  final bool canLeave;

  bool get isCompliant => categories.every((category) => category.isCompliant);

  int get mandatoryCount => categories.where((category) => category.mandatory).length;
  int get mandatoryReadyCount =>
      categories.where((category) => category.mandatory && category.isCompliant).length;
}

class ClubAdminZone {
  ClubAdminZone({
    required this.id,
    required this.name,
    required this.status,
  });

  factory ClubAdminZone.fromJson(Map<String, dynamic> json) {
    return ClubAdminZone(
      id: json['id'] as int,
      name: json['name'] as String? ?? '—',
      status: json['status'] as String? ?? 'OPEN',
    );
  }

  final int id;
  final String name;
  final String status;

  bool get isOpen => status == 'OPEN';

  String get statusLabel {
    switch (status) {
      case 'IN_PROGRESS':
        return 'En progreso';
      case 'PLAYING':
        return 'En juego';
      case 'FINISHED':
        return 'Finalizada';
      case 'OPEN':
      default:
        return 'Abierta';
    }
  }
}

class ClubAdminCategory {
  ClubAdminCategory({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.birthYearMin,
    required this.birthYearMax,
    required this.gender,
    required this.minPlayers,
    required this.mandatory,
    required this.enabledCount,
  });

  factory ClubAdminCategory.fromJson(Map<String, dynamic> json) {
    return ClubAdminCategory(
      tournamentCategoryId: json['tournamentCategoryId'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      birthYearMin: json['birthYearMin'] as int,
      birthYearMax: json['birthYearMax'] as int,
      gender: json['gender'] as String? ?? 'MIXTO',
      minPlayers: json['minPlayers'] as int? ?? 7,
      mandatory: json['mandatory'] as bool? ?? true,
      enabledCount: json['enabledCount'] as int? ?? 0,
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;
  final int minPlayers;
  final bool mandatory;
  final int enabledCount;

  bool get isCompliant => !mandatory || enabledCount >= minPlayers;

  String get birthYearRangeLabel {
    if (birthYearMin == birthYearMax) {
      return '$birthYearMin';
    }
    return '$birthYearMin - $birthYearMax';
  }

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }
}

Color? _parseHexColor(String? value) {
  if (value == null) {
    return null;
  }
  final cleaned = value.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  final hex = cleaned.startsWith('#') ? cleaned.substring(1) : cleaned;
  if (hex.length != 6 && hex.length != 8) {
    return null;
  }
  return Color(int.parse('0xff$hex'));
}

double? _parseCoordinate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

class ClubRosterEditorDialog extends ConsumerStatefulWidget {
  const ClubRosterEditorDialog({
    required this.club,
    required this.tournament,
    required this.category,
  });

  final ClubAdminSummary club;
  final ClubAdminTournament tournament;
  final ClubAdminCategory category;

  @override
  ConsumerState<ClubRosterEditorDialog> createState() => _ClubRosterEditorDialogState();
}

class _ClubRosterEditorDialogState extends ConsumerState<ClubRosterEditorDialog> {
  final Set<int> _selectedPlayers = <int>{};
  List<EligiblePlayer> _players = const [];
  int _page = 1;
  int _pageSize = 20;
  int _total = 0;
  bool _isSaving = false;
  bool _isLoading = true;
  Object? _error;
  bool _initialSelectionLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlayers());
  }

  Future<void> _loadPlayers({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final clubId = widget.club.id;
      final categoryId = widget.category.tournamentCategoryId;

      final response = await api.get<Map<String, dynamic>>(
        '/clubs/$clubId/tournament-categories/$categoryId/eligible-players',
        queryParameters: {
          'page': page,
          'pageSize': _pageSize,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final result = EligiblePlayersPage.fromJson(data);

      final enabledResponse = await api.get<Map<String, dynamic>>(
        '/clubs/$clubId/tournament-categories/$categoryId/eligible-players',
        queryParameters: {
          'page': 1,
          'pageSize': 500,
          'onlyEnabled': true,
        },
      );
      final enabledData = enabledResponse.data ?? <String, dynamic>{};
      final enabledPage = EligiblePlayersPage.fromJson(enabledData);

      if (!_initialSelectionLoaded) {
        _selectedPlayers
          ..clear()
          ..addAll(enabledPage.players.map((player) => player.id));
        _initialSelectionLoaded = true;
      }

      setState(() {
        _players = result.players;
        _page = result.page;
        _pageSize = result.pageSize;
        _total = result.total;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSelection(bool? selected, int playerId) async {
    setState(() {
      if (selected == true) {
        _selectedPlayers.add(playerId);
      } else {
        _selectedPlayers.remove(playerId);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final clubId = widget.club.id;
      final categoryId = widget.category.tournamentCategoryId;
      await api.put(
        '/clubs/$clubId/tournament-categories/$categoryId/eligible-players',
        data: {
          'playerIds': _selectedPlayers.toList(),
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar habilitados · ${widget.category.categoryName}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Seleccioná los jugadores elegibles del club para habilitarlos en esta categoría.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(context),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Seleccionados: ${_selectedPlayers.length} · Mínimo requerido: ${widget.category.minPlayers}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar los jugadores elegibles.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('$_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _loadPlayers(page: _page),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: _EligiblePlayersTable(
            players: _players,
            selectedPlayers: _selectedPlayers,
            onSelectionChanged: _toggleSelection,
          ),
        ),
        const SizedBox(height: 12),
        _PaginationControls(
          page: _page,
          pageSize: _pageSize,
          total: _total,
          onChanged: (page) => _loadPlayers(page: page),
        ),
      ],
    );
  }
}

class ClubRosterViewerDialog extends ConsumerStatefulWidget {
  const ClubRosterViewerDialog({
    required this.club,
    required this.tournament,
    required this.category,
  });

  final ClubAdminSummary club;
  final ClubAdminTournament tournament;
  final ClubAdminCategory category;

  @override
  ConsumerState<ClubRosterViewerDialog> createState() => _ClubRosterViewerDialogState();
}

class _ClubRosterViewerDialogState extends ConsumerState<ClubRosterViewerDialog> {
  bool _isLoading = true;
  Object? _error;
  List<EligiblePlayer> _players = const [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final clubId = widget.club.id;
      final categoryId = widget.category.tournamentCategoryId;
      final response = await api.get<Map<String, dynamic>>(
        '/clubs/$clubId/tournament-categories/$categoryId/eligible-players',
        queryParameters: {
          'page': 1,
          'pageSize': 200,
          'onlyEnabled': true,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final result = EligiblePlayersPage.fromJson(data);
      setState(() {
        _players = result.players;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habilitados · ${widget.category.categoryName}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Listado de jugadores habilitados para la categoría.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar los jugadores habilitados.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text('$_error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadPlayers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (_players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No hay jugadores habilitados en esta categoría.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SizedBox(
                height: 320,
                child: _EligiblePlayersTable(
                  players: _players,
                  selectedPlayers: _players.map((player) => player.id).toSet(),
                  readOnly: true,
                  onSelectionChanged: (selected, id) {},
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EligiblePlayersPage {
  EligiblePlayersPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.players,
  });

  factory EligiblePlayersPage.fromJson(Map<String, dynamic> json) {
    return EligiblePlayersPage(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((item) => EligiblePlayer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int page;
  final int pageSize;
  final int total;
  final List<EligiblePlayer> players;
}

class EligiblePlayer {
  EligiblePlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.enabled,
  });

  factory EligiblePlayer.fromJson(Map<String, dynamic> json) {
    return EligiblePlayer(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthDate: DateTime.tryParse(json['birthDate'] as String? ?? '') ?? DateTime(1970, 1, 1),
      gender: json['gender'] as String? ?? 'MIXTO',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String gender;
  final bool enabled;

  String get fullName => '${lastName.toUpperCase()}, $firstName';

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }
}

class _EligiblePlayersTable extends StatelessWidget {
  const _EligiblePlayersTable({
    required this.players,
    required this.selectedPlayers,
    required this.onSelectionChanged,
    this.readOnly = false,
  });

  final List<EligiblePlayer> players;
  final Set<int> selectedPlayers;
  final void Function(bool? value, int id) onSelectionChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          'No hay jugadores para mostrar.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final checked = selectedPlayers.contains(player.id);
        return CheckboxListTile(
          value: checked,
          onChanged: readOnly ? null : (value) => onSelectionChanged(value, player.id),
          title: Text(player.fullName),
          subtitle: Text(
            '${player.birthDate.year} · ${player.genderLabel}',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil();
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Página $page de $totalPages'),
        IconButton(
          onPressed: page < totalPages ? () => onChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class ClubJoinTournamentDialog extends ConsumerStatefulWidget {
  const ClubJoinTournamentDialog({required this.club});

  final ClubAdminSummary club;

  @override
  ConsumerState<ClubJoinTournamentDialog> createState() => _ClubJoinTournamentDialogState();
}

class _ClubJoinTournamentDialogState extends ConsumerState<ClubJoinTournamentDialog> {
  bool _isLoading = true;
  Object? _error;
  List<AvailableTournament> _tournaments = const [];
  AvailableTournament? _selectedTournament;
  final Set<int> _selectedCategories = <int>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get<List<dynamic>>(
        '/clubs/${widget.club.id}/available-tournaments',
      );
      final data = response.data ?? <dynamic>[];
      final tournaments = data
          .map((item) => AvailableTournament.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _tournaments = tournaments;
        _selectedTournament = tournaments.isNotEmpty ? tournaments.first : null;
        _selectedCategories
          ..clear()
          ..addAll(tournaments.isNotEmpty
              ? tournaments.first.categories.map((category) => category.tournamentCategoryId)
              : const Iterable<int>.empty());
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSaving || _selectedTournament == null || _selectedCategories.isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/clubs/${widget.club.id}/available-tournaments',
        data: {
          'tournamentId': _selectedTournament!.id,
          'tournamentCategoryIds': _selectedCategories.toList(),
        },
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la operación: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _onTournamentChanged(AvailableTournament? tournament) {
    setState(() {
      _selectedTournament = tournament;
      _selectedCategories
        ..clear()
        ..addAll(tournament?.categories.map((category) => category.tournamentCategoryId) ??
            const Iterable<int>.empty());
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'No se pudieron cargar los torneos disponibles.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('$_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadTournaments,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    } else if (_tournaments.isEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            'No hay torneos disponibles para sumar al club.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(false),
            child: const Text('Cerrar'),
          ),
        ],
      );
    } else {
      final tournament = _selectedTournament;
      content = SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sumar a torneo',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Seleccioná un torneo y las categorías en las que participará el club.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AvailableTournament>(
              value: _selectedTournament,
              items: _tournaments
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        '${item.leagueName} - ${item.name}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onTournamentChanged,
              decoration: const InputDecoration(labelText: 'Torneo'),
            ),
            const SizedBox(height: 16),
            if (tournament != null)
              Expanded(
                child: ListView(
                  children: tournament.categories.map((category) {
                    return ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(category.categoryName),
                      subtitle: Text(
                        '${category.birthYearRangeLabel} · ${category.genderLabel}',
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving || _selectedCategories.isEmpty ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(width: 600, child: content),
    );
  }
}

class AvailableTournament {
  AvailableTournament({
    required this.id,
    required this.name,
    required this.year,
    required this.leagueId,
    required this.leagueName,
    required this.categories,
  });

  factory AvailableTournament.fromJson(Map<String, dynamic> json) {
    return AvailableTournament(
      id: json['id'] as int,
      name: json['name'] as String,
      year: json['year'] as int,
      leagueId: json['leagueId'] as int,
      leagueName: json['leagueName'] as String? ?? '—',
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((item) => AvailableTournamentCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String name;
  final int year;
  final int leagueId;
  final String leagueName;
  final List<AvailableTournamentCategory> categories;
}

class AvailableTournamentCategory {
  AvailableTournamentCategory({
    required this.tournamentCategoryId,
    required this.categoryId,
    required this.categoryName,
    required this.birthYearMin,
    required this.birthYearMax,
    required this.gender,
    required this.minPlayers,
    required this.mandatory,
  });

  factory AvailableTournamentCategory.fromJson(Map<String, dynamic> json) {
    return AvailableTournamentCategory(
      tournamentCategoryId: json['tournamentCategoryId'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      birthYearMin: json['birthYearMin'] as int,
      birthYearMax: json['birthYearMax'] as int,
      gender: json['gender'] as String? ?? 'MIXTO',
      minPlayers: json['minPlayers'] as int? ?? 7,
      mandatory: json['mandatory'] as bool? ?? true,
    );
  }

  final int tournamentCategoryId;
  final int categoryId;
  final String categoryName;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;
  final int minPlayers;
  final bool mandatory;

  String get birthYearRangeLabel {
    if (birthYearMin == birthYearMax) {
      return '$birthYearMin';
    }
    return '$birthYearMin - $birthYearMax';
  }

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }
}
