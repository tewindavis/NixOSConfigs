{ pkgs, ... }:

{
  home.username = "td";
  home.homeDirectory = "/home/td";

  home.stateVersion = "25.11";

  # User specific packages
  home.packages = with pkgs; [
    # Modern CLI
    ripgrep
    bat
    eza
    fd
    bottom

    # Languages & Toolchains
    # Rust
    rustup
    rustlings
    
    # Zig
    zig
    zls # Zig Language Server
    
    # C/C++
    gcc
    gnumake
    cmake
    gdb # Already in rl-binary for one host, but good for all
    
    # Python
    (python3.withPackages (ps: with ps; [
      pip
      virtualenv
      black # formatter
      isort # import sorter
    ]))

    # LSPs, Formatters, Linters for LazyVim
    lua-language-server
    stylua
    rust-analyzer
    pyright
    ruff # Fast python linter/formatter
    nodePackages.vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    nodePackages.typescript-language-server
    yaml-language-server
    nil # Nix LSP
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    # Extra packages for nvim functionality
    extraPackages = with pkgs; [
      git
      gcc
      gnumake
      unzip
      wget
      curl
      tree-sitter
    ];
  };

  # Link Neovim Config
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Modern CLI tools with built-in HM modules
  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  # Default Browser / Mime Apps
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "brave-browser.desktop" ];
      "text/xml" = [ "brave-browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
    };
  };
  
  # Direnv for automatic nix-shell/flake loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
