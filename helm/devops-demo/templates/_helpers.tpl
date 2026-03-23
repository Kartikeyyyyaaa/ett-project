{{- define "devops-demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "devops-demo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "devops-demo.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "devops-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end }}

{{- define "devops-demo.labels" -}}
helm.sh/chart: {{ include "devops-demo.chart" . }}
{{ include "devops-demo.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "devops-demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devops-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "devops-demo.postgresql.fullname" -}}
{{ include "devops-demo.fullname" . }}-postgresql
{{- end }}

{{- define "devops-demo.backend.fullname" -}}
{{ include "devops-demo.fullname" . }}-backend
{{- end }}

{{- define "devops-demo.frontend.fullname" -}}
{{ include "devops-demo.fullname" . }}-frontend
{{- end }}

{{- define "devops-demo.dbPassword" -}}
{{- if .Values.secrets.dbPassword }}
{{- .Values.secrets.dbPassword }}
{{- else }}
{{- .Values.secrets.postgresPassword }}
{{- end }}
{{- end }}
