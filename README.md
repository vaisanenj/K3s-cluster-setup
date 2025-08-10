# Home K3s Cluster bootstrap

Repo pitää sisällään tarvittavat konfiguraatiot käynnistämään kubernetes klusteri pystyyn.

# Preconditions
- Hascicorp Vault
- Longhorn backups

# Set kubernetes cluster up
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --disable=traefik --disable=servicelb --write-kubeconfig-mode=644

    - Asenna k3s kuberentes koneille server/worker
    - Aseta käsin vault token
    - Käynnistä argocd
    - [valinnainen] Hae longhornista varmuuskopiot
    - Käynnistä argocd apps-of-apps