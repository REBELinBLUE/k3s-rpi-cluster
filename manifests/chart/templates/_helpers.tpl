{{/*
Resolve the cert-manager cluster issuer for an app, honouring per-app overrides.
Usage: {{ include "cluster-apps.certManagerIssuer" (dict "appName" "longhorn" "root" $) }}
*/}}
{{- define "cluster-apps.certManagerIssuer" -}}
{{- $override := index .root.Values.overrides .appName | default dict -}}
{{- $override.certManagerIssuer | default .root.Values.global.certManagerIssuer -}}
{{- end -}}

{{/*
Whether an app is enabled, defaulting to true if unset.
Usage: {{ include "cluster-apps.enabled" (dict "appName" "traefik" "root" $) }}
*/}}
{{- define "cluster-apps.enabled" -}}
{{- $app := index .root.Values.apps .appName | default dict -}}
{{- $enabled := $app.enabled -}}
{{- if kindIs "invalid" $enabled -}}
{{- $enabled = true -}}
{{- end -}}
{{- $enabled -}}
{{- end -}}
