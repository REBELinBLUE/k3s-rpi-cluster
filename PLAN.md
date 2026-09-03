# Ansible cleanup — remaining items

Part of a broader consistency pass over `ansible/`. Some items were already applied (see git history: FQCN fixes in `roles/master/tasks/main.yaml`, role-list syntax normalization in `master.yaml`/`workers.yaml`, pinned `starship` install, `requirements.yml` + `.ansible-lint-ignore` removal, `ansible.cfg`). The items below were reviewed and deliberately deferred — not rejected as bad ideas, just not applied yet.

## `packages` role: `vars/` → `defaults/`

`roles/packages/vars/main.yaml` sets `packages_additional: []`, which callers override per-role-invocation (`master.yaml`/`workers.yaml` already do this via `vars:` on the role entry). Ansible's convention for an override-me value is `defaults/main.yaml` — `vars/` is higher precedence and meant for values a role sets for itself. Every other role with an overridable setting (`config`, `hosts`, `topgrade`) already uses `defaults/`; `packages` is the only one using `vars/`.

**Change:** delete `roles/packages/vars/main.yaml`, create `roles/packages/defaults/main.yaml` with the same content.

## `shutdown.yaml` play parity

The workers play has both `serial: 1` and `ignore_unreachable: true`; the controlplane play (same file, same task shape) has neither. `serial: 1` is moot on controlplane (only one host), but `ignore_unreachable` isn't — right now an unreachable master aborts the whole `make shutdown` run instead of just skipping it.

**Change:** add `ignore_unreachable: true` to the controlplane play only.

## Consolidate reboot logic via `include_role`

"reboot + wait_for_connection" is duplicated 4x: the standalone `reboot` role, inline in `cgroups`, inline in `config`, and inline in `uninstall.yaml`. A future change (e.g. reboot timeout) has to be applied four times and will drift.

**Change:**
- `roles/cgroups/tasks/main.yaml` and `roles/config/tasks/main.yaml`: replace the inline reboot+wait tasks with `ansible.builtin.include_role: {name: reboot}` (keep the existing `when:`/`become:` guards on the include).
- `uninstall.yaml`: replace the two inline reboot task-lists with `roles: [reboot]`, matching `reboot.yaml`/`update.yaml`. This also adds the `wait_for_connection` step `uninstall.yaml` currently lacks.

**Why not handlers:** `master.yaml`/`workers.yaml` run all their roles in a single play, and handlers only flush at end-of-play by default — a notified reboot from `config`/`cgroups` would be deferred until every later role (`packages`, `master`, `hosts`, `shell`, `topgrade`, `starship`) had already run against a stale, un-rebooted kernel/cmdline. `include_role` preserves today's correct "reboot immediately, then continue" ordering and introduces no new pattern (handlers aren't used anywhere else in this repo).

## Template the RPi boot config

`roles/config/files/master-config.txt` and `workers-config.txt` are ~95% identical — the only difference is the `dtoverlay=pi3-disable-wifi` line, present only in the workers version. Any other change (e.g. PoE fan temps) has to be made in both files and can drift.

**Change:**
- Add `roles/config/templates/config.txt.j2` (content of `master-config.txt`, with the wifi-disable line wrapped in `{% if config_disable_wifi %}...{% endif %}`).
- Delete `roles/config/files/master-config.txt` and `workers-config.txt`.
- `roles/config/defaults/main.yaml`: `config_master: false` → `config_disable_wifi: false`.
- `roles/config/tasks/main.yaml`: drop the "select config file" `set_fact`; replace the `copy` task with a `template` task (fold in the `0755`→`0644` mode fix above while touching this file).
- `master.yaml`: drop `vars: {config_master: true}` from the `config` role entry (wifi stays enabled by default).
- `workers.yaml`: add `vars: {config_disable_wifi: true}` to the `config` role entry.

## Single source of truth for node topology

The same 4 IPs (and MACs) live in three places that can drift independently: `roles/hosts/defaults/main.yaml` (hostname+IP), `roles/master/defaults/main.yaml` (hostname+IP+MAC), and a hardcoded `K3S_URL: "https://10.0.0.1:6443"` string in `install.yaml`.

**Change (inventory host_vars, not `group_vars/`):**
- `inventory.yaml`: add `ansible_host` (all 4 hosts) and `mac_address` (workers) using the real current values from the two defaults files.
- Delete `roles/hosts/defaults/main.yaml`; rewrite `roles/hosts/tasks/main.yaml` to loop over `groups['all']` using `hostvars[item].ansible_host`.
- Delete `roles/master/defaults/main.yaml`; rewrite `roles/master/templates/dhcpd.conf.j2` to loop over `groups['workers']` using `hostvars[host].ansible_host`/`mac_address`.
- `install.yaml`: replace the hardcoded `K3S_URL` IP with `hostvars[groups['controlplane'][0]].ansible_host`.

**Why inventory host_vars, not a `group_vars/`/`host_vars/` tree:** per-node IP/MAC is exactly what inventory variables are for, and `inventory.yaml` is already the one file touched when adding/removing a node. A whole new directory convention is more ceremony than 4 static hosts warrant.

## Stop hardcoding `/home/{{ ansible_user }}`

`shell`, `starship`, and `topgrade` roles all write to `/home/{{ ansible_user }}/...` directly — an assumption baked into three files rather than derived from the actual system.

**Change:** prepend to each of `roles/shell/tasks/main.yaml`, `roles/starship/tasks/main.yaml`, `roles/topgrade/tasks/main.yaml`:
```yaml
- name: Determine home directory of ansible_user
  ansible.builtin.getent:
    database: passwd
    key: "{{ ansible_user }}"

- name: Set home directory fact
  ansible.builtin.set_fact:
    user_home: "{{ getent_passwd[ansible_user][4] }}"
```
then replace every `/home/{{ ansible_user }}/...` with `{{ user_home }}/...`. Small duplication across 3 roles is fine at this scale — not worth a 4th shared role for 3 call sites.

## CI for `ansible-lint`

`ansible-lint` is configured (`.ansible-lint` sets the strict `production` profile) but only runs manually via `make lint` — nothing stops a failing commit from landing. Net-new infra (repo has zero CI today).

**Change:** add `.github/workflows/ansible-lint.yml` — on push/PR touching `ansible/**`: checkout, set up Python, `pip install ansible-lint`, `ansible-galaxy collection install -r ansible/requirements.yml`, run `ansible-lint` from `ansible/`.

## Out of scope (not planned)

- `meta/main.yml` Galaxy metadata for any role — these roles are never published/shared.
- Molecule/role testing, dynamic inventory, Ansible Vault — disproportionate for a fixed 4-node homelab; secrets already handled outside Ansible via `scripts/update-sealed-secrets.sh`.
- Rewriting `enable_nat.sh`/`enable_nat.service` or any other functional/behavioral change.
- Auto-generating the README network table from inventory data.
