# omnisearch.nix

~A fork off~ _A nix-wrapper_ off [omnisearch](https://git.bwaaa.monster/omnisearch/about/)
**THAT ABSOLUTELY DO NOT BREAK THE LICENSE**, (i have made no changes to the source).

I have also a better nix implementation either way... :P

## USAGE

```nix flake.nix
{
  inputs = {
    # ... other inputs

    omnisearch-flake = {
      url = "github:LibereCode/omnisearch-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ... other inputs
  };

  outputs = inputs @ { args, ... }:
    {
    # ... other output-stuff

      nixosConfigurations.hostname = inputs.nixpkgs.lib.nixosSystem {
        # ... config

        modules = [
          ## allow you to use the package and
          ## the nixos-options `services.omnisearch.<options>`
          inputs.omnisearch-flake.nixosModules.default

          {
            services.omnisearch = {
              enable = true; # enables the service-module (else ignores all other)

              # systemd.enable = true; #default

              settings = {
                # omnisearch settings for **config.ini** here
              };
            };
          }
        ];

        # ... config
      };

    # ... other output-stuff
    };
}
```

## LICENSE

This [(un)LICENSE](./UNLICENSE) only extends toward this repo.
For the original repo, see [their LICENSE](omnisearch.LICENSE)
