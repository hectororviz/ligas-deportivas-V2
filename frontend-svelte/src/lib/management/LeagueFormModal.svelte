<script lang="ts">
  import Modal from '$lib/Modal.svelte';
  import { createLeague, updateLeague, type League } from '$lib/api';

  const days = [
    ['DOMINGO', 'Domingo'], ['LUNES', 'Lunes'], ['MARTES', 'Martes'],
    ['MIERCOLES', 'Miércoles'], ['JUEVES', 'Jueves'], ['VIERNES', 'Viernes'], ['SABADO', 'Sábado']
  ];

  let { editing, onclose, onsaved }: {
    editing: League | null;
    onclose: () => void;
    onsaved: (league: League) => void;
  } = $props();

  let saving = $state(false);
  let error = $state('');
  let form = $state({ name: '', slug: '', colorHex: '#0057B8', gameDay: 'DOMINGO' });

  $effect(() => {
    form = editing
      ? { name: editing.name, slug: editing.slug, colorHex: editing.colorHex, gameDay: editing.gameDay }
      : { name: '', slug: '', colorHex: '#0057B8', gameDay: 'DOMINGO' };
    error = '';
  });

  function slugify(value: string) {
    return value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }

  async function save() {
    error = '';
    if (!form.name.trim()) { error = 'Ingresa el nombre de la liga.'; return; }
    saving = true;
    const input = { ...form, name: form.name.trim(), slug: form.slug.trim() || slugify(form.name) };
    try {
      const saved = editing ? await updateLeague(editing.id, input) : await createLeague(input);
      onsaved(saved);
    } catch (cause) {
      error = cause instanceof Error ? cause.message : 'No se pudo guardar la liga.';
    } finally {
      saving = false;
    }
  }
</script>

<Modal {onclose}>
  <div class="modal-form">
    <p class="eyebrow">{editing ? 'Editar liga' : 'Nueva liga'}</p>
    <h2>{editing ? editing.name || 'Editar' : 'Crear liga'}</h2>
    {#if error}<p class="form-error">{error}</p>{/if}
    <form onsubmit={(event) => { event.preventDefault(); save(); }}>
      <label>Nombre<input bind:value={form.name} placeholder="Liga Metropolitana" disabled={saving} /></label>
      <label>Identificador<input bind:value={form.slug} placeholder="liga-metropolitana" disabled={saving} /></label>
      <label>Día de juego<select bind:value={form.gameDay} disabled={saving}>{#each days as [value, label]}<option value={value}>{label}</option>{/each}</select></label>
      <label>Color distintivo<div class="color-input"><input type="color" bind:value={form.colorHex} disabled={saving} /><input bind:value={form.colorHex} disabled={saving} /></div></label>
      <div class="form-actions"><button class="button primary" type="submit" disabled={saving}>{saving ? 'Guardando...' : editing ? 'Guardar cambios' : 'Crear liga'}</button></div>
    </form>
  </div>
</Modal>
