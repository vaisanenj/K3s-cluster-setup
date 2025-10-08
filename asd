      steps:
        - matchExpressions:
            - key: envLabel
              operator: In
              values:
                - env-dev
          #maxUpdate: 100%  # if undefined, all applications matched are updated together (default is 100%)
        - matchExpressions:
            - key: envLabel
              operator: In
              values:
                - env-qa
          maxUpdate: 0      # if 0, no matched applications will be updated
        - matchExpressions:
            - key: envLabel
              operator: In
              values:
                - env-prod
          maxUpdate: 10%


        - path: kubernetes/system/metallb-system
        - path: kubernetes/system/intel-device-manager
        - path: kubernetes/system/external-secrets

        - path: kubernetes/system/traefik
        - path: kubernetes/system/cert-manager
        - path: kubernetes/system/argo-cd

        - path: kubernetes/system/longhorn-system

        - path: kubernetes/system/kube-prometheus-stack

        - path: gitea?