#!/usr/bin/env -S just --justfile
# An stupidly complex just script for nice rebuilding of the host!

origin := '.'
user   := `whoami`
host   := `hostname`

action := 'nixos'

[private]
default:
  @just --list

rebuild action="nixos":
  @just rebuild-{{action}} {{host}} {{user}} {{origin}}

[private]
rebuild-nixos host user origin:
  @sudo nixos-rebuild switch --flake {{origin}}#{{host}}

[private]
rebuild-home-manager host user origin:
  @sudo -u {{user}} home-manager switch --flake {{origin}}#{{user}}@{{host}}

clean:
  @sudo nix-collect-garbage -d
  @sudo -u {{user}} nix-collect-garbage -d

update input="":
  @nix flake update {{input}}