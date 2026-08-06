---
draft: false
title: Using Nix to Keep Declarative Intent Separate from Implementation Code
slug: using-nix-to-keep-declarative-intent-separate-from-implementation
created: 2026-07-31
updated: 2026-07-31
tags: Nix, karrio
summary: 
---

The intent of this blog post is not to explain [Nix](https://nixos.org),
[NixOS](https://nixos.org) or
[Nixpkgs](https://nixos.org/manual/nixpkgs/stable/), but rather to show how
`nix` allows for keeping code implementation separate from actual intent of
deployment.

At work, we were looking at open-source shipping tracker aggregates, primarily
for ordering labels from local post services.

We found [karrio](https://github.com/karrioapi/karrio) which has excellent
support for custom integration. Specifically, it has AI-coding instructions for
incremental creation of custom connections, and any pull requests for new
features promises at least 2 employees for human verification before any merge.
This allows for quick return on investment for any time spent "vibe-coding".

For live deployment on server hardware, I used
[NixOS](https://nixos.org/)—which is also my daily driver. The `nix` module for
karrio can now be found at [karrio-nix](https://github.com/Joaqim/karrio-nix),
specifically
[karrio.nix](https://github.com/Joaqim/karrio-nix/blob/main/modules/karrio.nix).

Full disclosure: the `karrio-nix` whas wholly written by an LLM; I've done many
`nix` modules before and packaging `karrio`, with all it's dispirate `python`
and `NodeJS` packages would have been a lot of work, when the alternative would
be to just host a docker instance which could be packaged just as well—mostly
anyways.

For anyone familiar with nix, the outcome is a very standard service:

```nix
services.karrio = {
  enable = true;
  enableMaildev = true;

  publicApiUrl = apiPublicUrl; # api.your-domain.com
  publicDashboardUrl = dashboardPublicUrl; # app.your-domain.com

  enableAllPlugins = false;
  extraSettings = {
    # Available settings can be found at: 
    # https://www.karrio.io/docs/self-hosting/environment
    USE_HTTPS = "True";
    ALLOW_SIGNUP = "False";
    ALLOW_ADMIN_APPROVED_SIGNUP = "True";
  };

  dashboardEnvironmentFiles = [
    # Secrets file that contains, with whatever secrets
    # provider you prefer:
    # SECRET_KEY="$(openssl rand -hex 32)"
    # NEXTAUTH_SECRET="$(openssl rand -hex 32)"
    # ADMIN_PASSWORD="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)"
    karrioSecretsEnvPath
  ];
};
```

The intent remains clear, and the `nix` module contains the documentation for
how to configure it, which might be completely conformant to `karrio`
documentation; a minimal functional deployment. Or optionally augmented with
extended functionality; like seeding the initial database via a separate
systemd service, achieving true declarative deployment.

For my purposes, I have a separate `caddy` configuration for http proxy to the
exposed ports for api and dashboard, and my custom`karrio-nix` module could be
extended with a lot of further options, not least custom ports for dashboard
and API.
