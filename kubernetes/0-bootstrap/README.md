#Before running set vault-secret to correct for this installation

Installation is grouped to different phases:
  - Phase 1: Uninstall K3s if exists and reinstall new it
        - disable traefik (It will be installed with helm)
        - disable servicelb (Metalb is used instead)
  - Phase 2: Install 'system' applications that are needed for cluster

Käynnistys homma:
    - 1. Argocd käyntiin ja taustajärjestelmät pystyyn (1-system sisältö)
    - 2. Odotellaan kaikkien valmistumista
    - 3. Palautellaan aiemmat backupt Longhornin kautta ja luodaan PV&PVC&NS kaikille
    - 4. Käynnistetään sovellukset apps ja gameserver alta
    - 5. Profit?