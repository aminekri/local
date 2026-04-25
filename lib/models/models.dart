// lib/models/models.dart
// Tous les modèles de données de l'application

class Ingredient {
  final String id;
  String nom;
  double quantite;
  String unite;
  double seuilAlerte;
  bool estImportant;

  Ingredient({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.unite,
    required this.seuilAlerte,
    required this.estImportant,
  });

  bool get estEnRupture => estImportant && quantite <= seuilAlerte;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'quantite': quantite,
        'unite': unite,
        'seuilAlerte': seuilAlerte,
        'estImportant': estImportant ? 1 : 0,
      };

  factory Ingredient.fromMap(Map<String, dynamic> m) => Ingredient(
        id: m['id'],
        nom: m['nom'],
        quantite: m['quantite'],
        unite: m['unite'],
        seuilAlerte: m['seuilAlerte'],
        estImportant: m['estImportant'] == 1,
      );

  Ingredient copyWith({
    String? nom,
    double? quantite,
    String? unite,
    double? seuilAlerte,
    bool? estImportant,
  }) =>
      Ingredient(
        id: id,
        nom: nom ?? this.nom,
        quantite: quantite ?? this.quantite,
        unite: unite ?? this.unite,
        seuilAlerte: seuilAlerte ?? this.seuilAlerte,
        estImportant: estImportant ?? this.estImportant,
      );
}

class IngredientProduit {
  final String ingredientId;
  final double quantiteUtilisee;

  IngredientProduit({
    required this.ingredientId,
    required this.quantiteUtilisee,
  });

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'quantiteUtilisee': quantiteUtilisee,
      };

  factory IngredientProduit.fromMap(Map<String, dynamic> m) => IngredientProduit(
        ingredientId: m['ingredientId'],
        quantiteUtilisee: m['quantiteUtilisee'],
      );
}

class Supplement {
  final String id;
  String nom;
  double prix;
  String ingredientId;
  double quantiteUtilisee;

  Supplement({
    required this.id,
    required this.nom,
    required this.prix,
    required this.ingredientId,
    required this.quantiteUtilisee,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prix': prix,
        'ingredientId': ingredientId,
        'quantiteUtilisee': quantiteUtilisee,
      };

  factory Supplement.fromMap(Map<String, dynamic> m) => Supplement(
        id: m['id'],
        nom: m['nom'],
        prix: m['prix'],
        ingredientId: m['ingredientId'],
        quantiteUtilisee: m['quantiteUtilisee'],
      );

  Supplement copyWith({
    String? nom,
    double? prix,
    String? ingredientId,
    double? quantiteUtilisee,
  }) =>
      Supplement(
        id: id,
        nom: nom ?? this.nom,
        prix: prix ?? this.prix,
        ingredientId: ingredientId ?? this.ingredientId,
        quantiteUtilisee: quantiteUtilisee ?? this.quantiteUtilisee,
      );
}

class Categorie {
  final String id;
  String nom;

  Categorie({required this.id, required this.nom});

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom};

  factory Categorie.fromMap(Map<String, dynamic> m) =>
      Categorie(id: m['id'], nom: m['nom']);
}

class Produit {
  final String id;
  String nom;
  double prix;
  String categorieId;
  List<IngredientProduit> ingredients;
  String? imageUrl;

  Produit({
    required this.id,
    required this.nom,
    required this.prix,
    required this.categorieId,
    required this.ingredients,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prix': prix,
        'categorieId': categorieId,
        'imageUrl': imageUrl,
      };

  factory Produit.fromMap(Map<String, dynamic> m, List<IngredientProduit> ingredients) =>
      Produit(
        id: m['id'],
        nom: m['nom'],
        prix: m['prix'],
        categorieId: m['categorieId'],
        ingredients: ingredients,
        imageUrl: m['imageUrl'],
      );

  Produit copyWith({
    String? nom,
    double? prix,
    String? categorieId,
    List<IngredientProduit>? ingredients,
  }) =>
      Produit(
        id: id,
        nom: nom ?? this.nom,
        prix: prix ?? this.prix,
        categorieId: categorieId ?? this.categorieId,
        ingredients: ingredients ?? this.ingredients,
        imageUrl: imageUrl,
      );
}

class LigneCommande {
  final String id;
  final Produit produit;
  int quantite;
  List<Supplement> supplements;
  String commentaire;

  LigneCommande({
    required this.id,
    required this.produit,
    required this.quantite,
    List<Supplement>? supplements,
    this.commentaire = '',
  }) : supplements = supplements ?? [];

  double get sousTotal =>
      (produit.prix + supplements.fold(0.0, (s, sup) => s + sup.prix)) * quantite;

  LigneCommande copyWith({int? quantite, List<Supplement>? supplements, String? commentaire}) =>
      LigneCommande(
        id: id,
        produit: produit,
        quantite: quantite ?? this.quantite,
        supplements: supplements ?? this.supplements,
        commentaire: commentaire ?? this.commentaire,
      );
}

class Ticket {
  final String id;
  final int numero;
  final DateTime dateHeure;
  final List<LigneCommande> lignes;
  final double total;
  final double tva; // TVA Tunisie 19%
  final bool avecTicket;
  String? commentaireGeneral;

  Ticket({
    required this.id,
    required this.numero,
    required this.dateHeure,
    required this.lignes,
    required this.total,
    required this.tva,
    required this.avecTicket,
    this.commentaireGeneral,
  });

  double get totalHT => total / 1.19;
  double get montantTVA => total - totalHT;
  double get totalTTC => total;

  Map<String, dynamic> toMap() => {
        'id': id,
        'numero': numero,
        'dateHeure': dateHeure.toIso8601String(),
        'total': total,
        'tva': tva,
        'avecTicket': avecTicket ? 1 : 0,
        'commentaireGeneral': commentaireGeneral,
      };

  factory Ticket.fromMap(Map<String, dynamic> m, List<LigneCommande> lignes) => Ticket(
        id: m['id'],
        numero: m['numero'],
        dateHeure: DateTime.parse(m['dateHeure']),
        lignes: lignes,
        total: m['total'],
        tva: m['tva'],
        avecTicket: m['avecTicket'] == 1,
        commentaireGeneral: m['commentaireGeneral'],
      );
}
