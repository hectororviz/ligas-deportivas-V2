<script lang="ts">
  import { onMount } from 'svelte';
  import lottie, { type AnimationItem } from 'lottie-web';

  interface Props {
    url: string;
    onDone: () => void;
  }

  let { url, onDone }: Props = $props();

  let container = $state<HTMLDivElement>();
  let fading = $state(false);

  onMount(() => {
    let animation: AnimationItem | undefined;
    try {
      animation = lottie.loadAnimation({
        container: container as HTMLDivElement,
        renderer: 'svg',
        loop: true,
        autoplay: true,
        path: url,
      });
    } catch {
      animation = undefined;
    }

    const showTimer = setTimeout(() => {
      fading = true;
    }, 5000);

    const doneTimer = setTimeout(() => {
      onDone();
    }, 5450);

    return () => {
      clearTimeout(showTimer);
      clearTimeout(doneTimer);
      animation?.destroy();
    };
  });
</script>

<div class="splash" class:fading>
  <div class="splash-anim" bind:this={container}></div>
</div>

<style>
  .splash {
    position: fixed;
    inset: 0;
    z-index: 9999;
    display: grid;
    place-items: center;
    background: var(--color-surface);
    transition: opacity 400ms ease;
    opacity: 1;
  }
  .splash.fading {
    opacity: 0;
    pointer-events: none;
  }
  .splash-anim {
    width: min(70vw, 240px);
    height: min(70vw, 240px);
  }
  .splash-anim :global(svg) {
    width: 100%;
    height: 100%;
  }
</style>
