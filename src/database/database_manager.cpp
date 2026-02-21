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

        // ── Personnel ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS personnel ("
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
            "  prof_id INTEGER REFERENCES personnel(id),"
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

        // ── Séances (table de base, les détails sont dans cours/examens/events) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS seances ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  salle_id INTEGER REFERENCES salles(id),"
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
            "  personnel_id INTEGER NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,"
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

        // ── Cours (sous-table de séances) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS cours ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  seance_id INTEGER NOT NULL UNIQUE REFERENCES seances(id) ON DELETE CASCADE,"
            "  matiere_id INTEGER NOT NULL,"
            "  prof_id INTEGER NOT NULL,"
            "  classe_id INTEGER NOT NULL"
            ")"),

        // ── Examens (sous-table de séances) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS examens ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  seance_id INTEGER NOT NULL UNIQUE REFERENCES seances(id) ON DELETE CASCADE,"
            "  matiere_id INTEGER NOT NULL,"
            "  classe_id INTEGER NOT NULL,"
            "  titre TEXT NOT NULL,"
            "  prof_id INTEGER"
            ")"),

        // ── Événements (sous-table de séances) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS events ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  seance_id INTEGER NOT NULL UNIQUE REFERENCES seances(id) ON DELETE CASCADE,"
            "  titre TEXT NOT NULL,"
            "  salle_id INTEGER,"
            "  descriptif TEXT"
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

    // Helper : vérifie si une table existe.
    auto tableExists = [&](const QString& table) -> bool {
        QSqlQuery q(db);
        q.prepare(QStringLiteral("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=?"));
        q.addBindValue(table);
        if (!q.exec() || !q.next()) return false;
        return q.value(0).toInt() > 0;
    };

    // Migration 0 : renommer la table professeurs → personnel (pour les bases existantes)
    if (tableExists(QStringLiteral("professeurs")) && !tableExists(QStringLiteral("personnel"))) {
        execStatement(db, QStringLiteral("ALTER TABLE professeurs RENAME TO personnel"));
        qInfo() << "[DatabaseManager] Migration: renamed table professeurs → personnel";
    }

    // Déterminer le nom de la table personnel (peut être 'professeurs' si la migration a échoué)
    QString personnelTable = tableExists(QStringLiteral("personnel"))
        ? QStringLiteral("personnel") : QStringLiteral("professeurs");

    // Migration 1 : ajout de date_naissance dans eleves
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("date_naissance"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE eleves ADD COLUMN date_naissance TEXT"));
        qInfo() << "[DatabaseManager] Migration: added column eleves.date_naissance";
    }

    // Migration 2-7 : ajout des nouvelles colonnes dans personnel
    if (!columnExists(personnelTable, QStringLiteral("poste"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN poste TEXT DEFAULT 'Enseignant'").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".poste";
    }
    if (!columnExists(personnelTable, QStringLiteral("specialite"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN specialite TEXT").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".specialite";
    }
    if (!columnExists(personnelTable, QStringLiteral("mode_paie"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN mode_paie TEXT DEFAULT 'Heure'").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".mode_paie";
    }
    if (!columnExists(personnelTable, QStringLiteral("valeur_base"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN valeur_base REAL DEFAULT 25.0").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".valeur_base";
    }
    if (!columnExists(personnelTable, QStringLiteral("paye_pendant_vacances"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN paye_pendant_vacances INTEGER DEFAULT 1").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".paye_pendant_vacances";
    }
    if (!columnExists(personnelTable, QStringLiteral("heures_travalies"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN heures_travalies INTEGER DEFAULT 0").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration: added column" << personnelTable << ".heures_travalies";
    }

    // Migration 8 : ajout de titre dans seances
    if (!columnExists(QStringLiteral("seances"), QStringLiteral("titre"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE seances ADD COLUMN titre TEXT"));
        qInfo() << "[DatabaseManager] Migration: added column seances.titre";
    }

    // Migration 9 : migrer les données existantes vers les sous-tables cours/examens/events
    // On vérifie si la migration a déjà été faite en regardant si les sous-tables contiennent des données
    if (tableExists(QStringLiteral("cours"))) {
        QSqlQuery checkCours(db);
        checkCours.exec(QStringLiteral("SELECT COUNT(*) FROM cours"));
        bool coursEmpty = (!checkCours.next() || checkCours.value(0).toInt() == 0);

        if (coursEmpty) {
            // Vérifier s'il y a des données à migrer dans seances
            QSqlQuery checkSeances(db);
            checkSeances.exec(QStringLiteral("SELECT COUNT(*) FROM seances"));
            bool hasData = (checkSeances.next() && checkSeances.value(0).toInt() > 0);

            if (hasData) {
                qInfo() << "[DatabaseManager] Migration 9: migrating seances data to sub-tables...";

                execStatement(db, QStringLiteral(
                    "INSERT INTO cours (seance_id, matiere_id, prof_id, classe_id) "
                    "SELECT id, COALESCE(matiere_id, 0), COALESCE(prof_id, 0), COALESCE(classe_id, 0) "
                    "FROM seances WHERE type_seance = 'Cours'"));

                execStatement(db, QStringLiteral(
                    "INSERT INTO examens (seance_id, matiere_id, classe_id, titre, prof_id) "
                    "SELECT id, COALESCE(matiere_id, 0), COALESCE(classe_id, 0), COALESCE(titre, ''), prof_id "
                    "FROM seances WHERE type_seance = 'Examen'"));

                execStatement(db, QStringLiteral(
                    "INSERT INTO events (seance_id, titre, salle_id, descriptif) "
                    "SELECT id, COALESCE(titre, ''), salle_id, NULL "
                    "FROM seances WHERE type_seance = 'Événement'"));

                qInfo() << "[DatabaseManager] Migration 9: data migrated to sub-tables.";
            }
        }
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
