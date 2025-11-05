# Dockerfile pour Asterisk

Ce Dockerfile permet de compiler et exécuter Asterisk à partir du code source.

## Construction

```bash
docker build -t asterisk-source .
```

## Exécution

```bash
docker run -d \
  --name asterisk \
  -p 5060:5060/udp \
  -p 5060:5060/tcp \
  -p 5061:5061/udp \
  -p 5061:5061/tcp \
  -p 10000-20000:10000-20000/udp \
  -v /path/to/config:/etc/asterisk \
  asterisk-source
```

## Fonctionnalités

- Multi-stage build pour optimiser la taille
- Compilation avec les modules les plus courants
- Utilisateur non-root pour la sécurité
- Health check intégré
- Ports SIP/RTP exposés
- Configuration personnalisable via volumes

## Personnalisation

Pour ajouter des modules supplémentaires, modifiez la section `./configure` dans le Dockerfile.