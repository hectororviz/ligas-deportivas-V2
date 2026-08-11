<script lang="ts">
  import { getPlayers, getProfile, createPlayer, updatePlayer, scanDni, type AuthUser, type Player, type PaginatedPlayers, type ScanDniResult } from '$lib/api';
  import Modal from '$lib/Modal.svelte';

  let user: AuthUser | null = $state(null);
  let paginated: PaginatedPlayers | null = $state(null);
  let loading = $state(true);
  let saving = $state(false);
  let error = $state('');
  let notice = $state('');
  let search = $state('');
  let debounce: ReturnType<typeof setTimeout> | null = null;
  let page = $state(1);
  let editing: Player | null = $state(null);
  let showForm = $state(false);
  let showFilters = $state(false);
  let showMenu = $state(false);
  let form = $state({
    firstName: '', lastName: '', dni: '', birthDate: '', gender: 'MASCULINO', active: true,
    addressStreet: '', addressNumber: '', addressCity: '',
    emergencyName: '', emergencyRelationship: '', emergencyPhone: ''
  });

  let canManage = $derived(((user as AuthUser | null)?.roles ?? []).includes('ADMIN'));

  $effect(() => { fetchPlayers(); });

  function menuClose(e: MouseEvent) { if (!(e.target as HTMLElement).closest('.add-menu')) showMenu = false; }

  async function fetchPlayers() {
    loading = true; error = '';
    try {
      if (!user) user = await getProfile();
      paginated = await getPlayers(search, page);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudieron cargar los jugadores.';
    } finally { loading = false; }
  }

  function onSearch() {
    if (debounce) clearTimeout(debounce);
    debounce = setTimeout(() => { page = 1; fetchPlayers(); }, 300);
  }

  function freshRow() {
    return {
      firstName: '', lastName: '', dni: '', birthDate: '', gender: 'MASCULINO', active: true,
      addressStreet: '', addressNumber: '', addressCity: '',
      emergencyName: '', emergencyRelationship: '', emergencyPhone: ''
    };
  }

  function openCreate() { editing = null; showForm = true; error = ''; form = freshRow(); showMenu = false; }
  function openBulk() { showMenu = false; bulkRows = Array.from({ length: 10 }, () => freshRow()); showBulk = true; }
  function openScan() { showMenu = false; scanFile = null; scanImgPreview = ''; scanResult = null; scanError = ''; scanNotice = ''; showScan = true; }

  function openEdit(player: Player) {
    editing = player; showForm = true; error = '';
    form = {
      firstName: player.firstName, lastName: player.lastName, dni: player.dni,
      birthDate: player.birthDate ? player.birthDate.split('T')[0] : '', gender: player.gender, active: player.active,
      addressStreet: player.addressStreet ?? '', addressNumber: player.addressNumber ?? '', addressCity: player.addressCity ?? '',
      emergencyName: player.emergencyName ?? '', emergencyRelationship: player.emergencyRelationship ?? '', emergencyPhone: player.emergencyPhone ?? ''
    };
  }

  function closeModal() { showForm = false; editing = null; error = ''; }

  async function save() {
    error = '';
    if (!form.firstName.trim()) { error = 'Ingresa el nombre del jugador.'; return; }
    if (!form.lastName.trim()) { error = 'Ingresa el apellido del jugador.'; return; }
    if (!form.dni.trim()) { error = 'Ingresa el DNI del jugador.'; return; }
    saving = true;
    const payload: Record<string, unknown> = {
      firstName: form.firstName.trim(), lastName: form.lastName.trim(), dni: form.dni.trim(),
      birthDate: form.birthDate || undefined, gender: form.gender, active: form.active,
      addressStreet: form.addressStreet.trim() || undefined, addressNumber: form.addressNumber.trim() || undefined, addressCity: form.addressCity.trim() || undefined,
      emergencyName: form.emergencyName.trim() || undefined, emergencyRelationship: form.emergencyRelationship.trim() || undefined, emergencyPhone: form.emergencyPhone.trim() || undefined
    };
    try {
      if (editing) await updatePlayer(editing.id, payload);
      else await createPlayer(payload);
      notice = editing ? 'Jugador actualizado correctamente.' : 'Jugador creado correctamente.';
      showForm = false; editing = null;
      await fetchPlayers();
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar el jugador.';
    } finally { saving = false; }
  }

  function birthYear(dateStr: string): string { if (!dateStr) return '—'; return dateStr.split('-')[0] ?? '—'; }
  function initials(player: Player): string { return `${player.firstName[0] ?? ''}${player.lastName[0] ?? ''}`.toUpperCase(); }
  function genderLabel(g: string): string { return g === 'MASCULINO' ? 'Masculino' : g === 'FEMENINO' ? 'Femenino' : g; }

  let showBulk = $state(false);
  let bulkRows = $state(Array.from({ length: 10 }, () => freshRow()));
  let bulkSaving = $state(false);
  let bulkError = $state('');
  let bulkNotice = $state('');
  let bulkResults = $state<{ created: number; skipped: number; errors: string[] } | null>(null);

  function addBulkRow() { bulkRows.push(freshRow()); }
  function removeBulkRow(idx: number) { if (bulkRows.length > 1) bulkRows.splice(idx, 1); }

  async function saveBulk() {
    bulkError = ''; bulkNotice = ''; bulkResults = null;
    const toSave = bulkRows.filter((r) => r.firstName.trim() || r.lastName.trim() || r.dni.trim());
    if (toSave.length === 0) { bulkError = 'Completá al menos un jugador.'; return; }

    for (let i = 0; i < toSave.length; i++) {
      const r = toSave[i];
      if (!r.firstName.trim() || !r.lastName.trim() || !r.dni.trim()) {
        bulkError = `Fila ${i + 1}: nombre, apellido y DNI son obligatorios.`;
        return;
      }
    }

    const dniSet = new Set<string>();
    for (let i = 0; i < toSave.length; i++) {
      const dni = toSave[i].dni.trim();
      if (dniSet.has(dni)) { bulkError = `DNI duplicado en la tabla: ${dni}.`; return; }
      dniSet.add(dni);
    }

    bulkSaving = true;
    let created = 0;
    let skipped = 0;
    const errors: string[] = [];

    for (let i = 0; i < toSave.length; i++) {
      const r = toSave[i];
      const payload: Record<string, unknown> = {
        firstName: r.firstName.trim(), lastName: r.lastName.trim(), dni: r.dni.trim(),
        birthDate: r.birthDate || undefined, gender: r.gender, active: r.active,
        addressStreet: r.addressStreet.trim() || undefined, addressNumber: r.addressNumber.trim() || undefined, addressCity: r.addressCity.trim() || undefined,
        emergencyName: r.emergencyName.trim() || undefined, emergencyRelationship: r.emergencyRelationship.trim() || undefined, emergencyPhone: r.emergencyPhone.trim() || undefined
      };
      try {
        await createPlayer(payload);
        created++;
      } catch (cause) {
        const msg = cause instanceof Error ? cause.message : 'Error';
        if (msg.toLowerCase().includes('dni') && (msg.toLowerCase().includes('unique') || msg.toLowerCase().includes('existe') || msg.toLowerCase().includes('duplic'))) {
          skipped++;
        } else {
          errors.push(`Fila ${i + 1} (${r.lastName}, ${r.firstName}): ${msg}`);
        }
      }
    }

    bulkSaving = false;
    bulkResults = { created, skipped, errors };
    if (created > 0) {
      showBulk = false;
      bulkRows = Array.from({ length: 10 }, () => freshRow());
      await fetchPlayers();
    }
  }

  function closeBulk() { showBulk = false; bulkResults = null; }

  let showScan = $state(false);
  let scanFile = $state<File | null>(null);
  let scanImgPreview = $state('');
  let scanResult = $state<ScanDniResult | null>(null);
  let scanError = $state('');
  let scanNotice = $state('');
  let scanLoading = $state(false);
  let scanSaving = $state(false);

  function handleScanFileChange(e: Event) {
    const input = e.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    scanFile = file;
    scanResult = null;
    scanError = '';
    scanNotice = '';
    if (file) {
      const reader = new FileReader();
      reader.onload = () => scanImgPreview = reader.result as string;
      reader.readAsDataURL(file);
    } else {
      scanImgPreview = '';
    }
  }

  async function doScan() {
    if (!scanFile) { scanError = 'Seleccioná una imagen del DNI.'; return; }
    scanLoading = true; scanError = ''; scanNotice = ''; scanResult = null;
    try {
      scanResult = await scanDni(scanFile);
    } catch (cause) {
      scanError = cause instanceof Error ? cause.message : 'No se pudo escanear el DNI.';
    } finally { scanLoading = false; }
  }

  async function createFromScan() {
    if (!scanResult) return;
    scanSaving = true; scanError = '';
    try {
      await createPlayer({
        firstName: scanResult.firstName.trim(), lastName: scanResult.lastName.trim(), dni: scanResult.dni.trim(),
        birthDate: scanResult.birthDate, gender: scanResult.sex === 'M' ? 'MASCULINO' : scanResult.sex === 'F' ? 'FEMENINO' : 'MASCULINO', active: true
      });
      scanNotice = 'Jugador creado correctamente.';
      showScan = false;
      scanFile = null; scanImgPreview = ''; scanResult = null;
      await fetchPlayers();
    } catch (cause) {
      scanError = cause instanceof Error ? cause.message : 'No se pudo crear el jugador.';
    } finally { scanSaving = false; }
  }

  function closeScan() { showScan = false; scanFile = null; scanImgPreview = ''; scanResult = null; scanError = ''; }
</script>

<svelte:head><title>Jugadores | Ligas Deportivas</title></svelte:head>

<svelte:window onclick={menuClose} />

<main class="page-shell">
  <header class="page-header">
    <div>
      <p class="eyebrow">Personas</p>
      <h1>Jugadores</h1>
      <p class="muted">Administrá los jugadores, con carga manual, masiva o escaneo de DNI.</p>
    </div>
  </header>

  {#if loading && !paginated}
    <section class="loading-card">Cargando jugadores...</section>
  {:else}
    {#if error && !showForm && !showBulk && !showScan}<p class="error-banner">{error}</p>{/if}
    {#if notice}<p class="success-banner">{notice}</p>{/if}

    <section class="card-surface">
      <div class="filter-bar">
        <button class="button secondary" onclick={() => showFilters = !showFilters} aria-label="Filtros">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
          {showFilters ? 'Ocultar filtros' : 'Filtros'}
        </button>
        {#if canManage}
          <div class="add-menu" style="position:relative;">
            <button class="button primary add-btn" onclick={() => showMenu = !showMenu} aria-label="Agregar jugador">+</button>
            {#if showMenu}
              <!-- svelte-ignore a11y_click_events_have_key_events -->
              <!-- svelte-ignore a11y_no_static_element_interactions -->
              <div class="add-dropdown" onclick={(e) => e.stopPropagation()}>
                <button class="dropdown-item" onclick={openCreate}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/></svg>
                  Manual
                </button>
                <button class="dropdown-item" onclick={openBulk}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/></svg>
                  Masivo
                </button>
                <button class="dropdown-item" onclick={openScan}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><line x1="7" x2="7" y1="12" y2="12"/></svg>
                  Escanear DNI
                </button>
              </div>
            {/if}
          </div>
        {/if}
        <span class="count-pill">{paginated?.total ?? 0}</span>
      </div>
      {#if showFilters}
        <div class="filter-row">
          <input type="text" bind:value={search} oninput={onSearch} placeholder="Buscar por nombre o DNI..." />
        </div>
      {/if}

      {#if paginated && paginated.data.length === 0}
        <div class="empty-state compact-empty"><h2>Sin jugadores</h2><p>Crea el primer jugador para comenzar.</p></div>
      {:else if paginated}
        <div class="club-table">
          {#each paginated.data as player}
            <article class="club-row">
              <span class="club-color">{initials(player)}</span>
              <div class="club-info">
                <div class="club-name-row">
                  <strong>{player.firstName} {player.lastName}</strong>
                  {#if !player.active}<span class="inactive-badge">Inactivo</span>{/if}
                </div>
                <span>DNI {player.dni} · Nac. {birthYear(player.birthDate)} · {genderLabel(player.gender)}</span>
              </div>
              {#if canManage}<button class="icon-button" onclick={() => openEdit(player)}>Editar</button>{/if}
            </article>
          {/each}
        </div>
        {#if paginated.total > 25}
          <div class="pagination">
            <span>{paginated.total} jugadores</span>
            <div>
              <button class="button secondary" disabled={page <= 1} onclick={() => { page = Math.max(1, page - 1); fetchPlayers(); }}>Anterior</button>
              <button class="button secondary" disabled={page * 25 >= paginated.total} onclick={() => { page++; fetchPlayers(); }}>Siguiente</button>
            </div>
          </div>
        {/if}
      {/if}
    </section>
  {/if}
</main>

{#if showForm}
  <Modal onclose={closeModal}>
    <div class="modal-form">
      <p class="eyebrow">{editing ? 'Editar jugador' : 'Nuevo jugador'}</p>
      <h2>{editing ? `${editing.firstName} ${editing.lastName}` : 'Crear jugador'}</h2>
      {#if error}<p class="form-error">{error}</p>{/if}
      <form onsubmit={(event) => { event.preventDefault(); save(); }}>
        <label>Nombre<input bind:value={form.firstName} placeholder="Juan" disabled={saving} /></label>
        <label>Apellido<input bind:value={form.lastName} placeholder="Pérez" disabled={saving} /></label>
        <label>DNI<input bind:value={form.dni} placeholder="12345678" disabled={saving} /></label>
        <div class="form-row">
          <label>Fecha de nacimiento<input type="date" bind:value={form.birthDate} disabled={saving} /></label>
          <label>Género<select bind:value={form.gender} disabled={saving}><option value="MASCULINO">Masculino</option><option value="FEMENINO">Femenino</option></select></label>
        </div>
        <label class="checkbox-label"><input type="checkbox" bind:checked={form.active} disabled={saving} /> Jugador activo</label>

        <h3>Dirección</h3>
        <label>Calle<input bind:value={form.addressStreet} placeholder="Av. Siempre Viva" disabled={saving} /></label>
        <div class="form-row">
          <label>Número<input bind:value={form.addressNumber} placeholder="742" disabled={saving} /></label>
          <label>Ciudad<input bind:value={form.addressCity} placeholder="Springfield" disabled={saving} /></label>
        </div>

        <h3>Contacto de emergencia</h3>
        <label>Nombre<input bind:value={form.emergencyName} placeholder="María Pérez" disabled={saving} /></label>
        <div class="form-row">
          <label>Parentesco<input bind:value={form.emergencyRelationship} placeholder="Madre" disabled={saving} /></label>
          <label>Teléfono<input bind:value={form.emergencyPhone} placeholder="+549..." disabled={saving} /></label>
        </div>

        <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear jugador'}</button></div>
      </form>
    </div>
  </Modal>
{/if}

{#if showBulk}
  <Modal onclose={closeBulk}>
    <div class="modal-form bulk-modal">
      <p class="eyebrow">Carga masiva</p>
      <h2>Agregar jugadores</h2>
      <p class="muted" style="margin-bottom:1rem;">Completá los datos, cada fila es un jugador. Podés agregar o quitar filas.</p>

      {#if bulkError}<p class="form-error">{bulkError}</p>{/if}
      {#if bulkNotice}<p class="success-banner">{bulkNotice}</p>{/if}
      {#if bulkResults}
        <div class="bulk-results">
          <p>Creados: <strong>{bulkResults.created}</strong> · Omitidos (DNI existente): <strong>{bulkResults.skipped}</strong></p>
          {#if bulkResults.errors.length > 0}
            <div class="bulk-errors">
              {#each bulkResults.errors as e}<p class="form-error">{e}</p>{/each}
            </div>
          {/if}
        </div>
      {/if}

      <div class="bulk-table-wrapper">
        <table class="bulk-table">
          <thead>
            <tr>
              <th>#</th><th>Apellido</th><th>Nombre</th><th>DNI</th><th>Nac.</th><th>Gén.</th>
              <th>Dirección</th><th>Emergencia</th><th>Parent.</th><th>Tel.</th><th>Act.</th><th></th>
            </tr>
          </thead>
          <tbody>
            {#each bulkRows as row, i}
              <tr>
                <td class="row-num">{i + 1}</td>
                <td><input bind:value={row.lastName} placeholder="Apellido" /></td>
                <td><input bind:value={row.firstName} placeholder="Nombre" /></td>
                <td><input bind:value={row.dni} placeholder="DNI" style="max-width:90px" /></td>
                <td><input type="date" bind:value={row.birthDate} style="max-width:120px" /></td>
                <td>
                  <select bind:value={row.gender} class="compact-select">
                    <option value="MASCULINO">M</option>
                    <option value="FEMENINO">F</option>
                  </select>
                </td>
                <td>
                  <div class="inline-inputs">
                    <input bind:value={row.addressStreet} placeholder="Calle" style="max-width:100px" />
                    <input bind:value={row.addressNumber} placeholder="N°" style="max-width:50px" />
                    <input bind:value={row.addressCity} placeholder="Loc." style="max-width:80px" />
                  </div>
                </td>
                <td><input bind:value={row.emergencyName} placeholder="Nombre" style="max-width:100px" /></td>
                <td><input bind:value={row.emergencyRelationship} placeholder="Vínculo" style="max-width:80px" /></td>
                <td><input bind:value={row.emergencyPhone} placeholder="Tel" style="max-width:100px" /></td>
                <td class="td-center"><input type="checkbox" bind:checked={row.active} /></td>
                <td><button type="button" class="icon-button remove-row" onclick={() => removeBulkRow(i)} aria-label="Eliminar fila">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" x2="6" y1="6" y2="18"/><line x1="6" x2="18" y1="6" y2="18"/></svg>
                </button></td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>

      <div class="bulk-actions">
        <button class="button secondary" onclick={addBulkRow} disabled={bulkSaving}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
          Agregar fila
        </button>
        <span class="muted" style="font-size:.8rem">{bulkRows.length} filas</span>
        <button class="button primary" onclick={saveBulk} disabled={bulkSaving}>
          {bulkSaving ? 'Guardando...' : 'Guardar todo'}
        </button>
      </div>
    </div>
  </Modal>
{/if}

{#if showScan}
  <Modal onclose={closeScan}>
    <div class="modal-form scan-modal">
      <p class="eyebrow">Escanear DNI</p>
      <h2>Capturar documento</h2>
      <p class="muted" style="margin-bottom:1rem;">Tomá una foto del DNI para extraer los datos automáticamente.</p>

      {#if scanError}<p class="form-error">{scanError}</p>{/if}
      {#if scanNotice}<p class="success-banner">{scanNotice}</p>{/if}

      {#if !scanResult}
        <div class="scan-capture">
          <label class="scan-upload-area">
            {#if scanImgPreview}
              <img src={scanImgPreview} alt="Vista previa del DNI" class="scan-preview" />
            {:else}
              <div class="scan-placeholder">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="m21 15-5-5L5 21"/></svg>
                <span>Tocá para capturar o seleccionar una foto del DNI</span>
              </div>
            {/if}
            <input type="file" accept="image/*" capture="environment" onchange={handleScanFileChange} hidden />
          </label>

          <button class="button primary" onclick={doScan} disabled={!scanFile || scanLoading} style="margin-top:.75rem">
            {scanLoading ? 'Escaneando...' : 'Escanear DNI'}
          </button>
        </div>
      {:else}
        <div class="scan-result">
          <div class="scan-result-card">
            <div class="scan-fields">
              <div class="scan-field"><span class="info-label">Apellido</span><strong>{scanResult.lastName}</strong></div>
              <div class="scan-field"><span class="info-label">Nombre</span><strong>{scanResult.firstName}</strong></div>
              <div class="scan-field"><span class="info-label">DNI</span><strong>{scanResult.dni}</strong></div>
              <div class="scan-field"><span class="info-label">Nacimiento</span><strong>{scanResult.birthDate}</strong></div>
              <div class="scan-field"><span class="info-label">Sexo</span><strong>{scanResult.sex === 'M' ? 'Masculino' : scanResult.sex === 'F' ? 'Femenino' : scanResult.sex}</strong></div>
            </div>
          </div>
          <div class="scan-actions">
            <button class="button secondary" onclick={() => { scanResult = null; scanError = ''; }}>Escanear otro</button>
            <button class="button primary" onclick={createFromScan} disabled={scanSaving}>
              {scanSaving ? 'Creando...' : 'Crear jugador'}
            </button>
          </div>
        </div>
      {/if}
    </div>
  </Modal>
{/if}

<style>
  .modal-form h2 { margin: .5rem 0 1.5rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.6rem; letter-spacing: -.04em; }
  .modal-form h3 { margin: 1.5rem 0 .75rem; font-family: 'Space Grotesk', sans-serif; font-size: 1.05rem; color: var(--color-text-muted); }
  .modal-form form { margin-top: 0; }

  .add-btn { padding: .55rem .8rem; font-size: 1.2rem; line-height: 1; font-weight: 700; border-radius: .6rem; min-width: 2.5rem; }
  .add-dropdown {
    position: absolute; top: 100%; right: 0; margin-top: .35rem; z-index: 50;
    background: var(--color-surface); border: 1px solid var(--color-border); border-radius: .7rem;
    padding: .35rem; min-width: 180px; box-shadow: 0 4px 16px var(--color-shadow);
  }
  .dropdown-item {
    display: flex; align-items: center; gap: .6rem;
    width: 100%; padding: .55rem .7rem; border: 0; border-radius: .5rem;
    background: transparent; color: var(--color-text); font-size: .84rem; font-weight: 500;
    cursor: pointer; text-align: left; font-family: inherit;
    transition: background 150ms ease;
  }
  .dropdown-item:hover { background: var(--color-surface-hover); }

  .bulk-modal { max-width: 100% !important; width: 95vw; max-width: 1200px; }
  .bulk-table-wrapper { overflow-x: auto; margin: .5rem 0 1rem; border: 1px solid var(--color-border); border-radius: .7rem; }
  .bulk-table { width: 100%; border-collapse: collapse; font-size: .82rem; min-width: 1000px; }
  .bulk-table thead { position: sticky; top: 0; z-index: 1; }
  .bulk-table th {
    background: var(--color-surface-hover); color: var(--color-text-muted);
    font-size: .7rem; font-weight: 700; text-transform: uppercase; letter-spacing: .04em;
    padding: .5rem .4rem; text-align: left; white-space: nowrap;
    border-bottom: 1px solid var(--color-border);
  }
  .bulk-table th:first-child { padding-left: .7rem; border-radius: .7rem 0 0 0; }
  .bulk-table th:last-child { padding-right: .7rem; border-radius: 0 .7rem 0 0; }
  .bulk-table td { padding: .3rem .4rem; border-bottom: 1px solid var(--color-border); vertical-align: middle; }
  .bulk-table td:first-child { padding-left: .7rem; }
  .bulk-table td:last-child { padding-right: .4rem; }
  .bulk-table tbody tr:hover { background: var(--color-surface-hover); }
  .bulk-table input, .bulk-table select {
    width: 100%; max-width: 130px; padding: .35rem .4rem;
    border: 1px solid var(--color-input-border); border-radius: .4rem;
    background: var(--color-input); color: var(--color-text); font-size: .8rem; font-family: inherit;
    box-sizing: border-box;
  }
  .bulk-table input:focus, .bulk-table select:focus { outline: none; border-color: var(--color-input-focus); }
  .row-num { font-weight: 600; color: var(--color-text-muted); font-size: .75rem; text-align: center; width: 2rem; }
  .td-center { text-align: center; }
  .inline-inputs { display: flex; gap: .25rem; }
  .inline-inputs input { flex: 1; min-width: 0; }
  .compact-select { max-width: 50px !important; padding: .35rem .2rem !important; }
  .remove-row { padding: .2rem; opacity: .4; }
  .remove-row:hover { opacity: 1; color: var(--color-error); }

  .bulk-actions { display: flex; align-items: center; gap: .75rem; margin-top: .5rem; }
  .bulk-actions .button.primary { margin-left: auto; }
  .bulk-results {
    background: var(--color-success-bg); border: 1px solid var(--color-success);
    border-radius: .6rem; padding: .75rem 1rem; margin-bottom: .75rem;
  }
  .bulk-errors { margin-top: .5rem; }

  .scan-modal { max-width: 520px; }
  .scan-capture { display: grid; gap: .5rem; }
  .scan-upload-area {
    display: block; cursor: pointer; border: 2px dashed var(--color-border);
    border-radius: .75rem; overflow: hidden; transition: border-color 150ms ease;
  }
  .scan-upload-area:hover { border-color: var(--color-accent); }
  .scan-preview { width: 100%; max-height: 300px; object-fit: contain; display: block; }
  .scan-placeholder {
    display: grid; place-items: center; gap: .75rem; padding: 3rem 1.5rem;
    color: var(--color-text-muted); font-size: .82rem; text-align: center;
  }
  .scan-result { display: grid; gap: 1rem; }
  .scan-result-card { background: var(--color-surface-hover); border-radius: .7rem; padding: 1rem; }
  .scan-fields { display: grid; gap: .6rem; }
  .scan-field { display: flex; justify-content: space-between; align-items: center; gap: .5rem; }
  .scan-field .info-label { font-size: .78rem; color: var(--color-text-muted); font-weight: 600; }
  .scan-field strong { font-size: .9rem; }
  .scan-actions { display: flex; gap: .5rem; justify-content: flex-end; }
</style>
