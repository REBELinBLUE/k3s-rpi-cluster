# Ansible cleanup — remaining items

Part of a broader consistency pass over `ansible/`. Some items were already applied (see git history: FQCN fixes in `roles/master/tasks/main.yaml`, role-list syntax normalization in `master.yaml`/`workers.yaml`, pinned `starship` install, `requirements.yml` + `.ansible-lint-ignore` removal, `ansible.cfg`). The items below were reviewed and deliberately deferred — not rejected as bad ideas, just not applied yet.

## `shutdown.yaml` play parity

The workers play has both `serial: 1` and `ignore_unreachable: true`; the controlplane play (same file, same task shape) has neither. `serial: 1` is moot on controlplane (only one host), but `ignore_unreachable` isn't — right now an unreachable master aborts the whole `make shutdown` run instead of just skipping it.

**Change:** add `ignore_unreachable: true` to the controlplane play only.

## Consolidate reboot logic via `include_role`

"reboot + wait_for_connection" is duplicated 4x: the standalone `reboot` role, inline in `cgroups`, inline in `config`, and inline in `uninstall.yaml`. A future change (e.g. reboot timeout) has to be applied four times and will drift.

**Change:**
- `roles/cgroups/tasks/main.yaml` and `roles/config/tasks/main.yaml`: replace the inline reboot+wait tasks with `ansible.builtin.include_role: {name: reboot}` (keep the existing `when:`/`become:` guards on the include).
- `uninstall.yaml`: replace the two inline reboot task-lists with `roles: [reboot]`, matching `reboot.yaml`/`update.yaml`. This also adds the `wait_for_connection` step `uninstall.yaml` currently lacks.

**Why not handlers:** `master.yaml`/`workers.yaml` run all their roles in a single play, and handlers only flush at end-of-play by default — a notified reboot from `config`/`cgroups` would be deferred until every later role (`packages`, `master`, `hosts`, `shell`, `topgrade`, `starship`) had already run against a stale, un-rebooted kernel/cmdline. `include_role` preserves today's correct "reboot immediately, then continue" ordering and introduces no new pattern (handlers aren't used anywhere else in this repo).

## CI for `ansible-lint`

`ansible-lint` is configured (`.ansible-lint` sets the strict `production` profile) but only runs manually via `make lint` — nothing stops a failing commit from landing. Net-new infra (repo has zero CI today).

**Change:** add `.github/workflows/ansible-lint.yml` — on push/PR touching `ansible/**`: checkout, set up Python, `pip install ansible-lint`, `ansible-galaxy collection install -r ansible/requirements.yml`, run `ansible-lint` from `ansible/`.

## Out of scope (not planned)

- `meta/main.yml` Galaxy metadata for any role — these roles are never published/shared.
- Molecule/role testing, dynamic inventory, Ansible Vault — disproportionate for a fixed 4-node homelab; secrets already handled outside Ansible via `scripts/update-sealed-secrets.sh`.
- Rewriting `enable_nat.sh`/`enable_nat.service` or any other functional/behavioral change.
- Auto-generating the README network table from inventory data.
