# omnisearch.nix

> [!WARNING]
> The **package** works (on my machine at least), but
> ~**THE SERVICE DEFINENTLY DO NOT WORK!**
> Also, my package is kind of shit (as in bloated) at the moment...~

> [!NOTE]
> THE SERVICE NOW WORKS !!
> Well... kind of... you cant use the configure option of the service... BUT
> the systemd service now works, and it creates `omnisearch` user/group and
> they run the service.

## ABOUT

> [!NOTE]
> USE `pkgs.thunar` as a reference.
> [See the sauce here](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/th/thunar-unwrapped/package.nix#L105)

## USAGE

```nix flake.nix
# flake.nix
{
  inputs = {
    # ... other inputs

    omnisearch-flake = {
      url = "github:liberecode/omnisearch-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ... other inputs
  };

  outputs = {
    # ... other output-stuff
  };
}
```

```nix modules/nixos/omnisearch.nix
# modules/nixos/omnisearch.nix
## need to be imported!
{ inputs, ... }: {

  ## This exposes pkgs and options
  imports = [ inputs.omnisearch-flake.nixosModules.default ];

  config = {
    services.omnisearch = {
      enable = true;

      ## enables systemd-service (default: true)
      #systemd.enable = false;

      ## Will be applied to omnisearch's config.ini
      settings = {
        # ... settings here ...
      };
    };
  };
}
```

## ALTERNATIVES

I just discovered there also exist [another omnisearch nix-flake](https://github.com/JetHair/OmniSearch).
It is a bit older, but is maybe better; I dunno 🤷.

## LICENSE

This [EUPL](./LICENSE) only extends toward this repo.
For the original repo, see [their LICENSE](omnisearch.LICENSE)
