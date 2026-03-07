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
            "  sexe TEXT DEFAULT 'M',"
            "  cin TEXT"
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
            "  sexe TEXT DEFAULT 'M',"
            "  telephone TEXT,"
            "  adresse TEXT,"
            "  date_naissance TEXT,"
            "  nom_parent TEXT,"
            "  tel_parent TEXT,"
            "  commentaire TEXT,"
            "  categorie TEXT NOT NULL,"
            "  classe_id INTEGER REFERENCES classes(id)"
            ")"),

        // ── Inscriptions Élèves (Historique) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS inscriptions_eleves ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  eleve_id INTEGER REFERENCES eleves(id) ON DELETE CASCADE,"
            "  annee_scolaire TEXT NOT NULL,"
            "  niveau_id INTEGER REFERENCES niveaux(id),"
            "  resultat TEXT DEFAULT 'En cours',"
            "  frais_inscription_paye INTEGER DEFAULT 0,"
            "  montant_inscription REAL DEFAULT 50.0,"
            "  date_inscription TEXT DEFAULT (date('now')),"
            "  justificatif_path TEXT"
            ")"),

        // ── Matières ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS matieres ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  niveau_id INTEGER REFERENCES niveaux(id),"
            "  nombre_seances INTEGER DEFAULT 0,"
            "  duree_seance_minutes INTEGER DEFAULT 60"
            ")"),

        // ── Évaluations configurables par matière ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS type_examen ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  titre TEXT NOT NULL UNIQUE"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS matiere_examens ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  matiere_id INTEGER NOT NULL REFERENCES matieres(id) ON DELETE CASCADE,"
            "  type_examen_id INTEGER NOT NULL REFERENCES type_examen(id) ON DELETE CASCADE"
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
            "  type_seance TEXT DEFAULT 'Cours',"
            "  presence_valide INTEGER DEFAULT 0"
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
            "  annee_concernee INTEGER NOT NULL,"
            "  justificatif_path TEXT"
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
            "  date_paiement TEXT,"
            "  justificatif_path TEXT,"
            "  UNIQUE(personnel_id, mois, annee)"
            ")"),

        // ── Projets ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS projets ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom TEXT NOT NULL,"
            "  description TEXT,"
            "  objectif_financier REAL,"
            "  statut TEXT DEFAULT 'En cours',"
            "  date_debut TEXT,"
            "  date_fin TEXT"
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

        // ── Dépenses ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS depenses ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  libelle TEXT NOT NULL,"
            "  montant REAL NOT NULL,"
            "  date TEXT DEFAULT (date('now')),"
            "  categorie TEXT DEFAULT 'Autre',"
            "  justificatif_path TEXT,"
            "  notes TEXT"
            ")"),

        // ── Tarifs mensualités (par catégorie et année scolaire) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS tarifs_mensualites ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  categorie TEXT NOT NULL,"
            "  annee_scolaire TEXT NOT NULL,"
            "  montant REAL NOT NULL DEFAULT 0.0,"
            "  UNIQUE(categorie, annee_scolaire)"
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

        // ── Contrats (données variables du personnel) ──
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS contrats ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  personnel_id INTEGER NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,"
            "  poste TEXT DEFAULT 'Enseignant',"
            "  specialite TEXT,"
            "  mode_paie TEXT DEFAULT 'Heure',"
            "  valeur_base REAL DEFAULT 25.0,"
            "  date_debut TEXT NOT NULL,"
            "  date_fin TEXT,"
            "  jours_travail INTEGER DEFAULT 31"
            ")"),

        QStringLiteral(
            "CREATE INDEX IF NOT EXISTS idx_contrats_personnel ON contrats(personnel_id)"),

        QStringLiteral(
            "CREATE INDEX IF NOT EXISTS idx_contrats_dates ON contrats(date_debut, date_fin)"),
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

    // Migration 10 : migrer les données personnel vers contrats
    if (tableExists(QStringLiteral("contrats")) && columnExists(personnelTable, QStringLiteral("poste"))) {
        QSqlQuery checkContrats(db);
        checkContrats.exec(QStringLiteral("SELECT COUNT(*) FROM contrats"));
        bool contratsEmpty = (!checkContrats.next() || checkContrats.value(0).toInt() == 0);

        if (contratsEmpty) {
            QSqlQuery checkPersonnel(db);
            checkPersonnel.exec(QStringLiteral("SELECT COUNT(*) FROM %1").arg(personnelTable));
            bool hasPersonnel = (checkPersonnel.next() && checkPersonnel.value(0).toInt() > 0);

            if (hasPersonnel) {
                qInfo() << "[DatabaseManager] Migration 10: migrating personnel data to contrats...";
                execStatement(db, QStringLiteral(
                    "INSERT INTO contrats (personnel_id, poste, specialite, mode_paie, valeur_base, date_debut) "
                    "SELECT id, COALESCE(poste, 'Enseignant'), specialite, "
                    "COALESCE(mode_paie, 'Heure'), COALESCE(valeur_base, 25.0), date('now') "
                    "FROM %1").arg(personnelTable));
                qInfo() << "[DatabaseManager] Migration 10: personnel data migrated to contrats.";
            }
        }
    }

    // Migration 11 : ajout de la colonne sexe dans personnel
    if (!columnExists(personnelTable, QStringLiteral("sexe"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE %1 ADD COLUMN sexe TEXT DEFAULT 'M'").arg(personnelTable));
        qInfo() << "[DatabaseManager] Migration 11: added column" << personnelTable << ".sexe";
    }

    // Migration 12 : ajout des colonnes dans eleves
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("sexe"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN sexe TEXT DEFAULT 'M'"));
    }
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("nom_parent"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN nom_parent TEXT"));
    }
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("tel_parent"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN tel_parent TEXT"));
    }
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("commentaire"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN commentaire TEXT"));
    }
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("categorie"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN categorie TEXT DEFAULT 'Jeune'"));
    }
    qInfo() << "[DatabaseManager] Migration 12: added new columns to eleves";

    // Migration 13 : création de la table inscriptions_eleves si elle n'existe pas (déjà fait dans createTables mais pour la sécurité)
    if (!tableExists(QStringLiteral("inscriptions_eleves"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS inscriptions_eleves ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  eleve_id INTEGER REFERENCES eleves(id) ON DELETE CASCADE,"
            "  annee_scolaire TEXT NOT NULL,"
            "  niveau_id INTEGER REFERENCES niveaux(id),"
            "  resultat TEXT DEFAULT 'En cours',"
            "  frais_inscription_paye INTEGER DEFAULT 0,"
            "  montant_inscription REAL DEFAULT 50.0,"
            "  date_inscription TEXT DEFAULT (date('now')),"
            "  justificatif_path TEXT"
            ")"));
        qInfo() << "[DatabaseManager] Migration 13: created inscriptions_eleves table";
    }

    // Migration 14 : ajout de presence_valide dans seances
    if (!columnExists(QStringLiteral("seances"), QStringLiteral("presence_valide"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE seances ADD COLUMN presence_valide INTEGER DEFAULT 0"));
        qInfo() << "[DatabaseManager] Migration 14: added column seances.presence_valide";
    }

    // Migration 15 : ajout des nouveaux champs dans matieres
    if (!columnExists(QStringLiteral("matieres"), QStringLiteral("nombre_seances"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE matieres ADD COLUMN nombre_seances INTEGER DEFAULT 0"));
        qInfo() << "[DatabaseManager] Migration 15a: added column matieres.nombre_seances";
    }
    if (!columnExists(QStringLiteral("matieres"), QStringLiteral("duree_seance_minutes"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE matieres ADD COLUMN duree_seance_minutes INTEGER DEFAULT 60"));
        qInfo() << "[DatabaseManager] Migration 15b: added column matieres.duree_seance_minutes";
    }

    // Migration 16 : création de la table matiere_examens
    // Migration 24 : création de la table type_examen et adaptation de matiere_examens
    if (!tableExists(QStringLiteral("type_examen"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS type_examen ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  titre TEXT NOT NULL UNIQUE"
            ")"));
        qInfo() << "[DatabaseManager] Migration 24a: created table type_examen";
        
        // Mettre à jour matiere_examens pour utiliser type_examen_id si elle existait avant
        if (tableExists(QStringLiteral("matiere_examens"))) {
            if (columnExists(QStringLiteral("matiere_examens"), QStringLiteral("titre"))) {
                // Créer les types existants
                execStatement(db, QStringLiteral("INSERT OR IGNORE INTO type_examen (titre) SELECT DISTINCT titre FROM matiere_examens"));
                
                // Ajouter la nouvelle colonne
                execStatement(db, QStringLiteral("ALTER TABLE matiere_examens ADD COLUMN type_examen_id INTEGER REFERENCES type_examen(id)"));
                
                // Mettre à jour la colonne
                execStatement(db, QStringLiteral("UPDATE matiere_examens SET type_examen_id = (SELECT id FROM type_examen WHERE type_examen.titre = matiere_examens.titre)"));
            }
        } else {
            execStatement(db, QStringLiteral(
                "CREATE TABLE IF NOT EXISTS matiere_examens ("
                "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
                "  matiere_id INTEGER NOT NULL REFERENCES matieres(id) ON DELETE CASCADE,"
                "  type_examen_id INTEGER NOT NULL REFERENCES type_examen(id) ON DELETE CASCADE"
                ")"));
        }
        qInfo() << "[DatabaseManager] Migration 24b: adapted matiere_examens";
    }

    // Migration 25 : Ajout global des colonnes de soft-delete et audit (valide, date_modification, etc.)
    QStringList tablesToUpdate = {
        "salles", "niveaux", "classes", "personnel", "eleves", "matieres", 
        "type_examen", "matiere_examens", "equipements", "seances", "participations",
        "paiements_mensualites", "paiements_personnel", "projets", "donateurs", "dons",
        "depenses", "tarifs_mensualites", "contrats", "inscriptions_eleves"
    };

    for (const QString& table : tablesToUpdate) {
        if (tableExists(table)) {
            if (!columnExists(table, "valide")) {
                execStatement(db, QString("ALTER TABLE %1 ADD COLUMN valide INTEGER DEFAULT 1").arg(table));
            }
            if (!columnExists(table, "date_modification")) {
                execStatement(db, QString("ALTER TABLE %1 ADD COLUMN date_modification TEXT").arg(table));
            }
            if (!columnExists(table, "date_invalidation")) {
                execStatement(db, QString("ALTER TABLE %1 ADD COLUMN date_invalidation TEXT").arg(table));
            }
        }
    }
    qInfo() << "[DatabaseManager] Migration 25: checked audit columns for all tables.";

    // Migration 17 : ajout de jours_travail dans contrats (bitmask Lun-Ven, défaut 31)
    if (!columnExists(QStringLiteral("contrats"), QStringLiteral("jours_travail"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE contrats ADD COLUMN jours_travail INTEGER DEFAULT 31"));
        qInfo() << "[DatabaseManager] Migration 17: added column contrats.jours_travail";
    }

    // Migration 19 : champs étendus donateurs (Décret-loi 2011-88 Tunisie)
    if (!columnExists(QStringLiteral("donateurs"), QStringLiteral("type_personne"))) {
        execStatement(db, QStringLiteral("ALTER TABLE donateurs ADD COLUMN type_personne TEXT DEFAULT 'Physique'"));
        qInfo() << "[DatabaseManager] Migration 19a: added donateurs.type_personne";
    }
    if (!columnExists(QStringLiteral("donateurs"), QStringLiteral("cin"))) {
        execStatement(db, QStringLiteral("ALTER TABLE donateurs ADD COLUMN cin TEXT"));
        qInfo() << "[DatabaseManager] Migration 19b: added donateurs.cin";
    }
    if (!columnExists(QStringLiteral("donateurs"), QStringLiteral("raison_sociale"))) {
        execStatement(db, QStringLiteral("ALTER TABLE donateurs ADD COLUMN raison_sociale TEXT"));
        qInfo() << "[DatabaseManager] Migration 19c: added donateurs.raison_sociale";
    }
    if (!columnExists(QStringLiteral("donateurs"), QStringLiteral("matricule_fiscal"))) {
        execStatement(db, QStringLiteral("ALTER TABLE donateurs ADD COLUMN matricule_fiscal TEXT"));
        qInfo() << "[DatabaseManager] Migration 19d: added donateurs.matricule_fiscal";
    }
    if (!columnExists(QStringLiteral("donateurs"), QStringLiteral("representant_legal"))) {
        execStatement(db, QStringLiteral("ALTER TABLE donateurs ADD COLUMN representant_legal TEXT"));
        qInfo() << "[DatabaseManager] Migration 19e: added donateurs.representant_legal";
    }
    // Migration 19 : champs étendus dons (nature + justificatif)
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("nature_don"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN nature_don TEXT DEFAULT 'Numéraire'"));
        qInfo() << "[DatabaseManager] Migration 19f: added dons.nature_don";
    }
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("mode_paiement"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN mode_paiement TEXT DEFAULT 'Espèces'"));
        qInfo() << "[DatabaseManager] Migration 19g: added dons.mode_paiement";
    }
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("description_materiel"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN description_materiel TEXT"));
        qInfo() << "[DatabaseManager] Migration 19h: added dons.description_materiel";
    }
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("valeur_estimee"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN valeur_estimee REAL DEFAULT 0.0"));
        qInfo() << "[DatabaseManager] Migration 19i: added dons.valeur_estimee";
    }
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("etat_materiel"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN etat_materiel TEXT DEFAULT 'Neuf'"));
        qInfo() << "[DatabaseManager] Migration 19j: added dons.etat_materiel";
    }
    if (!columnExists(QStringLiteral("dons"), QStringLiteral("justificatif_path"))) {
        execStatement(db, QStringLiteral("ALTER TABLE dons ADD COLUMN justificatif_path TEXT"));
        qInfo() << "[DatabaseManager] Migration 19k: added dons.justificatif_path";
    }

    // Migration 20 : ajout du justificatif pour les paiements
    if (!columnExists(QStringLiteral("paiements_mensualites"), QStringLiteral("justificatif_path"))) {
        execStatement(db, QStringLiteral("ALTER TABLE paiements_mensualites ADD COLUMN justificatif_path TEXT"));
        qInfo() << "[DatabaseManager] Migration 20: added paiements_mensualites.justificatif_path";
    }

    // Migration 21 : ajout du justificatif pour les inscriptions
    if (!columnExists(QStringLiteral("inscriptions_eleves"), QStringLiteral("justificatif_path"))) {
        execStatement(db, QStringLiteral("ALTER TABLE inscriptions_eleves ADD COLUMN justificatif_path TEXT"));
        qInfo() << "[DatabaseManager] Migration 21: added inscriptions_eleves.justificatif_path";
    }

    // Migration 22 : ajout de date_paiement et justificatif_path pour paiements_personnel
    if (!columnExists(QStringLiteral("paiements_personnel"), QStringLiteral("date_paiement"))) {
        execStatement(db, QStringLiteral("ALTER TABLE paiements_personnel ADD COLUMN date_paiement TEXT"));
        qInfo() << "[DatabaseManager] Migration 22a: added paiements_personnel.date_paiement";
    }
    if (!columnExists(QStringLiteral("paiements_personnel"), QStringLiteral("justificatif_path"))) {
        execStatement(db, QStringLiteral("ALTER TABLE paiements_personnel ADD COLUMN justificatif_path TEXT"));
        qInfo() << "[DatabaseManager] Migration 22b: added paiements_personnel.justificatif_path";
    }

    // Migration 23 : ajout de date_debut et date_fin dans projets
    if (!columnExists(QStringLiteral("projets"), QStringLiteral("date_debut"))) {
        execStatement(db, QStringLiteral("ALTER TABLE projets ADD COLUMN date_debut TEXT"));
        qInfo() << "[DatabaseManager] Migration 23a: added projets.date_debut";
    }
    if (!columnExists(QStringLiteral("projets"), QStringLiteral("date_fin"))) {
        execStatement(db, QStringLiteral("ALTER TABLE projets ADD COLUMN date_fin TEXT"));
        qInfo() << "[DatabaseManager] Migration 23b: added projets.date_fin";
    }

    // Migration 18 : création de la table tarifs_mensualites + données initiales
    if (!tableExists(QStringLiteral("tarifs_mensualites"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS tarifs_mensualites ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  categorie TEXT NOT NULL,"
            "  annee_scolaire TEXT NOT NULL,"
            "  montant REAL NOT NULL DEFAULT 0.0,"
            "  UNIQUE(categorie, annee_scolaire)"
            ")"));
        qInfo() << "[DatabaseManager] Migration 18: created table tarifs_mensualites";
    }
    // Migration 20 : création de la table depenses
    if (!tableExists(QStringLiteral("depenses"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS depenses ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  libelle TEXT NOT NULL,"
            "  montant REAL NOT NULL,"
            "  date TEXT DEFAULT (date('now')),"
            "  categorie TEXT DEFAULT 'Autre',"
            "  justificatif_path TEXT,"
            "  notes TEXT"
            ")"));
        qInfo() << "[DatabaseManager] Migration 20: created table depenses";
    }

    // Insérer les tarifs par défaut pour les années scolaires courantes (idempotent)
    {
        QSqlQuery ins(db);
        ins.prepare(QStringLiteral(
            "INSERT OR IGNORE INTO tarifs_mensualites (categorie, annee_scolaire, montant) VALUES (?, ?, ?)"));
        const QList<std::tuple<QString,QString,double>> defaults = {
            {"Jeune",  "2023-2024", 150.0},
            {"Adulte", "2023-2024", 250.0},
            {"Jeune",  "2024-2025", 150.0},
            {"Adulte", "2024-2025", 250.0},
            {"Jeune",  "2025-2026", 150.0},
            {"Adulte", "2025-2026", 250.0},
            {"Jeune",  "2026-2027", 150.0},
            {"Adulte", "2026-2027", 250.0},
        };
        for (const auto& [cat, annee, montant] : defaults) {
            ins.addBindValue(cat);
            ins.addBindValue(annee);
            ins.addBindValue(montant);
            ins.exec();
        }
    }

    // ── Migration 26 : table de configuration de l'association ──
    if (!tableExists(QStringLiteral("association_config"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS association_config ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  nom_association TEXT NOT NULL DEFAULT 'Ez-Zaytouna',"
            "  adresse TEXT,"
            "  exercice_debut TEXT DEFAULT '01-01',"
            "  exercice_fin TEXT DEFAULT '12-31',"
            "  app_initialized INTEGER DEFAULT 0,"
            "  date_modification TEXT"
            ")"));
        execStatement(db, QStringLiteral(
            "INSERT INTO association_config (nom_association, app_initialized) "
            "VALUES ('Ez-Zaytouna', 0)"));
        qInfo() << "[DatabaseManager] Migration 26: created table association_config";
    }

    // ── Migration 27 : table annees_scolaires (remplace le champ TEXT annee_scolaire) ──
    if (!tableExists(QStringLiteral("annees_scolaires"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS annees_scolaires ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  libelle TEXT NOT NULL,"
            "  date_debut TEXT,"
            "  date_fin TEXT,"
            "  tarif_jeune REAL DEFAULT 0.0,"
            "  tarif_adulte REAL DEFAULT 0.0,"
            "  frais_inscription_jeune REAL DEFAULT 0.0,"
            "  frais_inscription_adulte REAL DEFAULT 0.0,"
            "  statut TEXT DEFAULT 'Active',"
            "  valide INTEGER DEFAULT 1,"
            "  date_modification TEXT,"
            "  date_invalidation TEXT,"
            "  UNIQUE(libelle)"
            ")"));
        qInfo() << "[DatabaseManager] Migration 27: created table annees_scolaires";
    }

    // ── Migration 28 : table de liaison niveaux <-> annees_scolaires ──
    if (!tableExists(QStringLiteral("niveaux_actifs_par_annee"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS niveaux_actifs_par_annee ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  annee_scolaire_id INTEGER NOT NULL REFERENCES annees_scolaires(id) ON DELETE CASCADE,"
            "  niveau_id INTEGER NOT NULL REFERENCES niveaux(id) ON DELETE CASCADE,"
            "  valide INTEGER DEFAULT 1,"
            "  date_modification TEXT,"
            "  date_invalidation TEXT,"
            "  UNIQUE(annee_scolaire_id, niveau_id)"
            ")"));
        qInfo() << "[DatabaseManager] Migration 28: created table niveaux_actifs_par_annee";
    }

    // ── Migration 29 : ajout de parent_level_id dans niveaux (hiérarchie) ──
    if (!columnExists(QStringLiteral("niveaux"), QStringLiteral("parent_level_id"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE niveaux ADD COLUMN parent_level_id INTEGER REFERENCES niveaux(id)"));
        qInfo() << "[DatabaseManager] Migration 29: added column niveaux.parent_level_id";
    }

    // ── Migration 30 : ajout de cin_eleve et cin_parent dans eleves ──
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("cin_eleve"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN cin_eleve TEXT"));
        qInfo() << "[DatabaseManager] Migration 30a: added column eleves.cin_eleve";
    }
    if (!columnExists(QStringLiteral("eleves"), QStringLiteral("cin_parent"))) {
        execStatement(db, QStringLiteral("ALTER TABLE eleves ADD COLUMN cin_parent TEXT"));
        qInfo() << "[DatabaseManager] Migration 30b: added column eleves.cin_parent";
    }

    // ── Migration 31 : ajout de annee_scolaire_id et classe_id dans inscriptions_eleves ──
    if (!columnExists(QStringLiteral("inscriptions_eleves"), QStringLiteral("annee_scolaire_id"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE inscriptions_eleves ADD COLUMN annee_scolaire_id INTEGER REFERENCES annees_scolaires(id)"));
        // Populate annee_scolaire_id from existing annee_scolaire text
        execStatement(db, QStringLiteral(
            "UPDATE inscriptions_eleves SET annee_scolaire_id = ("
            "  SELECT a.id FROM annees_scolaires a WHERE a.libelle = inscriptions_eleves.annee_scolaire AND a.valide = 1 LIMIT 1"
            ")"));
        qInfo() << "[DatabaseManager] Migration 31a: added column inscriptions_eleves.annee_scolaire_id";
    }
    if (!columnExists(QStringLiteral("inscriptions_eleves"), QStringLiteral("classe_id"))) {
        execStatement(db, QStringLiteral(
            "ALTER TABLE inscriptions_eleves ADD COLUMN classe_id INTEGER REFERENCES classes(id)"));
        // Migrate existing class assignment from eleves.classe_id to active-year inscription
        execStatement(db, QStringLiteral(
            "UPDATE inscriptions_eleves SET classe_id = ("
            "  SELECT e.classe_id FROM eleves e WHERE e.id = inscriptions_eleves.eleve_id AND e.classe_id IS NOT NULL"
            ") WHERE annee_scolaire = (SELECT libelle FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"
            " AND valide = 1"));
        qInfo() << "[DatabaseManager] Migration 31b: added column inscriptions_eleves.classe_id";
    }

    // ── Migration 32 : suppression de inscriptions_eleves.annee_scolaire (remplacé par annee_scolaire_id) ──
    if (columnExists(QStringLiteral("inscriptions_eleves"), QStringLiteral("annee_scolaire"))) {
        execStatement(db, QStringLiteral("ALTER TABLE inscriptions_eleves DROP COLUMN annee_scolaire"));
        qInfo() << "[DatabaseManager] Migration 32: dropped column inscriptions_eleves.annee_scolaire";
    }

    // ── Migration 33 : nettoyage personnel (suppression colonnes migrées vers contrats, ajout cin) ──
    if (!columnExists(QStringLiteral("personnel"), QStringLiteral("cin"))) {
        execStatement(db, QStringLiteral("ALTER TABLE personnel ADD COLUMN cin TEXT"));
        qInfo() << "[DatabaseManager] Migration 33a: added column personnel.cin";
    }
    for (const QString& col : {QStringLiteral("mode_paie"), QStringLiteral("specialite"),
                                QStringLiteral("valeur_base"), QStringLiteral("paye_pendant_vacances"),
                                QStringLiteral("heures_travalies"), QStringLiteral("statut"),
                                QStringLiteral("poste"), QStringLiteral("prix_heure_actuel")}) {
        if (columnExists(QStringLiteral("personnel"), col)) {
            execStatement(db, QStringLiteral("ALTER TABLE personnel DROP COLUMN ") + col);
            qInfo() << "[DatabaseManager] Migration 33: dropped column personnel." << col;
        }
    }

    // ── Migration 34 : ajout age_passage_adulte dans association_config ──
    if (!columnExists(QStringLiteral("association_config"), QStringLiteral("age_passage_adulte"))) {
        execStatement(db, QStringLiteral("ALTER TABLE association_config ADD COLUMN age_passage_adulte INTEGER DEFAULT 12"));
        qInfo() << "[DatabaseManager] Migration 34: added column association_config.age_passage_adulte";
    }
}

