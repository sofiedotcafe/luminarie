#!/usr/bin/env -S just --justfile

# ── Defaults ───────────────────────────────

origin := '.'
user   := `whoami`
host   := `hostname`
args   := ''

# ── Default ────────────────────────────────

[private]
default:
  @just --list

# ── Entrypoint ─────────────────────────────

# → Deploy system or user config, 
deploy action host=host user=user origin=origin args=args:
  @just deploy-{{action}} {{host}} {{user}} {{origin}} "{{args}}"

# ── Subcommands ────────────────────────────

[private]
deploy-nixos host user origin args:
  @sudo nixos-rebuild switch --flake {{origin}}#{{host}} {{args}}

[private]
deploy-home-manager host user origin args:
  @sudo -u {{user}} home-manager switch --flake {{origin}}#{{user}}@{{host}} {{args}}

# ── Utilities ──────────────────────────────

# → Run nix flake update
update input="":
  @nix flake update {{input}}

# → Collect system/user garbage
clean user=user:
  @sudo nix-collect-garbage -d
  @sudo -u {{user}} nix-collect-garbage -d
  @nix store verify --all || true
