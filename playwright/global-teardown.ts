async function teardown(): Promise<void> {
  const state = globalThis.__e2e__;
  if (!state) {
    console.warn('[teardown] No global state — nothing to clean up.');
    return;
  }
  // Stop flutter servers first so their callable retries don't keep the
  // emulator busy past shutdown. Each flavor has its own handle; attach-mode
  // flavors (PW_BASE_URL_*) have no entry in the map, so iteration skips them.
  for (const handle of Object.values(state.flutter)) {
    if (!handle) continue;
    try {
      await handle.stop();
    } catch (err) {
      console.error(`[teardown] flutter:${handle.flavor}.stop failed`, err);
    }
  }
  try {
    await state.emulators.stop();
  } catch (err) {
    console.error('[teardown] emulators.stop failed', err);
  }
}

export default teardown;
