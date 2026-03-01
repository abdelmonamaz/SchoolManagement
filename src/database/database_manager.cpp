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
            "CREATE TABLE IF NOT EXISTS matiere_examens ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  matiere_id INTEGER NOT NULL REFERENCES matieres(id) ON DELETE CASCADE,"
            "  titre TEXT NOT NULL"
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
    if (!tableExists(QStringLiteral("matiere_examens"))) {
        execStatement(db, QStringLiteral(
            "CREATE TABLE IF NOT EXISTS matiere_examens ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  matiere_id INTEGER NOT NULL REFERENCES matieres(id) ON DELETE CASCADE,"
            "  titre TEXT NOT NULL"
            ")"));
        qInfo() << "[DatabaseManager] Migration 16: created table matiere_examens";
    }

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
