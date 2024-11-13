
// Gestion des Transactions
//todo 1.1. Création et Modification des transactions : Gestion des types de transactions (crédit, débit), catégories, récurrence, et options de modification et suppression.
//todo 1.1.1 Formulaire avec sélection du type (crédit/débit) et de la catégorie
//todo 1.1.2 Ajout d'un label pour le type de transaction (crédit/débit) dans transaction_form_screen.dart
//todo 1.1.3 Ajout d'une option de récurrence pour les transactions
//todo 1.1.4 Modification de transactions avec options de suppression ou de récurrence
//todo 1.1.5 Mise à jour automatique des transactions récurrentes chaque mois

// Affichage et Gestion des Transactions dans la Liste
//todo 1.2. Affichage et filtre : Vue structurée des transactions par dates, sections, et types (débit/crédit), avec filtres par récurrence
//todo 1.2.1 Affichage trié par date (ordre décroissant)
//todo 1.2.2 Filtre pour afficher uniquement les transactions récurrentes
//todo 1.2.3 Séparation des transactions en sections "récurrentes" et "non récurrentes"
//todo 1.2.4 Badge indicateur pour les transactions récurrentes
//todo 1.2.5 Affichage de la date sous format jour, mois, année (en français)
//todo 1.2.6 Vue mensuelle et journalière avec options de filtrage par crédits, débits ou tous

// Interaction et Feedback Utilisateur
//todo 1.3. Interaction avec l’utilisateur : Fonctions de swipe pour modifier ou supprimer, messages de confirmation et d’erreur
//todo 1.3.1 Suppression d'une transaction par swipe dans transactions_base_view.dart
//todo 1.3.2 Modification d'une transaction par swipe dans transactions_base_view.dart
//todo 1.3.3 Confirmation de suppression avec dialogue de confirmation pour les transactions récurrentes
//todo 1.3.4 Message d'erreur pour les transactions sans catégorie sélectionnée
//todo 1.3.5 Sélection de jours avec transactions en surbrillance sur le calendrier
//todo 1.3.6 Navigation et rafraîchissement de l'interface après l'ajout ou la modification d'une transaction

// Gestion des Images et des Reçus
//todo 1.4. Reçus pour transactions : Limites de reçus par transaction, suppression, agrandissement, et gestion des sources d’image
//todo 1.4.1 Limitation de deux reçus par transaction avec option de suppression
//todo 1.4.2 Croix pour supprimer les photos et possibilité de les agrandir dans une vue
//todo 1.4.3 Modification ou suppression avec choix de source dans la vue d'une photo agrandie
//todo 1.4.4 Sélecteur d'images pour choisir entre galerie et caméra
//todo 1.4.5 Galerie de photos pour chaque transaction avec rafraîchissement après modification

// Vue Résumé (SummaryView)
//todo 2.1 Résumé du budget : Calcul et affichage des totaux de dépenses, crédits, et économies en fonction des transactions en cours
//todo 2.1.1 Calcul automatique des totaux au chargement de SummaryView
//todo 2.1.2 Affichage des économies dans SummaryView selon les conditions définies
//todo 2.1.3 Affichage en temps réel des mises à jour des montants après modification d'une transaction

// Vue de Transaction (TransactionsBaseView et TransactionDetails)
//todo 3.1 Vue détaillée des transactions : Affichage structuré par jour et par mois avec localisation et options pour voir et supprimer les reçus
//todo 3.1.1 Vérification de l’affichage des transactions par jour et par mois
//todo 3.1.2 Confirmation de l'affichage de la date et de la localisation dans transaction_details_view
//todo 3.1.3 Assurer l'agrandissement des images et la suppression des reçus

// Gestion des Catégories
//todo 4.1. Gestion des catégories : Sélection, affichage, et vérification de la bonne association des transactions aux catégories
//todo 4.1.1 Vérification que les transactions débit/crédit ne se mélangent pas entre catégories

// Gestion des Budgets
//todo 5.1. Gestion des budgets et des totaux mensuels : Affichage et mise à jour automatique du budget en fonction des transactions
//todo 5.1.1 Tester la copie des transactions récurrentes au changement de mois
//todo 5.1.2 Vérification de la mise à jour des totaux de budget après ajout ou suppression de transaction

// Gestion des Utilisateurs et Sécurité
//todo 6.1. Gestion du profil utilisateur : Sécurité des informations personnelles, réauthentification, et restriction d'accès aux champs sensibles
//todo 6.1.1 Réauthentification pour la modification de mot de passe
//todo 6.1.2 Restriction d'accès aux champs sensibles (comme le mot de passe) dans le profil

// Fonctionnalité de Calendrier
//todo 7.1 Calendrier intégré : Affichage des transactions par jour et par mois avec jours marqués en fonction de l’activité
//todo 7.1.1 Affichage correct du calendrier avec les jours contenant des transactions en surbrillance
//todo 7.1.2 Tester le fonctionnement du calendrier pour afficher les transactions par jour et par mois

// Refactoring du Code en Services
//todo 8.1. Refactoring pour organisation en services : Centralisation de la logique commune et optimisation des appels de services
//todo 8.1.1 Structuration de services pour gérer la logique des transactions, utilisateurs, et catégories

// Checklist pour Test Rétrospectifs
// Test des transactions
//todo 1.1 Tester la création et modification de transactions pour chaque cas de figure (crédit, débit, avec ou sans récurrence)
//todo 1.2 Vérifier l'affichage correct des transactions dans les filtres "récurrentes", "crédits", et "débits"
//todo 1.3 Vérifier la limitation de deux reçus par transaction et la possibilité de suppression

// Gestion des Totaux et Résumé
//todo 2.1 Tester le calcul automatique des totaux lors du chargement de SummaryView et les mises à jour en temps réel
//todo 2.2 Vérifier l'affichage des économies dans SummaryView selon les conditions définies

// Affichage des Transactions et Détails
//todo 3.1 Vérifier l’affichage des transactions par jour et par mois
//todo 3.2 Confirmer l'affichage de la date et la localisation dans transaction_details_view
//todo 3.3 Tester l'agrandissement des images et suppression des reçus

// Gestion des Budgets
//todo 4.1 Tester la copie des transactions récurrentes au changement de mois
//todo 4.2 Vérifier la mise à jour des totaux de budget après ajout ou suppression de transaction

// Interface Utilisateur et Sécurité
//todo 5.1 Confirmer la réauthentification pour la modification de mot de passe et accès restreint aux champs nécessaires (mot de passe)

// Fonctionnalités du Calendrier
//todo 6.1 Assurer l'affichage correct du calendrier avec les jours contenant des transactions en surbrillance
//todo 6.2 Tester le fonctionnement du calendrier pour afficher les transactions par jour et par mois