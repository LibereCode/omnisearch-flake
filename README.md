# omnisearch.nix

~A fork off~ _A nix-wrapper_ off [omnisearch](https://git.bwaaa.monster/omnisearch/about/)
**THAT ABSOLUTELY DO NOT BREAK THE LICENSE**, (i have made no changes to the source).

I have also a better nix implementation either way... :P

> [!WARN]
> `services.omnisearch` does NOT work yet, so just use the package for now...

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

## LICENSE

This [(un)LICENSE](./UNLICENSE) only extends toward this repo.
For the original repo, see [their LICENSE](omnisearch.LICENSE)
