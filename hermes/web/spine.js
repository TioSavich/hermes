// Shared page spine for repo-root-relative assets and manifests.
(function () {
  const DEFAULT_ROOT = '../';
  const DEFAULT_ASSET_MANIFEST = 'representation/asset_manifest.json';

  function root(options = {}) {
    return Object.prototype.hasOwnProperty.call(options, 'root')
      ? options.root
      : DEFAULT_ROOT;
  }

  function assetPath(path, options = {}) {
    const clean = String(path || '').replace(/^\/+/, '');
    return root(options) + clean.split('/').map(encodeURIComponent).join('/');
  }

  async function loadJson(path, options = {}) {
    const response = await fetch(assetPath(path, options));
    if (!response.ok) throw new Error(response.status);
    return response.json();
  }

  function loadAssetManifest(options = {}) {
    return loadJson(options.manifestPath || DEFAULT_ASSET_MANIFEST, options);
  }

  window.Spine = {
    assetPath,
    loadAssetManifest,
    loadJson,
    root,
  };
})();
