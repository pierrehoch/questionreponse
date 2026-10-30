# Question Réponse

Application mobile Flutter de questions indépendantes et de statistiques en
temps réel, adossée à Firebase.

Le projet est connecté au projet Firebase réel `question-reponse-app`.

Console Firebase :
<https://console.firebase.google.com/project/question-reponse-app/overview>

## Prérequis

- Flutter
- Android Studio avec Android SDK, ou Xcode avec CocoaPods
- un appareil physique ou un simulateur mobile

## Lancement

Connecter un appareil ou démarrer un simulateur, puis lancer :

```sh
flutter run
```

Android utilise Kotlin intégré à AGP 9 (`android.builtInKotlin=true`).
Flutter 3.47 peut néanmoins signaler les plugins Firebase comme utilisant KGP :
sa détection repère leurs déclarations conditionnelles pour les anciennes
versions d'AGP, même lorsqu'elles ne sont pas exécutées. Ne pas modifier le
cache des paquets pour masquer cet avertissement.

Pour le débogage sans fil sur iOS, autoriser l'accès au réseau local lorsque
iOS le demande. Si l'accès a été refusé, l'activer dans
**Réglages > Confidentialité et sécurité > Réseau local > Question Reponse**,
ou connecter l'appareil en USB. Les déclarations Bonjour nécessaires au service
de débogage Flutter sont déjà présentes dans `ios/Runner/Info.plist`.

En développement, App Check utilise le fournisseur de jeton de débogage. Dans
la console Firebase, vérifier que l'application iOS correspondante est
enregistrée dans App Check, puis ajouter le jeton affiché par l'appareil dans
ses jetons de débogage. Un jeton de débogage est un secret : ne pas le publier
ni le committer, et révoquer tout jeton qui a été exposé. En production, la
fonctionnalité utilise App Attest. Les fonctions callable continuent d'exiger
App Check dans les deux environnements.

## Production

```sh
flutter run --release --dart-define=APP_ENV=prod
```

La signature de distribution Android et le compte de signature Apple devront
être configurés avant publication sur les stores.

Cloud Firestore est configuré dans la région `europe-west9` (Paris). Avant de
développer l'authentification, activer le fournisseur
**Authentication > Sign-in method > Email/Password** dans la console. Cloud
Storage nécessite l'activation de la facturation Blaze pour les nouveaux
projets Firebase.

Après inscription, l'application exige la création d'un profil avec un pseudo
unique, un pays choisi dans la liste des pays ISO 3166-1 (sélecteur avec
recherche, `lib/core/countries/`), une valeur de sexe et sa date de naissance
précise (de 1900 à aujourd'hui). Cette date reste privée dans le profil ;
seule la tranche d'âge au moment du vote est conservée dans la réponse.
Les profils existants peuvent ajouter leur date depuis « Mon profil ».
Le pseudo et son
index d'unicité sont écrits dans une même transaction Firestore. Chaque utilisateur
peut également envoyer une photo JPEG/PNG de 5 Mo maximum ; les règles Storage
réservent l'écriture au propriétaire.

## Participation

Les réponses passent exclusivement par la Cloud Function callable
`submitResponse` dans `europe-west9`. Elle exige Authentication et App Check,
puis crée la réponse irréversible et met à jour les compteurs dans une même
transaction. Elle renvoie la réponse enregistrée et les statistiques mises à
jour afin que l'application affiche les résultats immédiatement, sans attendre
la propagation des listeners Firestore ; les flux temps réel prennent ensuite
le relais.

Le vote blanc et l'abstention ne sont pas proposés par défaut : ils
n'apparaissent que si la question a été créée avec `allowBlank` ou
`allowAbstention`. La fonction `submitResponse` et les règles Firestore
refusent (`response_type_not_allowed`) un type de réponse non autorisé.

La page affiche la question seule en tête, puis la date, l'icône et le bouton
« En savoir plus ». La feuille d'information occupe toute la largeur, s'ouvre
au minimum sur environ la moitié de l'écran et protège son contenu des zones
système du téléphone. Aucun titre « Résultats » n'est ajouté ; « En direct »
est placé à côté du nombre de participants lorsque le flux est connecté.
Les graphiques gardent le type choisi pour la question
(`packages/question_shared`) :

| Type | Clé | Rendu |
| --- | --- | --- |
| Anneau | `donut` | anneau avec le total au centre |
| Barres | `bars` | barres horizontales |
| Colonnes | `columns` | colonnes verticales avec lettres |
| Gaufre | `waffle` | grille de 100 carrés |
| Podium | `podium` | trois marches et médailles |
| Bulles | `bubbles` | cercles proportionnels |
| Duel | `versus` | barre unique avec badge « VS » |

Le bouton « Comparer les pays, sexes et âges » remplace les filtres. Il ouvre
trois vues de barres empilées normalisées, avec une légende commune et le
nombre de participants de chaque groupe. Un appui long sur une couleur donne
son pourcentage et son effectif. La callable `getDemographicStatistics`
exige Authentication, App Check et une participation à la question ; elle
ne renvoie que des agrégats, jamais les dates de naissance. Les tranches sont
moins de 18 ans, 18–24, 25–34, 35–44, 45–54, 55–64 et 65 ans et plus.
Les anciennes réponses sans âge restent dans « Âge non renseigné » ; elles
ne sont pas réécrites à partir du profil actuel. Les comparaisons sont
actualisées à chaque ouverture et ne portent pas la mention « En direct ».

L'historique remplace « Répondu » par une ligne multicolore proportionnelle
aux réponses de chaque question, sans légende. Une question sans réponse
montre une ligne neutre : les résultats restent masqués tant que
l'utilisateur n'a pas participé, comme les commentaires et les comparaisons.

Pour réduire les démarrages à froid de la fonction (payants), il est possible
d'ajouter `minInstances: 1` aux options de `submitResponse`.

Le déploiement de Cloud Functions et l'activation de Firebase Storage exigent
le forfait Blaze :
<https://console.firebase.google.com/project/question-reponse-app/usage/details>

Après activation de la facturation :

```sh
firebase deploy --only functions:submitResponse,storage
```

Après toute modification des règles ou de la fonction, redéployer :

```sh
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Les comparaisons nécessitent notamment le déploiement de
`getDemographicStatistics` et de l'index de groupe de collections sur
`responses.questionId`.

## Commentaires

Chaque question dispose d'un espace « Discussion » sous les résultats, réservé aux participants : il n'apparaît qu'après avoir répondu, pour ne pas influencer le vote.

- Stockage : `questions/{id}/comments/{commentId}` (`userId`, `username`, `vote`, `text` de 1 à 500 caractères, `createdAt`).
- Chaque commentaire affiche le vote réel de son auteur (pastille colorée comme dans le graphique) ; les règles Firestore vérifient pseudo et vote.
- Les commentaires ne sont pas modifiables ; l'auteur ou un administrateur peut les supprimer.
- Déploiement : `firebase deploy --only firestore:rules` puis reconstruire l'application mobile.

## Administration web

L'application d'administration séparée se trouve dans `admin/`. Elle permet
aux comptes possédant le custom claim Firebase Auth `admin: true` de créer,
modifier, programmer et supprimer les questions non publiées. Les questions
publiées sont immuables.

À la création, l'éditeur permet de choisir les options facultatives (vote
blanc, abstention), le type de représentation graphique parmi les vignettes
et une icône dans la banque d'icônes thématiques. Ces catalogues sont
partagés avec l'application mobile via le paquet local
`packages/question_shared`, et les champs Firestore correspondants
(`allowBlank`, `allowAbstention`, `chartType`, `icon`) sont validés par
`firestore.rules`.

Attribuer le rôle à un compte existant avec des identifiants Google locaux :

```sh
cd functions
gcloud auth application-default login
npm run set-admin -- administrateur@example.com
```

Le compte doit se déconnecter puis se reconnecter pour renouveler son token.

Lancer localement et déployer :

```sh
cd admin
flutter run -d chrome
flutter build web
cd ..
firebase deploy --only hosting
```

La fonction planifiée `publishScheduledQuestions` publie chaque minute les
questions arrivées à échéance.

## Qualité, sécurité et déploiement

Les tests backend lancent l'émulateur Firestore et vérifient les règles,
l'immutabilité des questions publiées et la résistance aux votes concurrents :

```sh
cd functions
PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" npm test
```

Les workflows GitHub Actions :

- `CI` analyse et teste le paquet partagé et les applications mobile/admin,
  construit le Web et exécute les tests Firebase ;
- `Deploy production` redéploie Firebase après validation sur `main` ou
  manuellement.

Le dépôt GitHub doit définir le secret d'environnement
`FIREBASE_SERVICE_ACCOUNT` avec un compte de service limité au déploiement
Firebase. Crashlytics collecte les erreurs fatales de l'application mobile,
App Check utilise Play Integrity/App Attest en production et les fonctions
émettent des journaux structurés pour les votes et publications planifiées.
