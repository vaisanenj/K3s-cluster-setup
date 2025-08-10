# Home K3s Cluster bootstrap

Repo pitää sisällään tarvittavat konfiguraatiot käynnistämään kubernetes klusteri pystyyn.

# Preconditions
- Hascicorp Vault
- Longhorn backups

# Set kubernetes cluster up
1. Asenna K3s cluster ensimmäiselle koneelle
Komento: curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --disable=traefik --disable=servicelb --write-kubeconfig-mode=644
2. Asenna loput server ja worker nodes
TODO: täydennä komennot
3. Lisää Hashicorp valut token salaisuus
Komento: kubectl apply -f /path/to/secret.yaml
4. Asenna Argo 
Komento: 
cd K3s-cluster-setup/kubernetes/argo
kubectl apply -k .
5. Vahvita ohjelmistojen asennus argo UI kautta
HOX kaikki käynnistetään yhtä aikaa, jonka vuoksi ohjelmistot eivät päivity heti oikein. (riippuvuuksia toisiinsa)
6. Valinnainen palauta varmuuskopiot
- Palauta varmuuskopoit longhorn UI kautta
- Luo tyhjät namespacet valmiiksi PVC varten
- Longhorn UI luo PVC aikaisempien nimien pohjalta
7. Asenna gitea ja openldap myös
8. Hae paikallisesta gitea reposta manifestit peliservuille, yms.