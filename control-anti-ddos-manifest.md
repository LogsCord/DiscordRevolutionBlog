# Manifeste de Fonctionnement - Bot Anti-DDoS Vocal

## 1. Objectif du bot

Ce bot protège automatiquement vos salons vocaux Discord contre les attaques DDoS vocales :
- Lags,
- Coupures,
- Déconnexions,
- Perturbations massives liées au serveur vocal Discord.

Son rôle est d'identifier les attaques le plus tôt possible, puis de restaurer la stabilité du salon.

# 2. Comment fonctionne un salon vocal Discord (important à comprendre)

Pour bien comprendre le bot, il faut comprendre **comment Discord gère les vocaux** :

### A. Chaque salon vocal est associé à un “serveur vocal” (une allocation)

Ce serveur vocal possède :
- Une IP
- Une région
- Une durée de vie limitée

Une allocation est **réinitialisée** dans les cas suivants :

1. Le salon devient totalement vide → nouvelle IP et nouveau serveur vocal à la prochaine connexion
2. La région du salon est changée
3. Discord réalloue le serveur vocal pour maintenance ou mise à jour (le bot est l'un des rares à détecter ce cas)

### B. Pour les salons de conférence (Stage channels)

Discord utilise **un modèle distribué** :  
- **Tous les 10 utilisateurs**, un **serveur vocal différent** est alloué
- Donc 100 utilisateurs = 10 serveurs vocaux différents
→ Il est **impossible** d'identifier un auteur d'attaque ou de détecter précisément l'origine en raison de cette fragmentation.

C'est pour cela qu'un mécanisme alternatif est proposé (voir section 7).

# 3. Comment fonctionne le bot (version simple et exacte)

## Étape A - Observation unique lors d'une nouvelle allocation

Le bot **ne rejoint pas en boucle**.

Il rejoint un salon vocal **uniquement** lorsque :
- Il contient 3 utilisateurs ou plus
- Et que ce salon vient d'obtenir une nouvelle allocation du serveur vocal

Le bot rejoint → obtient les statistiques réseau → quitte.
Ensuite, il **ne rejoint plus ce salon** tant que l'allocation reste la même.

### Important

Même s'il quitte, il continue d'avoir accès aux informations réseau internes du serveur vocal **tant que l'allocation existe**.

Il voit :
- Pertes de paquets
- Latence réelle des utilisateurs
- Micro-lags
- Incohérences protocolaires
- Fluctuations audio masquées par Discord

## Étape B - Détection des perturbations

Le bot considère qu'il y a un “mini-crash” lorsque :

- Les pertes de paquets dépassent 75 %
- Un pic de latence est observé
- Plusieurs utilisateurs subissent un freeze simultané
- Discord tente de compenser (tampon audio, accélération de lecture, ralentissement)
- Des anomalies protocolaires apparaissent

Ce sont des signaux invisibles pour la plupart des utilisateurs, car Discord corrige les symptômes côté client.

Le bot détecte ce que Discord cache.

## Étape C - Déclenchement d'une action

Si une perturbation est détectée, le bot :

### 1. Regénère la région du salon

Il change la région vocal → ce qui réinitialise totalement :
- la région
- l'adresse IP
- la session du serveur vocal
Cela coupe net la majorité des attaques.

### 2. Surveille l'occurrence

Si **3 perturbations surviennent en moins de 5 minutes**,
→ il considère qu'il s'agit presque certainement d'une attaque DDoS vocale.

### 3. Identifie les utilisateurs potentiellement liés

Le bot ne voit jamais l'IP des membres, mais il sait **qui possède l'IP du serveur vocal**, c'est-à-dire :

- tous les utilisateurs qui ont rejoint après la dernière allocation
- et qui étaient donc connectés lorsque la perturbation a eu lieu

### 4. Mesures temporaires

Les membres avec un faible historique vocal (moins de 20 minutes de vocal dans les 14 derniers jours) sont **timeout 1 minute** pour éviter la propagation dans d'autres salons.

# 4. Faux positifs : pourquoi ils existent

Le bot est configuré pour maximiser **la sécurité**, pas le confort.

Il est volontairement réglé pour :
- Détecter tous les mini-lags (0 faux négatifs)
- Intervenir avant que le crash soit perceptible
- Stopper une attaque avant qu'elle ne s'installe

Cela signifie qu'une variation temporaire de réseau *peut être interprétée* comme un début d'attaque.

C'est normal pour un système anti-DDoS.

# 5. Pourquoi vous ne voyez pas toujours les mini-crashs

Parce que Discord :
- Met en tampon l'audio
- Compense le retard
- Accélère ou ralentit légèrement la lecture
- Masque la perte de paquets tant que possible

Le bot, lui, voit les données techniques brutes.

# 6. Limites connues (transparence)

### A. Les salons standards :

→ Détection fiable, identification probabiliste très précise

### B. Les salons de conférence (stage channels) :

→ Discord sépare les utilisateurs en plusieurs serveurs vocaux (1 pour chaque groupe de 10)
→ Il est impossible de :
    - Regrouper les données
    - Identifier un attaquant
    - Mesurer l'impact de manière homogène

### Solution fournie pour les conférences

Nous proposons un service de **diffusion en temps réel** (hosting externe au bot) :

- 40 Tbps de mitigation DDoS (L4/L7)
- Aucun lag possible côté spectateurs
- Permet de continuer l'événement même si le vocal Discord est perturbé
- Fonctionne sans configuration, prêt à l'emploi

Cela garantit une continuité totale des grands événements vocaux.

# 7. Prochaines évolutions (IA / Machine Learning)

Nous développons actuellement un moteur avancé basé sur du Machine Learning :

- Détection comportementale des anomalies
- Réduction massive des faux positifs
- Scoring intelligent des utilisateurs récents
- Meilleure distinction entre un lag normal et une attaque coordonnée
- Prise en compte de dizaines de signaux réseau

De plus, le système de détection sera bientôt :
- Entièrement personnalisable
- Modifiable par des développeurs
- Basé sur un environnement isolé type **V8 isolate (Cloudflare Workers-like)**
- Sécurisé, extensible, et programmable

# Conclusion

Ce bot apporte une protection vocale unique basée sur une compréhension profonde du fonctionnement interne des serveurs vocaux Discord.
Il offre une détection ultra précoce, agit avant le crash visible, et isole les utilisateurs potentiellement impliqués, avec un niveau de transparence que vous ne trouverez dans aucun autre bot.
