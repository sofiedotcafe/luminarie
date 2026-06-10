<!-- markdownlint-disable MD033 MD041 MD010 MD013 -->

<div>
  <img
    align="left"
    src="assets/flake.png"
    alt='"Mushroom Nix Logo" by @fsnkty'
    width="50"
  />
  <div style="padding-left: 60px">
    <strong>
      <big>Luminarie</big>
    <br>
      <span style="font-size: small;">
        <a href="#contents">Contents</a> ·
        <a href="#usage">Usage</a> ·
        <a href="#license">License</a>
      </span>
    </strong>
    </div>
</div>

<p align="left">
  <img src="assets/macchiato-palette.png" width="400" / alt="Catppuccin Macchiato Palette">
</p>

<p align="left">
	<a href="https://github.com/sofiedotcafe/luminarie/stargazers">
		<img alt="Stargazers" src="https://img.shields.io/github/stars/sofiedotcafe/luminarie?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/sofiedotcafe/luminarie">
		<img alt="Repo Size" src="https://img.shields.io/github/repo-size/sofiedotcafe/luminarie.svg?style=for-the-badge&logo=github&color=F2CDCD&logoColor=D9E0EE&labelColor=302D41"/></a>
	<a href="https://github.com/sofiedotcafe/luminarie/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/sofiedotcafe/luminarie?style=for-the-badge&logo=gitbook&color=B5E8E0&logoColor=D9E0EE&labelColor=302D41"></a>
  <a href="https://github.com/sofiedotcafe/luminarie/tree/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/License-GPLv3+-907385605422448742?style=for-the-badge&logo=GPL&color=DDB6F2&logoColor=D9E0EE&labelColor=302D41"></a>
  <br><a href="https://builtwithnix.org">
      <img alt="Built with Nix" src="https://builtwithnix.org/badge.svg"></a>
</p>

> [!NOTE]  
> hii~ this flake is still evolving a lot! i'm slowly moving away from [nixpkgs](https://github.com/NixOS/nixpkgs) — partly because of [the recent moderation drama](https://discourse.nixos.org/t/the-sc-prepared-to-lie-to-us-and-what-we-can-do-about-it-whistleblow/70103) — and switching to [aux](https://auxolotl.org/) to [npins](https://github.com/nix-community/npins) for better pinning and reproducibility. flakes don't really have a standard...  
>
> I'm refactoring the whole modular setup to match little how [lix](https://lix.systems) and [aux](https://auxolotl.org/) do their infra. and eventually I want to migrate this project to use e.g. aux, they are also much nicer due to their queer values so a `arf arf`~ >:3 trans techwitch girl powered by lix (lesbian nix) would be greatly welcomed in that community 💜🩷🐾🏳️‍⚧️  

In this repo is the Nix ([Lix](https://lix.systems/)) Flake *Luminarie*, which contains the configurations for all my [NixOS](https://nixos.org)-based servers and desktops.

### Contents

```text
luminarie
├── hosts               # Configuration for specific hosts 
├── lib                 # Helpers
├── packages            # Overlays for Nixpkgs
├── packages            # Package definitions
├── modules             # Modules
│  ├── home             # Configuration modules for home-manager
│  ├── nixos            # Configuration for NixOS hosts
└── devshell            # Shell environment for the infra repo
```

### Usage

NixOS hosts configurations are published as flake outputs.<br> These outputs can be then consumed and used by `nixos-rebuild`. Home Manager configurations are embedded inside the NixOS ones.

You can use these configurations with, for example:

```sh
nixos-rebuild switch --flake github:sofiedotcafe/luminarie#azalea
```

You may also use the included Rust [task runner](task.toml) to alias these longer commands.

---

### License

The code in this repository is licensed under the GNU General Public License v3 (GPLv3 or later). <br>For more details, see the [LICENSE](LICENSE) file.
