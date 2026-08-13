# Modifications overlay - changes to existing packages
_final: prev: {
  # RomM's gunicorn workers die on boot with fastapi-pagination 0.15.16, which
  # mis-detects our fastapi and calls get_body_field() with the wrong keyword.
  # See the patch header for the full story; drop both once fastapi 0.141.1
  # reaches nixos-unstable (nixpkgs#548924, merged to staging 2026-08-11).
  #
  # Scoped to romm's own python (it runs from `passthru.pythonEnv`) so that no
  # other python package on the system loses its binary cache.
  romm = prev.romm.override {
    python3 = prev.python3.override {
      packageOverrides = _pyfinal: pyprev: {
        fastapi-pagination = pyprev.fastapi-pagination.overridePythonAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./fastapi-pagination-old-fastapi.patch ];
        });
      };
    };
  };
}
