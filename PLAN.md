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

## Print ArgoCD initial admin password from `install.yaml`

README step 10 requires manually running `scripts/get-argo-token.sh` after bootstrapping, which reads `argocd-initial-admin-secret` via `kubectl` using the same local kubeconfig that `install.yaml`'s "Bootstrap cluster" play already writes to `../k3s_config`. The password half of that script can run automatically as the last step of `make cluster`.

**Change:**
- Add a fourth play to `install.yaml`, after "Bootstrap cluster": `hosts: localhost`, `connection: local`, `gather_facts: false`.
- Task 1 — wait for the secret to exist (ArgoCD's manifest is applied asynchronously by k3s and its pods still need time to start after that):
  ```yaml
  - name: Wait for ArgoCD initial admin secret
    register: argocd_admin_secret
    changed_when: false
    until: argocd_admin_secret.rc == 0
    retries: 30
    delay: 10
    ansible.builtin.command: >-
      kubectl --kubeconfig=../k3s_config -n argocd
      get secret argocd-initial-admin-secret
      -o jsonpath={.data.password}
  ```
- Task 2 — decode and print it:
  ```yaml
  - name: Print ArgoCD initial admin password
    ansible.builtin.debug:
      msg: "ArgoCD initial admin password: {{ argocd_admin_secret.stdout | b64decode }}"
  ```

**Why `command` + `b64decode`, not the `kubernetes.core` collection:** `kubectl` is already an assumed prerequisite (the README has the user run it directly), whereas `kubernetes.core.k8s_info` would add a new collection plus the Python `kubernetes` client to `requirements.yml`/the control node for one read-only lookup. Decoding with the Jinja `b64decode` filter (instead of piping to `base64 -d`) keeps the task on `ansible.builtin.command` rather than `ansible.builtin.shell`, avoiding a lint exception for shell pipes.

**Out of scope for this change:** the `kubectl port-forward service/argocd-server 8090:80` half of `scripts/get-argo-token.sh` stays a manual/separate step — it's a long-running foreground process meant to stay open while using the browser, which doesn't fit Ansible's run-to-completion task model. README step 10 would be updated to drop the password-fetch instruction but keep the port-forward one.

## `get-argo-token.sh`: wait for ArgoCD to be available

README step 10 tells the user to run `scripts/get-argo-token.sh` right after step 9 says ArgoCD "will be installed" — but that install is asynchronous (k3s's helm-controller still has to pull/render the `argo-cd` chart and roll out `argocd-server`). Run the script too early today and `kubectl get secret argocd-initial-admin-secret` fails outright under `set -euo pipefail`, or (once the password step moves to `install.yaml`, see above) the `port-forward` call succeeds but forwards to a service with no ready endpoint yet.

**Change:** in `scripts/get-argo-token.sh`, before the existing `kubectl get secret`/`port-forward` calls, add:
```sh
echo "Waiting for argocd-server to be available..."
kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n argocd rollout status deployment/argocd-server --timeout=300s
```
`argocd-server` as the deployment/service name is already relied on elsewhere in this file (the existing `port-forward service/argocd-server` line) and in `ansible/files/argocd.yaml`'s hand-written `IngressRoute`.

**Why keep this here even if the password step moves to `install.yaml`:** that change waits on the *secret*, which is a different readiness signal than the *service* this script still needs for `port-forward`. Both waits are cheap and worth keeping independently.

## `populate-secrets-manifests.sh`: wait for sealed-secrets-controller to be ready

README step 11 has the user manually watch `kubectl get pods` and only run `make secrets` once `sealed-secrets-controller` looks up. `make secrets` → `update-sealed-secrets.sh` → `populate-secrets-manifests.sh`'s first action is `kubeseal --fetch-cert`, which talks to that controller's HTTPS endpoint for its public key — run too early, it fails immediately.

**Change:** in `scripts/populate-secrets-manifests.sh`, before the `kubeseal --fetch-cert` line, add:
```sh
kubectl --kubeconfig="$REPO_ROOT/k3s_config" -n kube-system rollout status deployment/sealed-secrets-controller --timeout=300s
```
Deployment name: `manifests/infrastructure/apps/sealed-secrets.yaml`'s ArgoCD `Application` sets `helm.releaseName: sealed-secrets-controller`, targeting namespace `kube-system`. Since the release name contains the chart name (`sealed-secrets`), the Bitnami chart's `common.names.fullname` template collapses to the release name verbatim — so the deployment is named `sealed-secrets-controller`, not `sealed-secrets-controller-sealed-secrets`.

**Why `rollout status`, not a manual poll/sleep:** it's a single built-in `kubectl` subcommand that blocks until the Deployment's rollout finishes and exits non-zero on timeout — `set -euo pipefail` (already at the top of both scripts) then aborts with a clear error instead of proceeding against a cluster that isn't ready. No new tooling required.

**Follow-up:** once both of the above land, README steps 10 and 11 can drop their "wait until X is ready" framing — the scripts enforce it themselves. Step 11's wording would simplify to just "Run `make secrets` to seal and apply the remaining secrets."

## Out of scope (not planned)

- `meta/main.yml` Galaxy metadata for any role — these roles are never published/shared.
- Molecule/role testing, dynamic inventory, Ansible Vault — disproportionate for a fixed 4-node homelab; secrets already handled outside Ansible via `scripts/update-sealed-secrets.sh`.
- Rewriting `enable_nat.sh`/`enable_nat.service` or any other functional/behavioral change.
- Auto-generating the README network table from inventory data.
