{{/* ============================================================================
   Basic Chart/Name Helpers
   ============================================================================ */}}

{{- define "universal-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "universal-controller.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "universal-controller.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* ============================================================================
   Label-Safe Helpers
   ============================================================================ */}}

{{/* Create a DNS/label-safe version of the chart name (lowercase, no spaces, etc.) */}}
{{- define "universal-controller.nameLabel" -}}
{{- $raw := include "universal-controller.name" . -}}
{{- $s := $raw | lower | replace " " "-" -}}
{{- $s = $s | regexReplaceAll "[^a-z0-9._-]" "" -}}
{{- $s = $s | trimPrefix "-" | trimSuffix "-" | trimPrefix "_" | trimSuffix "_" | trimPrefix "." | trimSuffix "." -}}
{{- $s -}}
{{- end -}}

{{/* Standard labels used across resources */}}
{{- define "universal-controller.labels" -}}
app.kubernetes.io/name: {{ include "universal-controller.nameLabel" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | replace " " "-" | regexReplaceAll "[^A-Za-z0-9._-]" "" }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels (used for Deployment selectors and Service selectors) */}}
{{- define "universal-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "universal-controller.nameLabel" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Service Account name helper */}}
{{- define "universal-controller.serviceAccountName" -}}
{{- default "default" .Values.serviceAccount.name }}
{{- end -}}

{{/* ============================================================================
   Utility Helpers
   ============================================================================ */}}

{{/* DNS-1123 safe name for volumes, configmaps, etc. */}}
{{- define "uc.safeName" -}}
{{- $s := regexReplaceAll "[^a-z0-9-]" (lower .) "-" -}}
{{- $s | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Emit a ConfigMap line only if the value is non-empty.
Handles booleans, numbers, and strings.
*/}}
{{- define "uc.emitIfSet" -}}
{{- $key := index . 0 -}}
{{- $val := index . 1 -}}
{{- if and (ne $val nil) (ne (printf "%v" $val) "") }}
{{ $key }}: {{ $val | quote }}
{{- end -}}
{{- end -}}

{{/* Emit a single key:value line if the value is set (non-empty/non-nil). Always quoted. */}}
{{- define "uac.emitIfSet" -}}
{{- $v := .value -}}
{{- if not (kindIs "invalid" $v) -}}
  {{- if kindIs "string" $v -}}
    {{- if ne $v "" -}}
{{ .name }}: {{ $v | quote }}
    {{- end -}}
  {{- else if kindIs "bool" $v -}}
{{ .name }}: {{ ternary "true" "false" $v | quote }}
  {{- else -}}
    {{- if not (empty $v) -}}
{{ .name }}: {{ printf "%v" $v | quote }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
