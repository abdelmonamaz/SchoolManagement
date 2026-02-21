#include "database/database_manager.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

bool DatabaseManager::initialize(const QString& dbPath, const QString& connectionName)
{
    if (QSqlDatabase::contains(connectionName)) {
        auto db = QSqlDatabase::database(connectionName);
        if (db.isOpen())
            return true;
    }

    auto db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);

    if (!db.open()) {
        qCritical() << "[DatabaseManager] Failed to open database:"
                     << db.lastError().text();
        return false;
    }

    // Enable foreign-key enforcement for every connection.
    QSqlQuery pragma(db);
    pragma.exec(QStringLiteral("PRAGMA foreign_keys = ON;"));

    qInfo() << "[DatabaseManager] Database opened –" << connectionName
            << "→" << dbPath;
    return true;
}

void DatabaseManager::createSchema(const QString& connectionName)
{
    auto db = QSqlDatabase::database(connectionName);
    if (!db.isOpen()) {
        qWarning() << "[DatabaseManager] createSchema called on closed connection"
                    << connectionName;
        return;
    }

    createTables(db);
    seedInitialData(db);
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

static bool execStatement(QSqlDatabase& db, const QString& sql)
{
    QSqlQuery q(db);
    if (!q.exec(sql)) {
        qWarning() << "[DatabaseManager] SQL error:" << q.lastError().text()
                    << "\n  Statement:" << sql;
        return false;
    }
    return true;
}

void DatabaseManager::createTables(QSqlDatabase& db)
{
    const QStringList statements {
        // ── Salles ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS salles ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  capacite_chaises INTEGER NOT NULL,"
            "  equipement TEXT"
            ")"),

        // ── Niveaux ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS niveaux ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL"
            ")"),

        // ── Classes ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS classes ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  niveau_id INTEGER REFERENCES niveaux(id) ON DELETE CASCADE"
            ")"),

        // ── Professeurs / Personnel ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS professeurs ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  prenom TEXT,"
            "  telephone TEXT,"
            "  adresse TEXT,"
            "  poste TEXT DEFAULT 'Enseignant',"
            "  specialite TEXT,"
            "  mode_paie TEXT DEFAULT 'Heure',"
            "  valeur_base REAL DEFAULT 25.0,"
            "  paye_pendant_vacances INTEGER DEFAULT 1,"
            "  heures_travalies INTEGER DEFAULT 0,"
            "  statut TEXT DEFAULT 'Actif',"
            "  prix_heure_actuel REAL NOT NULL"
            ")"),

        // ── Tarifs profs historique ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS tarifs_profs_historique ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  prof_id INTEGER REFERENCES professeurs(id),"
            "  nouveau_prix REAL NOT NULL,"
            "  date_changement TEXT DEFAULT (datetime('now'))"
            ")"),

        // ── Élèves ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS eleves ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  prenom TEXT NOT NULL,"
            "  telephone TEXT,"
            "  adresse TEXT,"
            "  date_naissance TEXT,"
            "  categorie TEXT NOT NULL,"
            "  classe_id INTEGER REFERENCES classes(id)"
            ")"),

        // ── Matières ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS matieres ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  niveau_id INTEGER REFERENCES niveaux(id)"
            ")"),

        // ── Équipements ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS equipements ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL UNIQUE"
            ")"),

        // ── Séances ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS seances ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  matiere_id INTEGER REFERENCES matieres(id),"
            "  prof_id INTEGER REFERENCES professeurs(id),"
            "  salle_id INTEGER REFERENCES salles(id),"
            "  classe_id INTEGER REFERENCES classes(id),"
            "  date_heure_debut TEXT NOT NULL,"
            "  duree_minutes INTEGER NOT NULL DEFAULT 60,"
            "  type_seance TEXT DEFAULT 'Cours'"
            ")"),

        // ── Participations ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS participations ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  seance_id INTEGER REFERENCES seances(id) ON DELETE CASCADE,"
            "  eleve_id INTEGER REFERENCES eleves(id),"
            "  statut TEXT DEFAULT 'Présent',"
            "  note REAL,"
            "  est_invite INTEGER DEFAULT 0"
            ")"),

        // ── Paiements mensualités ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS paiements_mensualites ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  eleve_id INTEGER REFERENCES eleves(id),"
            "  montant_paye REAL NOT NULL,"
            "  date_paiement TEXT DEFAULT (date('now')),"
            "  mois_concerne INTEGER NOT NULL,"
            "  annee_concernee INTEGER NOT NULL"
            ")"),

        // ── Paiements personnel ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS paiements_personnel ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  personnel_id INTEGER NOT NULL REFERENCES professeurs(id) ON DELETE CASCADE,"
            "  mois INTEGER NOT NULL CHECK(mois >= 1 AND mois <= 12),"
            "  annee INTEGER NOT NULL CHECK(annee >= 2000),"
            "  somme_due REAL NOT NULL DEFAULT 0.0,"
            "  somme_payee REAL NOT NULL DEFAULT 0.0,"
            "  date_modification TEXT NOT NULL,"
            "  UNIQUE(personnel_id, mois, annee)"
            ")"),

        // ── Projets ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS projets ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  description TEXT,"
            "  objectif_financier REAL,"
            "  statut TEXT DEFAULT 'En cours'"
            ")"),

        // ── Donateurs ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS donateurs ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT,"
            "  telephone TEXT,"
            "  adresse TEXT"
            ")"),

        // ── Dons ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS dons ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  donateur_id INTEGER REFERENCES donateurs(id),"
            "  projet_id INTEGER REFERENCES projets(id),"
            "  montant REAL NOT NULL,"
            "  date_don TEXT DEFAULT (date('now'))"
            ")"),
    };

    for (const auto& sql : statements)
        execStatement(db, sql);

    qInfo() << "[DatabaseManager] Schema created / verified –"
            << statements.size() << "tables.";

    // ── Migrations incrémentales ──
    runMigrations(db);
}

// Ajoute les colonnes manquantes sur une base existante (idempotent).
void DatabaseManager::runMigrations(QSqlDatabase& db)
{
    // Helper : vérifie si une colonne existe dans une table via PRAGMA table_info.
    auto columnExists = [&](const QString& table, const QString& column) -> bool {
        QSqlQuery q(db);
        q.prepare(QStringLiteral("PRAGMA table_info(%1)").arg(table));
        if (!q.exec()) return false;
        while (q.next()) {
            if (q.value(1).toString() == column) return true;
        }
        return false;
    };

    // Migration 1 : ajout de date_naissance dans eleves
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("date_naissance"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE eleves ADD COLUMN date_naissance TEXT"));
        qInfo() << "[DatabaseManager] Migration: added column eleves.date_naissance";
    }

    // Migration 2-7 : ajout des nouvelles colonnes dans professeurs
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("poste"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN poste TEXT DEFAULT 'Enseignant'"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.poste";
    }
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("specialite"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN specialite TEXT"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.specialite";
    }
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("mode_paie"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN mode_paie TEXT DEFAULT 'Heure'"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.mode_paie";
    }
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("valeur_base"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN valeur_base REAL DEFAULT 25.0"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.valeur_base";
    }
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("paye_pendant_vacances"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN paye_pendant_vacances INTEGER DEFAULT 1"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.paye_pendant_vacances";
    }
    if (!columnExists(QStringLiteral("professeurs"), QStringLiteral("heures_travalies"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE professeurs ADD COLUMN heures_travalies INTEGER DEFAULT 0"));
        qInfo() << "[DatabaseManager] Migration: added column professeurs.heures_travalies";
    }
}

void DatabaseManager::seedInitialData(QSqlDatabase& db)
{
    // Guard: only seed when the niveaux table is empty.
    QSqlQuery check(db);
    check.exec(QStringLiteral("SELECT COUNT(*) FROM niveaux"));
    if (check.next() && check.value(0).toInt() > 0)
        return;

    qInfo() << "[DatabaseManager] Seeding initial reference data...";

    // ── Niveaux ──
    for (int i = 1; i <= 5; ++i) {
        execStatement(db,
            QStringLiteral("INSERT INTO niveaux (nom) VALUES ('Niveau %1')").arg(i));
    }

    // ── Salles ──
    const QStringList salles {
        QStringLiteral("INSERT INTO salles (nom, capacite_chaises, equipement) "
                        "VALUES ('Salle A1', 30, 'Tableau Blanc, Projecteur')"),
        QStringLiteral("INSERT INTO salles (nom, capacite_chaises, equipement) "
                        "VALUES ('Salle A2', 25, 'Tableau Blanc, WiFi')"),
        QStringLiteral("INSERT INTO salles (nom, capacite_chaises, equipement) "
                        "VALUES ('Salle B1', 40, 'Tableau Digital, Projecteur, Système Audio')"),
        QStringLiteral("INSERT INTO salles (nom, capacite_chaises, equipement) "
                        "VALUES ('Labo Sciences', 20, 'Tableau Blanc, WiFi')"),
    };
    for (const auto& sql : salles)
        execStatement(db, sql);

    // ── Classes (a few per level) ──
    const QStringList classes {
        // Niveau 1
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('1A', 1)"),
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('1B', 1)"),
        // Niveau 2
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('2A', 2)"),
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('2B', 2)"),
        // Niveau 3
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('3A', 3)"),
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('3B', 3)"),
        // Niveau 4
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('4A', 4)"),
        // Niveau 5
        QStringLiteral("INSERT INTO classes (nom, niveau_id) VALUES ('5A', 5)"),
    };
    for (const auto& sql : classes)
        execStatement(db, sql);

    // ── Équipements ──
    const QStringList equipements {
        QStringLiteral("INSERT INTO equipements (nom) VALUES ('Projecteur')"),
        QStringLiteral("INSERT INTO equipements (nom) VALUES ('Tableau Blanc')"),
        QStringLiteral("INSERT INTO equipements (nom) VALUES ('Tableau Digital')"),
        QStringLiteral("INSERT INTO equipements (nom) VALUES ('WiFi')"),
        QStringLiteral("INSERT INTO equipements (nom) VALUES ('Système Audio')"),
    };
    for (const auto& sql : equipements)
        execStatement(db, sql);

    qInfo() << "[DatabaseManager] Seed data inserted.";
}
