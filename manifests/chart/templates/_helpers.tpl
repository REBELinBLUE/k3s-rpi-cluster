{{/*
Resolve the cert-manager cluster issuer for an app, honouring per-app overrides.
Usage: {{ include "cluster-apps.certManagerIssuer" (dict "appName" "longhorn" "root" $) }}
*/}}
{{- define "cluster-apps.certManagerIssuer" -}}
{{- $override := index .root.Values.overrides .appName | default dict -}}
{{- $override.certManagerIssuer | default .root.Values.global.certManagerIssuer -}}
{{- end -}}
