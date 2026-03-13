{{flutter_js}}
{{flutter_build_config}}

(function() {
  var loading = document.getElementById("loading");
  function hideLoading() {
    if (loading) loading.style.display = "none";
  }
  _flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
      try {
        var appRunner = await engineInitializer.initializeEngine();
        await appRunner.runApp();
      } finally {
        hideLoading();
      }
    }
  });
})();
