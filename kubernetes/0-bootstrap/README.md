#Before running set vault-secret to correct for this installation

Install K3s Cluster with following command:
url -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --disable=traefik --disable=servicelb --write-kubeconfig-mode=644

kubectl apply -k /kubernetes/0-bootstrap
kubectl apply -f /kubernetes/0-bootstrap/argocd/applicationSet-apps.yaml
-- Setups is now done

# Install applications
Restore backups with setup-apps.sh script


Käynnistys homma:
    - 1. Argocd käyntiin ja taustajärjestelmät pystyyn (1-system sisältö)
    - 2. Odotellaan kaikkien valmistumista
    - 3. Palautellaan aiemmat backupt Longhornin kautta ja luodaan PV&PVC&NS kaikille
    - 4. Käynnistetään sovellukset apps ja gameserver alta
    - 5. Profit?