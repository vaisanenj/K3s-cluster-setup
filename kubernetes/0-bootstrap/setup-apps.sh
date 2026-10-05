#!/bin/bash

format_bytes() {
    local bytes="$1"

    local gi_boundary=1073741824        # 1 GiB
    local mi_boundary=1048576           # 1 MiB

    if [ "$bytes" -ge "$gi_boundary" ]; then
        local gi=$((bytes / gi_boundary))
        echo "${gi}Gi"
    else
        local mi=$((bytes / mi_boundary))
        # Fallback to 1Mi if it evaluates to 0 due to integer division
        if [ "$mi" -le 0 ]; then mi=1; fi
        echo "${mi}Mi"
    fi
}

get_latest_backup_name() {
    local vol_name="$1"
    local ns="longhorn-system"

    # Query backups in the longhorn-system namespace, filter, sort, and select the latest
    local latest_backup_json
    latest_backup_json=$(kubectl get backups.longhorn.io -n "$ns" -o json | \
      jq --arg vol "$vol_name" '.items[] | select(.status.volumeName == $vol)' | \
      jq -s 'sort_by(.status.createdAt) | last')

    # Verify if a valid JSON object was returned
    if [ -z "$latest_backup_json" ] || [ "$latest_backup_json" == "null" ]; then
        echo "ERROR: No backups found for volume '$vol_name' in namespace '$ns'." >&2
        return 1
    fi

    # Extract name, size, and url, then print them separated by tabs (\t)
    echo "$latest_backup_json" | jq -r '[.metadata.name, .status.volumeName, .status.volumeSize, .status.url] | @tsv'
}

create_volume_from_backup() {
    local backup_name="$1"
    local vol_name="$2"
    local vol_size="$3"
    local backup_url="$4"

    echo "$vol_size"

    local ns="longhorn-system"
    local replicas=1

    echo "Deploying volume '$vol_name' using backup details..." >&2
    kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  name: "$vol_name"
  namespace: "$ns"
spec:
  size: "$vol_size"
  numberOfReplicas: $replicas
  fromBackup: "$backup_url"
  frontend: blockdev
  dataEngine: v1
EOF
}

wait_for_volume_restore() {
    local vol_name="$1"
    local ns="longhorn-system"
    local check_interval=5

    echo "Monitoring volume restoration for '$vol_name'..." >&2

    while true; do
        # Fetch status fields using custom jsonpath lookups
        local restore_required
        local state
        restore_required=$(kubectl get volume "$vol_name" -n "$ns" -o jsonpath='{.status.restoreRequired}' 2>/dev/null || echo "unknown")
        state=$(kubectl get volume "$vol_name" -n "$ns" -o jsonpath='{.status.state}' 2>/dev/null || echo "unknown")

        # Longhorn flags restore complete when restoreRequired is false and state settles to 'detached'
        if [ "$restore_required" == "false" ] && [ "$state" == "detached" ]; then
            echo "Success! Volume '$vol_name' is fully restored and ready." >&2
            break
        elif [ "$state" == "faulty" ]; then
            echo "Error: Volume '$vol_name' reached a 'faulty' state during restore." >&2
            return 1
        elif [ "$state" == "unknown" ]; then
            echo "   • Volume not found yet, waiting..." >&2
        else
            echo "   • Current State: $state | Restoration in progress..." >&2
        fi

        sleep "$check_interval"
    done
}

create_new_pv() {
    local vol_name="$2"
    local volume_size=$(format_bytes "$3")

    echo "Creating PersistentVolume: $vol_name" >&2
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${vol_name}
spec:
  capacity:
    storage: "${volume_size}"
  volumeMode: Filesystem
  storageClass: longhorn-strict-local-1-replica
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: driver.longhorn.io
    volumeHandle: ${vol_name}
EOF
}

create_new_ns() {
    echo "Creating namespace: '$1'" >&2
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $1
EOF
}

create_new_pvc() {
    local pv_name="$1"
    local pv_size=$(format_bytes "$4")
    local pvc_name="$6"
    local ns="$7"

    echo "Creating PersistentVolumeClaim: $pvc_name in namespace '$ns'" >&2

    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pvc_name}
  namespace: ${ns}
spec:
  accessModes: [ReadWriteOnce]
  storageClass: longhorn-strict-local-1-replica
  volumeName: ${pv_name}
  resources:
    requests:
      storage: '${pv_size}'
EOF

    echo "Storage linking complete! Workloads can now mount PVC: '$pvc_name'" >&2
}

restore_longhorn_backup() {
    local ns="$1"
    local pv="$2"
    local pvc="$3"

    echo "Start restoring backup ns: $1, pvc: $3, pv: $2"
    values=$(get_latest_backup_name "$pv")

    create_volume_from_backup $values
    wait_for_volume_restore "$pv"
    create_new_pv $values
    create_new_ns $ns
    create_new_pvc $pv $values $pvc $ns
}

echo "Start K3s installation"
sudo apt-get update -y && sudo apt-get upgrade -y
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --disable=traefik --disable=servicelb --write-kubeconfig-mode=644

echo "Install 'system' applications next"
kubectl apply -k .
sleep 5
echo "Wait until argocd is installed and running"
kubectl -n argocd rollout status deployment/argocd-server --timeout=5m

echo "Install 'system' applications next and wait installations"
kubectl apply -f argocd/applicationSet-system.yaml
Sleep 5s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application --all --timeout=5m

echo "sleep 90s to wait longhorn poll backups"
sleep 90s

#restore_longhorn_backup "automation" "pvc-58643349-ad55-44f4-92e9-7ee0f30956e1" "data-homeassistant-0"
#restore_longhorn_backup "automation" "pvc-99a75591-395c-4009-a387-fca3f3e68647" "data-zigbee2mqtt-0"
#restore_longhorn_backup "immich" "immich-library" "immich-library-pvc"
#restore_longhorn_backup "jellyfin" "pvc-c676729b-ce99-4e8e-affc-d2a248999678" "config-jellyfin-0"
#restore_longhorn_backup "lyrion-media-server" "pvc-4cd62879-b835-4a84-ac6e-8ebf1b07021f" "data-lyrion-media-server-0"
restore_longhorn_backup "wireguard" "pvc-df8df800-3ec1-40e3-b556-d9e8ce05e5a5" "data-wireguard-0"

echo "Install apps & gameservers next.."
kubectl apply -f argocd/applicationSet-apps.yaml