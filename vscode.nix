{ config, pkgs, ... }:
let
  vscode-brew = pkgs.stdenv.mkDerivation {
    name = "vscode-brew";
    pname = "vscode";

    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cd $out/bin
      ln -s /opt/homebrew/bin/code
    '';
  };
  vscode-extensions = [
    "eamodio.gitlens"
    "esbenp.prettier-vscode"
    "GitHub.vscode-pull-request-github"
    "iocave.customize-ui"
    "iocave.monkey-patch"
    "jdinhlife.gruvbox"
    "jnoortheen.nix-ide"
    "JuanBlanco.solidity"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vsliveshare.vsliveshare"
    "redhat.vscode-yaml"
    "rust-lang.rust-analyzer"
    "styled-components.vscode-styled-components"
    "vadimcn.vscode-lldb"
    "vscodevim.vim"
  ];
  vscode-settings = {
    "telemetry.telemetryLevel" = "off";
    "redhat.telemetry.enabled" = false;
    "workbench.colorTheme" = "Gruvbox Dark Hard";
    "workbench.preferredDarkColorTheme" = "Gruvbox Dark Hard";
    "workbench.preferredLightColorTheme" = "Gruvbox Light Medium";
    "window.autoDetectColorScheme" = true;
    "workbench.fontAliasing" = "auto";
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "terminal.integrated.cursorStyle" = "underline";
    "gitlens.codeLens.enabled" = false;
    "security.workspace.trust.untrustedFiles" = "open";
    "javascript.format.semicolons" = "insert";
    "typescript.format.semicolons" = "insert";
    "javascript.preferences.quoteStyle" = "single";
    "typescript.preferences.quoteStyle" = "single";
    "[markdown]" = {
      "editor.unicodeHighlight.ambiguousCharacters" = false;
      "editor.unicodeHighlight.invisibleCharacters" = false;
      "editor.wordWrap" = "on";
      "editor.wordWrapColumn" = 120;
      "editor.quickSuggestions" = {
        "comments" = "off";
        "strings" = "off";
        "other" = "off";
      };
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.rnix-lsp}/bin/rnix-lsp";
    "nix.formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
    "editor.tabSize" = 2;
    "editor.fontFamily" = "Hack, Menlo, Monaco, 'Courier New', monospace";
    "liveshare.showInStatusBar" = "whileCollaborating";
    "editor.acceptSuggestionOnCommitCharacter" = false;
    "terminal.external.osxExec" = "iTerm.app";
    "editor.rulers" = [ ];
    "workbench.sideBar.location" = "right";
    "customizeUI.activityBar" = "bottom";
    "window.titleBarStyle" = "native";
    "customizeUI.titleBar" = "inline";
    "customizeUI.activityBarHideSettings" = true;
    "customizeUI.statusBarPosition" = "under-panel";
    "editor.minimap.enabled" = false;
    "workbench.startupEditor" = "readme";
    "git.autofetch" = false;
    "gitlens.statusBar.enabled" = false;
    "gitlens.statusBar.pullRequests.enabled" = false;
    "githubIssues.assignWhenWorking" = false;
    "gitlens.menus" = {
      "editor" = {
        "blame" = false;
        "clipboard" = false;
        "compare" = false;
        "history" = false;
        "remote" = false;
      };
      "editorGroup" = {
        "blame" = false;
        "compare" = false;
      };
      "editorTab" = {
        "clipboard" = false;
        "compare" = false;
        "history" = false;
        "remote" = false;
      };
      "explorer" = {
        "clipboard" = false;
        "compare" = false;
        "history" = false;
        "remote" = false;
      };
      "scm" = {
        "authors" = false;
      };
      "scmGroupInline" = {
        "stash" = false;
      };
      "scmGroup" = {
        "compare" = false;
        "openClose" = false;
        "stash" = false;
      };
      "scmItem" = {
        "clipboard" = false;
        "compare" = false;
        "history" = false;
        "remote" = false;
        "stash" = false;
      };
    };
    "breadcrumbs.enabled" = false;
    "editor.padding.bottom" = 12;
    "editor.padding.top" = 16;
    "editor.folding" = false;
    "editor.guides.indentation" = false;
    "editor.renderLineHighlight" = "gutter";
    "editor.cursorBlinking" = "phase";
    "editor.cursorStyle" = "line-thin";
    "editor.inlayHints.enabled" = "off";
    "vim.easymotion" = true;
    "githubPullRequests.pullBranch" = "never";
    "vs-kubernetes" = {
      "vs-kubernetes.crd-code-completion" = "disabled";
    };
    "terminal.integrated.shellIntegration.decorationsEnabled" = "never";
    "extensions.ignoreRecommendations" = true;
    "workbench.statusBar.visible" = false;
  };
  settings-json = pkgs.runCommand "vscode-settings" { } ''
    cat << EOF | ${pkgs.jq}/bin/jq . > $out
    ${builtins.toJSON vscode-settings}
    EOF
  '';
  settings-dir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "$HOME/Library/Application Support/Code/User"
    else
      "${config.xdg.configHome}/Code/User";
  home-module = { pkgs, lib, ... }: {
    config = {
      home.packages = [ vscode-brew ];

      home.activation.install-extensions =
        let
          install-cmd = lib.concatMapStrings (ext: "$DRY_RUN_CMD ${vscode-brew}/bin/code --install-extension ${ext}\n") vscode-extensions;
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] install-cmd;

      home.activation.copy-settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cp -f "${settings-json}" "${settings-dir}/settings.json"
      '';

      programs.zsh.shellAliases = {
        vscode-settings-diff = "${pkgs.delta}/bin/delta  \"${settings-json}\" \"${settings-dir}/settings.json\"";
      };
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
        "visual-studio-code"
      ];
    };

    home-manager.sharedModules = [
      home-module
    ];
  };
}
