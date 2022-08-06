{ pkgs, ... }:
let
  iterm2-config = pkgs.stdenv.mkDerivation {
    name = "iterm2-config";
    src = ./com.googlecode.iterm2.plist;
    phases = ["installPhase"];
    installPhase = ''
      cp $src $out
    '';
  };
  home-module = { pkgs, lib, ... }: {
    config = {
      home.activation.config-iterm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD cp -f ${iterm2-config} ~/Library/Preferences/com.googlecode.iterm2.plist
      '';
    };
  };
in
{
  config = {
    homebrew = {
      enable = true;
      autoUpdate = true;
      cleanup = "zap";

      taps = [
        "homebrew/bundle"
        "homebrew/cask"
        "homebrew/cask-versions"
        "homebrew/core"
      ];

      casks = [
        "iterm2-beta"
      ];
    };

    home-manager.sharedModules = [
      home-module
    ];
  };
}