//todo 1.1. Gestion des Transactions
//todo 1.1. a. Création et Modification des transactions
//todo 1.1. b. Formulaire avec sélection du type (crédit/débit) et de la catégorie
//todo 1.1. c. Ajout d'un label pour le type de transaction (crédit/débit) dans transaction_form_screen.dart
//todo 1.1. d. Ajout d'une option de récurence pour les transactions.
//todo 1.1. e. Modification de transcations avec options de suppression ou de récurrence.
//todo 1.1. f. Mise à jour automatique des transcations récurrentes chaque mois.
//todo 1.2. Affichage et Gestion des Transactions dans la Liste
//todo 1.2. a. Affichage trié par date (ordre décroissant)
//todo 1.2. b. Filtre pour afficher uniquement les transactions récurrentes.
//todo 1.2. c. Séparation des transactions en sections "récurrentes" et "non récurrentes"
//todo 1.2. d. Badge d'inndicateur pour les transactions récurrentes.
//todo 1.2. e. Affichage de la date sous format jour, mois, année (en français).
//todo 1.2. f. Vue mensuelle et journalière avec options de filtrage par crédits, débits ou tous.
//todo 1.3. Interaction et Feedback Utilisateur
//todo 1.3. a. Possibilité de supprimer une transaction par swipe dans transactions_base_view.dart.
//todo 1.3. b. Possibilité de modifier une transaction par swipe dans transactions_base_view.dart
//todo 1.3. c. Confirmation de suppression avec dialogue de confirmation pour les transcations réccurentes.
//todo 1.3. d. Message d'erreur pour les transactions sans catégorie sélectionnée.
//todo 1.3. e. Sélection de jours avec transctions en surbrillance sur le calendrier.
//todo 1.3. f. Navigation et rafraîchissement de l'interface après l'ajout ou la modification d'une transaction.
//todo 1.4. Gestion des Images et des Reçus
//todo 1.4. a. Limitation de deux reçus par transaction avec option de suppressions.
//todo 1.4. b. Croix pour supprimer les photos et possibilité de les agrandir dans une vue.
//todo 1.4. c. Modification ou suppression avec choix de source dans la vue d'une photos agrandie.
//todo 1.4. d. Intérgation d'une selectieur d'images pour choisir entre galerie et caméra.
//todo 1.4. e. Galerie de photos pour chaque transactions avec rafraîchissement après modification.
//todo 2.1. Vue Résumé (SummaryView)
//todo 2.1. a.
//todo 3.1. Vue de Transaction (TransactionsBaseView et TransactionDetails)
//todo 3.1. a.
//todo 4.1 Gestion des Catégories
//todo 4.1. a.
//todo 5.1 Gestion des Budgets
//todo 5.1. a.
//todo 6.1 Gestion des Utilisateur et Sécurité
//todo 6.1. a.
//todo 7.1 Fonctionnalité de Calendrier
//todo 7.1. a.
//todo 8.1 Refactoring du Code en Services
//todo 8.1. a.


// Checklist pour Test Rétrospectifs
//todo 1. Création et Modification des transactions
//todo 1.1. a. Tester la création d'une transaction crédit
//todo 1.1. b. Tester la création d'une transaction débit
//todo 1.1. c. Tester la création d'une transaction débit avec récurrence
//todo 1.1. d. Tester la création d'une transaction crédit avec récurrence
//todo 1.2. a. Vérifier l'affichage corrects des transactions dans les filtres "récurrentes", "crédits", et "débits",
//todo 1.2. b. Vérifier la limite de deux reçus par transaction et la possibilité de suppression.

//todo 2. Gestion des Totaux et Résumé
//todo 2.1. a. Confirmer le calcul automatique des totaux lors du chargement de SummaryView.
//todo 2.1. b. Vérifier l’affichage des économies dans SummaryView selon les conditions définies.
//todo 2.1. c. Tester l'affichage en temps réel des mises à jour des montants après modification d'une transaction.

//todo 3. Affichage des Transactions et Détails
//todo 2.1. a. Vérifier l’affichage des transactions par jour et par mois.
//todo 2.1. b. Confirmer l'affichage de la date et la localisation dans transaction_details_view.
//todo 2.1. c. Assurer que l’agrandissement des images et la suppression des reçus fonctionnent comme attendu.

//todo 4. Gestion des Budgets
//todo 2.1. a. Tester la copie des transactions récurrentes au changement de mois.
//todo 2.1. b. Vérifier la mise à jour des totaux de budget après ajout ou suppression de transaction.

//todo 5. Interface Utilisateur et Sécurité
//todo 2.1. a. Confirmer la réauthentification pour la modification de mot de passe.
//todo 2.1. b. Vérifier que seuls les champs nécessaires (mot de passe) sont accessibles dans le profil.

//todo 6. Fonctionnalités du Calendrier
//todo 2.1. a. Assurer l'affichage correct du calendrier avec les jours contenant des transactions en surbrillance.
//todo 2.1. b. Tester le fonctionnement du calendrier pour afficher les transactions par jour et par mois.

