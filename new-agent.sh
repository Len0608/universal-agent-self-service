#!/bin/bash
set -e

AGENT="${1:?Usage: new-agent.sh <agent-name> [oms-server]}"
OMS="${2:-7878@ps2.stonebranchdev.cloud}"
NETNAME=$(echo "$AGENT" | tr '[:lower:]-' '[:upper:]_')
REPO="$(dirname "$(realpath "$0")")"

echo "Creating agent: $NETNAME -> $OMS"

cd "$REPO"
git checkout main && git pull
git checkout -b "add-agent/$AGENT"

mkdir -p "agents/aks/$AGENT"

cat > "agents/aks/$AGENT/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: sb-$AGENT
EOF

cat > "agents/aks/$AGENT/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - helmrelease.yaml
EOF

cat > "agents/aks/$AGENT/helmrelease.yaml" <<EOF
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: $AGENT
  namespace: sb-$AGENT
spec:
  interval: 10m
  chart:
    spec:
      chart: helm-repo/helm/helm_ua_v1.5.1-aks
      sourceRef:
        kind: GitRepository
        name: helm-charts
        namespace: flux-system
      interval: 1m
  install:
    createNamespace: true
    remediation:
      retries: 3
  values:
    uaDeployment:
      image:
        repository: stonebranch/universal-agent
        tag: "7.9.0.0"
      replicas: 1
      resources:
        requests:
          memory: "512Mi"
          cpu: "250m"
        limits:
          memory: "1Gi"
          cpu: "1000m"
      storageRequest: 1Gi
      storageClassName: "default"
      accessMode: ReadWriteOnce
      pvc:
        enabled: true
    uaConfig:
      netname: "$NETNAME"
      omsServers: "$OMS"
      uagAutostart: "yes"
      omsAutostart: "no"
      uemAutostart: "no"
    workloadIdentity:
      enabled: false
    istio:
      enabled: true
      host: "$AGENT.stonebranchdev.cloud"
      TLSProtocol: "TLSV1_2"
      udmConnectionPort: 446
      udmConnectionPortInternal: 15446
EOF

sed -i "s/# Self-service:/  - $AGENT\n# Self-service:/" "agents/aks/kustomization.yaml"

git add -A
git commit -m "feat: add $NETNAME agent via self-service PR"
git push -u origin "add-agent/$AGENT"

echo ""
echo "PR öffnen: https://github.com/Len0608/universal-agent-self-service/compare/add-agent/$AGENT"
