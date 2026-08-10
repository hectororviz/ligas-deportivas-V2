<script lang="ts">
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { generateFixture, getProfile, getZones, type AuthUser, type Zone } from '$lib/api';

  let user: AuthUser | null = null;
  let zones: Zone[] = [];
  let loading = true;
  let error = '';
  let notice = '';
  let generatingZoneId: number | null = null;
  let generating = false;

  onMount(async () => {
    try {
      [user, zones] = await Promise.all([getProfile(), getZones(true)]);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar las zonas.';
    } finally {
      loading = false;
    }
  });

  $: canManage = user?.roles.includes('ADMIN') ?? false;

  function statusLabel(status: string) {
    const map: Record<string, string> = {
      ACTIVE: 'Activa',
      INACTIVE: 'Inactiva',
      DRAFT: 'Borrador',
      CLOSED: 'Cerrada'
    };
    return map[status] ?? status;
  }

  function statusClass(status: string) {
    const map: Record<string, string> = {
      ACTIVE: 'badge-active',
      INACTIVE: 'badge-inactive',
      DRAFT: 'badge-draft',
      CLOSED: 'badge-closed'
    };
    return map[status] ?? 'badge-default';
  }

  async function handleGenerate(zone: Zone) {
    error = '';
    notice = '';
    generatingZoneId = zone.id;
    generating = true;
    try {
      await generateFixture(zone.id, true);
      notice = `Fixture generado para Zona ${zone.name}.`;
      zones = await getZones(true);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo generar el fixture.';
    } finally {
      generatingZoneId = null;
      generating = false;
    }
  }
</script>

<svelte:head><title>Zonas | Ligas Deportivas</title></svelte:head>

<main class="page-shell">
  <header class="page-header">
    <div><p class="eyebrow">Competencia</p><h1>Zonas</h1><p class="muted">Administra las zonas de cada torneo, sus posiciones y la generación de partidos.</p></div>
    <div class="header-actions">
      <a class="button secondary" href="/">Volver al panel</a>
      <a class="button secondary" href="/fixtures">Ver partidos</a>
    </div>
  </header>

  {#if loading}
    <section class="loading-card">Cargando zonas...</section>
  {:else}
    {#if error}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}
    <section class="zone-list card-surface">
      <div class="list-header">
        <div><p class="eyebrow">Catálogo</p><h2>Zonas registradas</h2></div>
        <span class="count-pill">{zones.length}</span>
      </div>
      {#if zones.length === 0}
        <div class="empty-state compact-empty"><h2>Sin zonas todavía</h2><p>Crea torneos y zonas para comenzar.</p></div>
      {:else}
        <div class="zone-table">
          {#each zones as zone}
            <article class="zone-row">
              <span class="zone-icon">Z{zone.name.slice(0, 1)}</span>
              <div class="zone-info">
                <div class="zone-name-row">
                  <strong>Zona {zone.name}</strong>
                  <span class="status-badge {statusClass(zone.status)}">{statusLabel(zone.status)}</span>
                </div>
                <span>{zone.tournament.name} {zone.tournament.year} · {zone.tournament.league.name}{#if zone.clubZones?.length} · {zone.clubZones.length} clubes{/if}</span>
              </div>
              <div class="zone-actions">
                <a class="button secondary" href={`/zones/${zone.id}/standings`}>Posiciones</a>
                {#if canManage}
                  <button class="button primary" disabled={generating && generatingZoneId === zone.id} onclick={() => handleGenerate(zone)}>
                    {generating && generatingZoneId === zone.id ? 'Generando...' : 'Generar fixture'}
                  </button>
                {/if}
              </div>
            </article>
          {/each}
        </div>
      {/if}
    </section>
  {/if}
</main>
