// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/database_service.dart';

class AppProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  List<Ingredient> _ingredients = [];
  List<Supplement> _supplements = [];
  List<Categorie> _categories = [];
  List<Produit> _produits = [];
  List<Ticket> _tickets = [];
  Map<String, String> _config = {};
  final List<LigneCommande> _lignesCommande = [];
  bool _chargement = false;
  int _numeroTicketActuel = 0;

  List<Ingredient> get ingredients => _ingredients;
  List<Supplement> get supplements => _supplements;
  List<Categorie> get categories => _categories;
  List<Produit> get produits => _produits;
  List<Ticket> get tickets => _tickets;
  List<LigneCommande> get lignesCommande => _lignesCommande;
  Map<String, String> get config => _config;
  bool get chargement => _chargement;
  int get numeroTicketActuel => _numeroTicketActuel;

  double get totalCommande =>
      _lignesCommande.fold(0.0, (s, l) => s + l.sousTotal);

  Future<void> init() async {
    _chargement = true;
    notifyListeners();
    await _chargerTout();
    _chargement = false;
    notifyListeners();
  }

  Future<void> _chargerTout() async {
    _ingredients = await DatabaseService.getIngredients();
    _supplements = await DatabaseService.getSupplements();
    _categories = await DatabaseService.getCategories();
    _produits = await DatabaseService.getProduits();
    _tickets = await DatabaseService.getTickets();
    _config = await DatabaseService.getConfig();
    _numeroTicketActuel = await DatabaseService.getNumeroTicketActuel();
  }

  // ============ INGREDIENTS ============
  Future<void> ajouterIngredient(Ingredient ing) async {
    await DatabaseService.insertIngredient(ing);
    _ingredients = await DatabaseService.getIngredients();
    notifyListeners();
  }

  Future<void> modifierIngredient(Ingredient ing) async {
    await DatabaseService.updateIngredient(ing);
    _ingredients = await DatabaseService.getIngredients();
    notifyListeners();
  }

  Future<void> supprimerIngredient(String id) async {
    await DatabaseService.deleteIngredient(id);
    _ingredients = await DatabaseService.getIngredients();
    notifyListeners();
  }

  Ingredient? getIngredient(String id) =>
      _ingredients.where((i) => i.id == id).firstOrNull;

  // ============ SUPPLEMENTS ============
  Future<void> ajouterSupplement(Supplement s) async {
    await DatabaseService.insertSupplement(s);
    _supplements = await DatabaseService.getSupplements();
    notifyListeners();
  }

  Future<void> modifierSupplement(Supplement s) async {
    await DatabaseService.updateSupplement(s);
    _supplements = await DatabaseService.getSupplements();
    notifyListeners();
  }

  Future<void> supprimerSupplement(String id) async {
    await DatabaseService.deleteSupplement(id);
    _supplements = await DatabaseService.getSupplements();
    notifyListeners();
  }

  // ============ CATEGORIES ============
  Future<void> ajouterCategorie(String nom) async {
    final cat = Categorie(id: _uuid.v4(), nom: nom);
    await DatabaseService.insertCategorie(cat);
    _categories = await DatabaseService.getCategories();
    notifyListeners();
  }

  Future<void> supprimerCategorie(String id) async {
    await DatabaseService.deleteCategorie(id);
    _categories = await DatabaseService.getCategories();
    notifyListeners();
  }

  // ============ PRODUITS ============
  Future<void> ajouterProduit(Produit p) async {
    await DatabaseService.insertProduit(p);
    _produits = await DatabaseService.getProduits();
    notifyListeners();
  }

  Future<void> modifierProduit(Produit p) async {
    await DatabaseService.updateProduit(p);
    _produits = await DatabaseService.getProduits();
    notifyListeners();
  }

  Future<void> supprimerProduit(String id) async {
    await DatabaseService.deleteProduit(id);
    _produits = await DatabaseService.getProduits();
    notifyListeners();
  }

  // ============ COMMANDE EN COURS ============
  String? verifierStockProduit(Produit produit, int quantiteCommandee) {
    for (final ingProd in produit.ingredients) {
      final ing = getIngredient(ingProd.ingredientId);
      if (ing != null && ing.estImportant) {
        final qteNecessaire = ingProd.quantiteUtilisee * quantiteCommandee;
        if (ing.quantite < qteNecessaire) {
          return 'Stock insuffisant: ${ing.nom} (dispo: ${ing.quantite} ${ing.unite}, requis: $qteNecessaire)';
        }
      }
    }
    return null;
  }

  void ajouterProduitNouvelLigne(Produit produit) {
    final erreur = verifierStockProduit(produit, 1);
    if (erreur != null) throw Exception(erreur);
    _lignesCommande.add(LigneCommande(id: _uuid.v4(), produit: produit, quantite: 1));
    notifyListeners();
  }

  void supprimerLigne(String ligneId) {
    _lignesCommande.removeWhere((l) => l.id == ligneId);
    notifyListeners();
  }

  void modifierQuantiteLigne(String ligneId, int nouvelleQuantite) {
    if (nouvelleQuantite <= 0) {
      supprimerLigne(ligneId);
      return;
    }
    final idx = _lignesCommande.indexWhere((l) => l.id == ligneId);
    if (idx >= 0) {
      final ligne = _lignesCommande[idx];
      final erreur = verifierStockProduit(ligne.produit, nouvelleQuantite);
      if (erreur != null) throw Exception(erreur);
      _lignesCommande[idx] = ligne.copyWith(quantite: nouvelleQuantite);
      notifyListeners();
    }
  }

  void ajouterSupplementLigne(String ligneId, Supplement sup) {
    final idx = _lignesCommande.indexWhere((l) => l.id == ligneId);
    if (idx >= 0) {
      final sups = List<Supplement>.from(_lignesCommande[idx].supplements)..add(sup);
      _lignesCommande[idx] = _lignesCommande[idx].copyWith(supplements: sups);
      notifyListeners();
    }
  }

  void supprimerSupplementLigne(String ligneId, String supId) {
    final idx = _lignesCommande.indexWhere((l) => l.id == ligneId);
    if (idx >= 0) {
      final sups = _lignesCommande[idx].supplements.where((s) => s.id != supId).toList();
      _lignesCommande[idx] = _lignesCommande[idx].copyWith(supplements: sups);
      notifyListeners();
    }
  }

  void setCommentaireLigne(String ligneId, String commentaire) {
    final idx = _lignesCommande.indexWhere((l) => l.id == ligneId);
    if (idx >= 0) {
      _lignesCommande[idx] = _lignesCommande[idx].copyWith(commentaire: commentaire);
      notifyListeners();
    }
  }

  void annulerCommande() {
    _lignesCommande.clear();
    notifyListeners();
  }

  Future<Ticket> validerCommande({required bool avecTicket}) async {
    if (_lignesCommande.isEmpty) throw Exception('Commande vide');

    final numero = await DatabaseService.getNextNumeroTicket();
    final ticket = Ticket(
      id: _uuid.v4(),
      numero: numero,
      dateHeure: DateTime.now(),
      lignes: List.from(_lignesCommande),
      total: totalCommande,
      tva: 0.19,
      avecTicket: avecTicket,
    );

    // Déduire les stocks
    for (final ligne in _lignesCommande) {
      for (final ingProd in ligne.produit.ingredients) {
        await DatabaseService.updateIngredientQuantite(
            ingProd.ingredientId, -(ingProd.quantiteUtilisee * ligne.quantite));
      }
      for (final sup in ligne.supplements) {
        await DatabaseService.updateIngredientQuantite(
            sup.ingredientId, -(sup.quantiteUtilisee * ligne.quantite));
      }
    }

    await DatabaseService.insertTicket(ticket);
    _lignesCommande.clear();
    await _chargerTout();
    notifyListeners();
    return ticket;
  }

  // ============ ADMIN ============

  /// Remet uniquement le numéro de ticket à 1 — conserve l'historique
  Future<void> resetNumeroTicketSeulement() async {
    await DatabaseService.resetNumeroTicketSeulement();
    _numeroTicketActuel = 0;
    notifyListeners();
  }

  // ============ STATS ============
  Future<Map<String, dynamic>> getStatsSemaine() => DatabaseService.getStatsSemaine();
  Future<Map<String, dynamic>> getStatsMois() => DatabaseService.getStatsMois();
  Future<List<Map<String, dynamic>>> getVentesParJour(int nbJours) =>
      DatabaseService.getVentesParJour(nbJours);
  Future<Map<String, dynamic>> getZRapport() => DatabaseService.getZRapport();

  String newId() => _uuid.v4();
}
