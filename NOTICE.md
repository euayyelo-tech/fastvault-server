# NOTICE

FastVault Server is a modified version of Vaultwarden
(https://github.com/dani-garcia/vaultwarden), licensed under the GNU Affero
General Public License v3.0 — see LICENSE.txt, which is unchanged.

Modifications by FSITES LTD (https://fastvault.app), starting 2026-09-16:

- `src/config.rs`, `src/api/core/organizations.rs`: an `ORG_MAX_SEATS`
  setting that refuses invitations once an organisation has that many
  members (upstream has no cap).
- `src/static/templates/email/*.hbs`: FastVault wording and logo.
- `scripts/build-web-vault.sh`: applies FastVault branding to the
  prebuilt web vault from dani-garcia/bw_web_builds before it is copied
  into the image.
- `docker/`: image build copies that branded web vault.

The complete corresponding source of the version running at
https://vault.fastvault.app is this repository, at the tag named in that
server's `/source` page. Vaultwarden and Bitwarden are not affiliated with
FastVault; "Bitwarden" is a trademark of Bitwarden, Inc.
