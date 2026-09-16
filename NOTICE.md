# NOTICE

FastVault Server is a modified version of Vaultwarden
(https://github.com/dani-garcia/vaultwarden), licensed under the GNU Affero
General Public License v3.0 — see LICENSE.txt, which is unchanged.

Modifications by FSITES LTD (https://fastvault.app), starting 2026-09-16:

- `src/config.rs`, `src/api/core/organizations.rs`, `src/api/core/public.rs`:
  an `ORG_MAX_SEATS` setting that refuses invitations (and bulk organisation
  imports) once an organisation has that many members (upstream has no cap).
- `src/static/templates/email/*.hbs`: FastVault wording and logo.
- `src/static/images/logo-gray.png`: FastVault mark.
- `src/static/templates/404.hbs`: FastVault wording and support link.
- `README.md`: FastVault-specific build/update instructions.
- `.github/workflows/`: image publish workflow and a weekly upstream
  release watch, in addition to upstream's own workflows.
- `scripts/build-web-vault.sh`: applies FastVault branding to the
  prebuilt web vault from dani-garcia/bw_web_builds before it is copied
  into the image, including rewriting the login page's inline wordmark
  SVG (which the upstream logo files don't cover).
- `docker/`: image build copies that branded web vault.

The complete corresponding source of the version running at
https://vault.fastvault.app is this repository, at the tag named in that
server's `/source.html` page. Vaultwarden and Bitwarden are not affiliated
with FastVault; "Bitwarden" is a trademark of Bitwarden, Inc.
