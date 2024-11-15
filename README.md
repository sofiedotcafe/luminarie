<!-- markdownlint-disable MD033 MD041 MD010 MD013 -->

<h3 align="center">
	<img src="assets/flake.png" width="100" alt="Logo"/><br>
	<img src="assets/transparent.png" height="30" width="0px"/ alt="">
	Luminarie
	<img src="assets/transparent.png" height="30" width="0px"/ alt="">
</h3>

<h6 align="center">
  <a href="#contents">Contents</a>
  ·
  <a href="#usage">Usage</a>
  ·
  <a href="#licenses">Licenses</a>
</h6>

<p align="center">
  <img src="assets/macchiato-palette.png" width="400" / alt="Catppuccin Macchiato Palette">
</p>

<p align="center">
	<a href="https://github.com/jh-devv/luminarie/stargazers">
		<img alt="Stargazers" src="https://img.shields.io/github/stars/jh-devv/luminarie?style=for-the-badge&logo=starship&color=C9CBFF&logoColor=D9E0EE&labelColor=302D41"></a>
	<a href="https://github.com/jh-devv/luminarie">
		<img alt="Repo Size" src="https://img.shields.io/github/repo-size/jh-devv/luminarie.svg?style=for-the-badge&logo=github&color=F2CDCD&logoColor=D9E0EE&labelColor=302D41"/></a>
	<a href="https://github.com/jh-devv/luminarie/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/jh-devv/luminarie?style=for-the-badge&logo=gitbook&color=B5E8E0&logoColor=D9E0EE&labelColor=302D41"></a>
  <a href="https://github.com/jh-devv/luminarie/tree/main/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/License-AGPL-907385605422448742?style=for-the-badge&logo=agpl&color=DDB6F2&logoColor=D9E0EE&labelColor=302D41"></a>
  <br><a href="https://builtwithnix.org">
      <img alt="Built with Nix" src="https://builtwithnix.org/badge.svg"></a>
</p>

<p align="center">
Luminarie, the flake for my NixOS setups like `Aisu` ( ˶ˆ꒳ˆ˵ )
</p>

---

&nbsp; ![Screenshot Showcase](/assets/showcase.png)

### Contents

- [modules/nixos](/modules/nixos/): NixOS common configs
- [modules/home](/modules/home/): HM common configs
- [hosts](/hosts): host-specific configuration
- [home](/home): user-specific configuration
- [pkgs](/pkgs): package definitions

### Usage

> [!TIP]
> You can find an `just` build script that has the aliases for the most used rebuild commands on the project root. It defaults to trying to apply an configuration from the current directory with the same as your `hostname` and `username`.
> This behavior can be overridden using `just host="<new host>" user="<new user> origin="<new origin>"` or manually from the file.

#### ➔ NixOS

> [!CAUTION]
> You will need to edit my [host files](/home/jh-devv/luminarie/hosts/) to be suitable for your system, for now; at least edit the `hardware.nix` file to suit your needs or edit your disk table. Lastly, add your system to the flake by adding it to [/hosts/default.nix](/hosts/default.nix)!

- Format system using the NixOS installer ISO. In the future, when disko is in
  use: You can use my premade ISOS for this!
- Format partitions following your own `hardware-configuration.nix` or use
  [disko](https://github.com/nix-community/disko).
- Install system pointing the installer to the flake.

- For the rebuild command, you can use just or as you probably know it is:

```sh
sudo nixos-rebuild switch --flake .#aisu
```

> [!TIP]
> In the future, when I have the time. I will make this flake use [impermanence](https://github.com/nix-community/impermanence).

- [ ] Switch to impermanence and use disko.
- [ ] Publish ISOs and write GitHub actions for it.

#### ➔ Home Manager

> [!NOTE]
> Make sure to first have Home Manager installed or use my NixOS flake!

- The install command should be the same as the rebuild command, if not; check
  the wiki!
- Same as with NixOS, for the rebuild command, you can use just or the command:

```sh
home-manager switch --flake .#jh-devv@aisu
```

Remember to replace my `hostname` and `user` with yours!

---

### Licenses

- The project's README has been inspired by the format and structure used by
  [The Catppuccin Theme Project](https://github.com/catppuccin) and the original
  can be found at
  [https://raw.githubusercontent.com/catppuccin/catppuccin/main/README.md](catppuccin/README.md).
  Additionally, the project is licensed under the MIT License, available
  [here](https://raw.githubusercontent.com/catppuccin/catppuccin/main/LICENSE).

#### ➔ Attributions

- A heartfelt ❤️ thank you to [fufexan](https://github.com/fufexan) for
  restructuring the code of this project!
- I also extend my heartfelt thanks to the Nix community for their tireless
  efforts and their from on their awesome Flakes. You can find some of them on
  [their GitHub community organization page](https://github.com/nix-community)!

[AGPL-3 License](LICENSE) © [jh-devv](https://jh-devv.com)
