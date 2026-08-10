<script lang="ts">
  import type { Snippet } from 'svelte';
  let { onclose = () => {}, children }: { onclose?: () => void; children: Snippet } = $props();
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="modal-backdrop" onclick={onclose}>
  <div class="modal-panel" onclick={(e) => e.stopPropagation()}>
    <button class="modal-close" onclick={onclose} aria-label="Cerrar">&times;</button>
    {@render children()}
  </div>
</div>

<style>
  .modal-backdrop {
    position: fixed; inset: 0; z-index: 100;
    display: grid; place-items: center; padding: 1rem;
    background: #0f1f1aaa; backdrop-filter: blur(4px);
  }
  .modal-panel {
    position: relative; width: min(100%, 560px); max-height: 90vh; overflow-y: auto;
    border: 1px solid #dfe3d7; border-radius: 1.2rem; padding: clamp(1.5rem, 4vw, 2.5rem);
    background: #fff; box-shadow: 0 30px 80px #0f1f1a33;
  }
  .modal-close {
    position: absolute; top: .8rem; right: 1rem;
    border: 0; background: none; font-size: 1.4rem; color: #66736c; cursor: pointer;
  }
</style>
