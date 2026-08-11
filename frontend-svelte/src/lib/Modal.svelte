<script lang="ts">
  import type { Snippet } from 'svelte';
  let { onclose = () => {}, wide = false, children }: { onclose?: () => void; wide?: boolean; children: Snippet } = $props();
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="modal-backdrop" onclick={onclose}>
  <div class="modal-panel" class:wide onclick={(e) => e.stopPropagation()}>
    <button class="modal-close" onclick={onclose} aria-label="Cerrar">&times;</button>
    <div class="modal-body">
      {@render children()}
    </div>
  </div>
</div>

<style>
  .modal-backdrop {
    position: fixed; inset: 0; z-index: 100;
    display: grid; place-items: center; padding: 1rem;
    background: var(--color-overlay); backdrop-filter: blur(4px);
  }
  .modal-panel {
    position: relative; width: min(100%, 560px); max-height: 90vh;
    border: 1px solid var(--color-border); border-radius: 1.2rem;
    background: var(--color-surface); box-shadow: 0 30px 80px var(--color-shadow);
    display: flex; flex-direction: column;
  }
  .modal-panel.wide { width: min(98vw, 1600px); }
  .modal-body {
    overflow-y: auto; padding: clamp(1.5rem, 4vw, 2.5rem);
    scrollbar-width: thin;
  }
  .modal-close {
    position: absolute; top: .8rem; right: 1rem;
    border: 0; background: none; font-size: 1.4rem; color: var(--color-text-muted); cursor: pointer;
  }
</style>
