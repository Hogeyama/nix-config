{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  overlays = [
    inputs.nix-alien.overlays.default
    (final: prev:
    let
      patchedPython3 = prev.python3.override {
        packageOverrides = pyfinal: pyprev: {
          pypass = pyprev.pypass.overridePythonAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              python - <<'PY'
              from pathlib import Path

              path = Path("pypass/passwordstore.py")
              text = path.read_text()
              text = text.replace(
                  "        if os.path.isfile(gpg_id_file):\n"
                  "            self.gpg_id = open(gpg_id_file, 'r').read().strip()\n"
                  "        else:\n",
                  "        if os.path.isfile(gpg_id_file):\n"
                  "            with open(gpg_id_file, 'r') as gpg_id_handle:\n"
                  "                self.gpg_ids = [\n"
                  "                    line.strip() for line in gpg_id_handle\n"
                  "                    if line.strip()\n"
                  "                ]\n"
                  "            self.gpg_id = self.gpg_ids[0] if self.gpg_ids else None\n"
                  "            if not self.gpg_ids:\n"
                  "                raise Exception(\"could not find any gpg-id recipients\")\n"
                  "        else:\n"
              )
              text = text.replace(
                  "        gpg = subprocess.Popen(\n"
                  "            [\n"
                  "                GPG_BIN,\n"
                  "                '-e',\n"
                  "                '-r', self.gpg_id,\n"
                  "                '--batch',\n"
                  "                '--use-agent',\n"
                  "                '--no-tty',\n"
                  "                '--yes',\n"
                  "                '-o', passfile_path\n"
                  "            ],\n",
                  "        gpg = subprocess.Popen(\n"
                  "            [GPG_BIN, '-e']\n"
                  "            + [arg for recipient in self.gpg_ids for arg in ('-r', recipient)]\n"
                  "            + [\n"
                  "                '--batch',\n"
                  "                '--use-agent',\n"
                  "                '--no-tty',\n"
                  "                '--yes',\n"
                  "                '-o', passfile_path\n"
                  "            ],\n"
              )
              path.write_text(text)
              PY
            '';
          });
        };
      };
    in
    {
      unstable = inputs.nixpkgs-unstable.outputs.legacyPackages.${system};
      haskell-updates = inputs.nixpkgs-for-haskell.outputs.legacyPackages.${system};
      my-fzf-wrapper = inputs.my-fzf-wrapper.outputs.packages.${system}.default;
      vscode-insiders-nightly = inputs.vscode-insiders-nightly.packages.${system}.vscode-insider;

      illusion = import ./illusion { pkgs = final; };
      udev-gothic = import ./udev-gothic { inherit (final) fetchzip; };
      my-xmobar = import ./my-xmobar { pkgs = final.haskell-updates; };
      my-xmonad = import ./my-xmonad { pkgs = final.haskell-updates; };
      pass-secret-service = prev.pass-secret-service.override { python3 = patchedPython3; };
    })
  ];
in
{ nixpkgs.overlays = overlays; }
