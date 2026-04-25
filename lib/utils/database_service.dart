// lib/utils/database_service.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;
  static const String _dbName = 'caisse_resto.db';
  static const int _version = 1;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    // Desktop: utiliser sqflite_common_ffi
    // Mobile (Android/iOS): utiliser sqflite natif via databaseFactory par défaut
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(version: _version, onCreate: _onCreate));
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE ingredients(
      id TEXT PRIMARY KEY, nom TEXT NOT NULL, quantite REAL NOT NULL,
      unite TEXT NOT NULL, seuilAlerte REAL NOT NULL, estImportant INTEGER NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE supplements(
      id TEXT PRIMARY KEY, nom TEXT NOT NULL, prix REAL NOT NULL,
      ingredientId TEXT NOT NULL, quantiteUtilisee REAL NOT NULL
    )''');
    await db.execute('''CREATE TABLE categories(id TEXT PRIMARY KEY, nom TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE produits(
      id TEXT PRIMARY KEY, nom TEXT NOT NULL, prix REAL NOT NULL,
      categorieId TEXT NOT NULL, imageUrl TEXT
    )''');
    await db.execute('''CREATE TABLE produit_ingredients(
      produitId TEXT NOT NULL, ingredientId TEXT NOT NULL, quantiteUtilisee REAL NOT NULL,
      PRIMARY KEY(produitId, ingredientId)
    )''');
    await db.execute('''CREATE TABLE tickets(
      id TEXT PRIMARY KEY, numero INTEGER NOT NULL, dateHeure TEXT NOT NULL,
      total REAL NOT NULL, tva REAL NOT NULL, avecTicket INTEGER NOT NULL DEFAULT 1,
      commentaireGeneral TEXT
    )''');
    await db.execute('''CREATE TABLE lignes_commande(
      id TEXT PRIMARY KEY, ticketId TEXT NOT NULL, produitId TEXT NOT NULL,
      quantite INTEGER NOT NULL, commentaire TEXT
    )''');
    await db.execute('''CREATE TABLE ligne_supplements(
      ligneId TEXT NOT NULL, supplementId TEXT NOT NULL, PRIMARY KEY(ligneId, supplementId)
    )''');
    await db.execute('''CREATE TABLE config(cle TEXT PRIMARY KEY, valeur TEXT NOT NULL)''');

    // Config initiale
    await db.insert('config', {'cle': 'numero_ticket', 'valeur': '0'});
    await db.insert('config', {'cle': 'nom_restaurant', 'valeur': 'Mon Restaurant'});
    await db.insert('config', {'cle': 'adresse', 'valeur': 'Tunis, Tunisie'});
    await db.insert('config', {'cle': 'mf', 'valeur': '0000000/A/A/M/000'});

    await _insertDemoData(db);
  }

  static Future<void> _insertDemoData(Database db) async {
    const catId1 = 'cat_1';
    const catId2 = 'cat_2';
    await db.insert('categories', {'id': catId1, 'nom': 'Plats'});
    await db.insert('categories', {'id': catId2, 'nom': 'Boissons'});

    const ing1 = 'ing_1';
    const ing2 = 'ing_2';
    await db.insert('ingredients', {
      'id': ing1, 'nom': 'Poulet', 'quantite': 5.0, 'unite': 'kg',
      'seuilAlerte': 1.0, 'estImportant': 1
    });
    await db.insert('ingredients', {
      'id': ing2, 'nom': 'Pain', 'quantite': 20.0, 'unite': 'pièce',
      'seuilAlerte': 5.0, 'estImportant': 1
    });
    await db.insert('supplements', {
      'id': 'sup_1', 'nom': 'Extra fromage', 'prix': 1.5,
      'ingredientId': ing2, 'quantiteUtilisee': 1.0
    });
    await db.insert('produits', {
      'id': 'prod_1', 'nom': 'Sandwich Poulet', 'prix': 8.5, 'categorieId': catId1
    });
    await db.insert('produits', {
      'id': 'prod_2', 'nom': 'Jus Orange', 'prix': 3.0, 'categorieId': catId2
    });
    await db.insert('produit_ingredients', {
      'produitId': 'prod_1', 'ingredientId': ing1, 'quantiteUtilisee': 0.2
    });
    await db.insert('produit_ingredients', {
      'produitId': 'prod_1', 'ingredientId': ing2, 'quantiteUtilisee': 1.0
    });
  }

  // =================== INGREDIENTS ===================
  static Future<List<Ingredient>> getIngredients() async {
    final d = await db;
    return (await d.query('ingredients')).map(Ingredient.fromMap).toList();
  }

  static Future<void> insertIngredient(Ingredient ing) async {
    final d = await db;
    await d.insert('ingredients', ing.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateIngredient(Ingredient ing) async {
    final d = await db;
    await d.update('ingredients', ing.toMap(), where: 'id = ?', whereArgs: [ing.id]);
  }

  static Future<void> deleteIngredient(String id) async {
    final d = await db;
    await d.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateIngredientQuantite(String id, double delta) async {
    final d = await db;
    await d.rawUpdate(
        'UPDATE ingredients SET quantite = quantite + ? WHERE id = ?', [delta, id]);
  }

  // =================== SUPPLEMENTS ===================
  static Future<List<Supplement>> getSupplements() async {
    final d = await db;
    return (await d.query('supplements')).map(Supplement.fromMap).toList();
  }

  static Future<void> insertSupplement(Supplement s) async {
    final d = await db;
    await d.insert('supplements', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSupplement(Supplement s) async {
    final d = await db;
    await d.update('supplements', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  static Future<void> deleteSupplement(String id) async {
    final d = await db;
    await d.delete('supplements', where: 'id = ?', whereArgs: [id]);
  }

  // =================== CATEGORIES ===================
  static Future<List<Categorie>> getCategories() async {
    final d = await db;
    return (await d.query('categories')).map(Categorie.fromMap).toList();
  }

  static Future<void> insertCategorie(Categorie c) async {
    final d = await db;
    await d.insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCategorie(String id) async {
    final d = await db;
    await d.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // =================== PRODUITS ===================
  static Future<List<Produit>> getProduits() async {
    final d = await db;
    final maps = await d.query('produits');
    final produits = <Produit>[];
    for (final m in maps) {
      final ingMaps = await d.query('produit_ingredients',
          where: 'produitId = ?', whereArgs: [m['id']]);
      produits.add(Produit.fromMap(m, ingMaps.map(IngredientProduit.fromMap).toList()));
    }
    return produits;
  }

  static Future<void> insertProduit(Produit p) async {
    final d = await db;
    await d.insert('produits', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await d.delete('produit_ingredients', where: 'produitId = ?', whereArgs: [p.id]);
    for (final ing in p.ingredients) {
      await d.insert('produit_ingredients', {
        'produitId': p.id, 'ingredientId': ing.ingredientId,
        'quantiteUtilisee': ing.quantiteUtilisee,
      });
    }
  }

  static Future<void> updateProduit(Produit p) async {
    final d = await db;
    await d.update('produits', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    await d.delete('produit_ingredients', where: 'produitId = ?', whereArgs: [p.id]);
    for (final ing in p.ingredients) {
      await d.insert('produit_ingredients', {
        'produitId': p.id, 'ingredientId': ing.ingredientId,
        'quantiteUtilisee': ing.quantiteUtilisee,
      });
    }
  }

  static Future<void> deleteProduit(String id) async {
    final d = await db;
    await d.delete('produit_ingredients', where: 'produitId = ?', whereArgs: [id]);
    await d.delete('produits', where: 'id = ?', whereArgs: [id]);
  }

  // =================== TICKETS ===================
  static Future<int> getNextNumeroTicket() async {
    final d = await db;
    final result = await d.query('config', where: 'cle = ?', whereArgs: ['numero_ticket']);
    final current = int.parse(result.first['valeur'] as String);
    final next = current + 1;
    await d.update('config', {'valeur': next.toString()},
        where: 'cle = ?', whereArgs: ['numero_ticket']);
    return next;
  }

  static Future<int> getNumeroTicketActuel() async {
    final d = await db;
    final result = await d.query('config', where: 'cle = ?', whereArgs: ['numero_ticket']);
    return int.parse(result.first['valeur'] as String);
  }

  /// Remet uniquement le compteur à 0 — NE supprime PAS l'historique
  static Future<void> resetNumeroTicketSeulement() async {
    final d = await db;
    await d.update('config', {'valeur': '0'},
        where: 'cle = ?', whereArgs: ['numero_ticket']);
  }

  static Future<void> insertTicket(Ticket ticket) async {
    final d = await db;
    await d.insert('tickets', ticket.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final ligne in ticket.lignes) {
      await d.insert('lignes_commande', {
        'id': ligne.id, 'ticketId': ticket.id, 'produitId': ligne.produit.id,
        'quantite': ligne.quantite, 'commentaire': ligne.commentaire,
      });
      for (final sup in ligne.supplements) {
        await d.insert('ligne_supplements', {'ligneId': ligne.id, 'supplementId': sup.id});
      }
    }
  }

  static Future<List<Ticket>> getTickets() async {
    final d = await db;
    final ticketMaps = await d.query('tickets', orderBy: 'dateHeure DESC');
    final produits = await getProduits();
    final supplements = await getSupplements();
    final prodsMap = {for (final p in produits) p.id: p};
    final supsMap = {for (final s in supplements) s.id: s};

    final tickets = <Ticket>[];
    for (final tm in ticketMaps) {
      final ligneMaps = await d.query('lignes_commande',
          where: 'ticketId = ?', whereArgs: [tm['id']]);
      final lignes = <LigneCommande>[];
      for (final lm in ligneMaps) {
        final supMaps = await d.query('ligne_supplements',
            where: 'ligneId = ?', whereArgs: [lm['id']]);
        final sups = supMaps
            .map((sm) => supsMap[sm['supplementId']])
            .whereType<Supplement>()
            .toList();
        final prod = prodsMap[lm['produitId']];
        if (prod != null) {
          lignes.add(LigneCommande(
            id: lm['id'] as String, produit: prod,
            quantite: lm['quantite'] as int,
            supplements: sups,
            commentaire: lm['commentaire'] as String? ?? '',
          ));
        }
      }
      tickets.add(Ticket.fromMap(tm, lignes));
    }
    return tickets;
  }

  // =================== CONFIG ===================
  static Future<Map<String, String>> getConfig() async {
    final d = await db;
    final maps = await d.query('config');
    return {for (final m in maps) m['cle'] as String: m['valeur'] as String};
  }

  static Future<void> setConfig(String cle, String valeur) async {
    final d = await db;
    await d.insert('config', {'cle': cle, 'valeur': valeur},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // =================== STATS ===================
  static Future<Map<String, dynamic>> getStatsSemaine() async {
    final d = await db;
    final now = DateTime.now();
    final debut = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final result = await d.rawQuery(
        'SELECT COUNT(*) as nb, SUM(total) as total FROM tickets WHERE dateHeure >= ?',
        [debut.toIso8601String()]);
    return {'nb_tickets': result.first['nb'] ?? 0, 'total': result.first['total'] ?? 0.0};
  }

  static Future<Map<String, dynamic>> getStatsMois() async {
    final d = await db;
    final now = DateTime.now();
    final debut = DateTime(now.year, now.month, 1);
    final result = await d.rawQuery(
        'SELECT COUNT(*) as nb, SUM(total) as total FROM tickets WHERE dateHeure >= ?',
        [debut.toIso8601String()]);
    return {'nb_tickets': result.first['nb'] ?? 0, 'total': result.first['total'] ?? 0.0};
  }

  static Future<List<Map<String, dynamic>>> getVentesParJour(int nbJours) async {
    final d = await db;
    final debut = DateTime.now().subtract(Duration(days: nbJours));
    return d.rawQuery(
        'SELECT DATE(dateHeure) as jour, SUM(total) as total, COUNT(*) as nb '
        'FROM tickets WHERE dateHeure >= ? GROUP BY DATE(dateHeure) ORDER BY jour ASC',
        [debut.toIso8601String()]);
  }

  // =================== Z-RAPPORT ===================
  static Future<Map<String, dynamic>> getZRapport() async {
    final d = await db;
    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day);

    final res = await d.rawQuery(
        'SELECT COUNT(*) as nb, SUM(total) as total FROM tickets WHERE dateHeure >= ?',
        [debutJour.toIso8601String()]);

    final parProduit = await d.rawQuery('''
      SELECT p.nom, SUM(lc.quantite) as qte, SUM(lc.quantite * p.prix) as montant
      FROM lignes_commande lc
      JOIN tickets t ON t.id = lc.ticketId
      JOIN produits p ON p.id = lc.produitId
      WHERE t.dateHeure >= ?
      GROUP BY p.id ORDER BY montant DESC
    ''', [debutJour.toIso8601String()]);

    final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;
    return {
      'date': debutJour,
      'nb_tickets': res.first['nb'] ?? 0,
      'total_ttc': total,
      'total_ht': total / 1.19,
      'total_tva': total - (total / 1.19),
      'par_produit': parProduit,
    };
  }
}
