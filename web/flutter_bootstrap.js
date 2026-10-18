{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('ug-splash');
    if (splash) {
      splash.style.opacity = '0';
      splash.style.transition = 'opacity 0.15s ease-out';
      setTimeout(function() {
        if (splash && splash.parentNode) {
          splash.parentNode.removeChild(splash);
        }
      }, 160);
    }
  }
});
