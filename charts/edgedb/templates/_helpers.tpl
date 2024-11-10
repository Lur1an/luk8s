{{/*
Expand the name of the chart.
*/}}
{{- define "edgedb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "edgedb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "edgedb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "edgedb.labels" -}}
helm.sh/chart: {{ include "edgedb.chart" . }}
{{ include "edgedb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "edgedb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "edgedb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Generate or lookup password
*/}}
{{- define "edgedb.password" -}}
{{ if .Release.IsUpgrade }}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (printf "%s-server-password" (include "edgedb.fullname" .)) }}
{{- index $secret.data "password" | b64dec }}
{{- else }}
{{- randAlphaNum 20 }}
{{- end }}
{{- end }}

{{- define "edgedb.tlsSecretName"}}
{{- if .Values.security.tls.enabled }}
  {{- if .Values.security.tls.secret }}
  {{- .Values.security.tls.secret }}
  {{- else if .Values.security.tls.cert }}
  {{- include "edgedb.fullname" . }}-tls
  {{- else }}
  {{- fail "You must provide either a secret or cert for TLS configuration" }}
  {{- end }}
{{- end }}
{{- end }}
