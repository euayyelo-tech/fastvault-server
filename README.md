# FastVault Server

The server behind https://fastvault.app — Vaultwarden 1.37.3 with FastVault
branding and an organisation seat cap. AGPL-3.0; see NOTICE.md for what was
changed and LICENSE.txt for the licence. Upstream documentation applies:
https://github.com/dani-garcia/vaultwarden/wiki

## Build

    scripts/build-web-vault.sh            # downloads + brands the web vault into web-vault/
    docker build -f docker/Dockerfile.debian -t fastvault-server:dev .

## Configuration additions

    ORG_MAX_SEATS=6   # 0 = unlimited (upstream behaviour)

Everything else is upstream's `.env.template`.

## Updating from upstream

    git fetch upstream && git merge <new-tag>
    # then update the `base` tag in .github/workflows/upstream-watch.yml
    # and, if a new web vault build is required, WEB_VAULT_VERSION in
    # scripts/build-web-vault.sh
