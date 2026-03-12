#include "repositories/sqlite/sqlite_setup_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

// ─── SqliteAssociationRepository ──────────────────────────────────────────────

SqliteAssociationRepository::SqliteAssociationRepository(const QString& connectionName)
    : m_connectionName(connectionName)
{
}

QVariantMap SqliteAssociationRepository::getConfig()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT app_initialized, nom_association, adresse, "
        "       exercice_debut, exercice_fin, age_passage_adulte, langue "
        "FROM association_config LIMIT 1"));

    if (!q.next()) return {};

    const bool init = q.value(0).toInt() == 1;
    const int  age  = q.value(5).toInt();
    return {
        {"initialized", init},
        {"associationData", QVariantMap{
            {"nomAssociation",   q.value(1).toString()},
            {"adresse",          q.value(2).toString()},
            {"exerciceDebut",    q.value(3).toString()},
            {"exerciceFin",      q.value(4).toString()},
            {"agePassageAdulte", age > 0 ? age : 12},
            {"langue",           q.value(6).toString()}
        }}
    };
}

Result<bool> SqliteAssociationRepository::saveAssociation(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE association_config SET "
        "  nom_association    = ?, "
        "  adresse            = ?, "
        "  exercice_debut     = ?, "
        "  exercice_fin       = ?, "
        "  age_passage_adulte = ?, "
        "  langue             = ?, "
        "  date_modification  = datetime('now') "
        "WHERE id = (SELECT MIN(id) FROM association_config)"));
    q.addBindValue(data.value("nomAssociation").toString());
    q.addBindValue(data.value("adresse").toString());
    q.addBindValue(data.value("exerciceDebut", "01-01").toString());
    q.addBindValue(data.value("exerciceFin",   "12-31").toString());
    q.addBindValue(data.value("agePassageAdulte", 12).toInt());
    q.addBindValue(data.value("langue", "français").toString());

    if (!q.exec())
        return Result<bool>::error(q.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteAssociationRepository::markInitialized()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (!q.exec(QStringLiteral(
            "UPDATE association_config SET app_initialized = 1, "
            "date_modification = datetime('now') "
            "WHERE id = (SELECT MIN(id) FROM association_config)")))
        return Result<bool>::error(q.lastError().text());
    return Result<bool>::success(true);
}

Result<int> SqliteAssociationRepository::recalculeCategories(int agePassage)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE eleves SET categorie = CASE "
        "  WHEN ("
        "    CAST(strftime('%Y','now') AS INTEGER) - CAST(strftime('%Y', date_naissance) AS INTEGER)"
        "    - CASE WHEN strftime('%m-%d','now') < strftime('%m-%d', date_naissance) THEN 1 ELSE 0 END"
        "  ) < :age THEN 'Jeune' ELSE 'Adulte' "
        "END "
        "WHERE valide = 1 AND date_naissance IS NOT NULL AND date_naissance != ''"));
    q.bindValue(":age", agePassage);

    if (!q.exec())
        return Result<int>::error(q.lastError().text());
    return Result<int>::success(q.numRowsAffected());
}

// ─── SqliteSetupSchoolYearRepository ──────────────────────────────────────────

SqliteSetupSchoolYearRepository::SqliteSetupSchoolYearRepository(const QString& connectionName)
    : m_connectionName(connectionName)
{
}

QVariantMap SqliteSetupSchoolYearRepository::getActiveYearTarifs()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT id, libelle, tarif_jeune, tarif_adulte, "
        "       frais_inscription_jeune, frais_inscription_adulte, "
        "       date_debut, date_fin "
        "FROM annees_scolaires WHERE statut = 'Active' AND valide = 1 LIMIT 1"));
    if (!q.next()) return {};
    return {
        {"id",                     q.value(0).toInt()},
        {"libelle",                q.value(1).toString()},
        {"tarifJeune",             q.value(2).toDouble()},
        {"tarifAdulte",            q.value(3).toDouble()},
        {"fraisInscriptionJeune",  q.value(4).toDouble()},
        {"fraisInscriptionAdulte", q.value(5).toDouble()},
        {"dateDebut",              q.value(6).toString()},
        {"dateFin",                q.value(7).toString()}
    };
}

Result<int> SqliteSetupSchoolYearRepository::upsertAnneeScolaire(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO annees_scolaires "
        "  (libelle, date_debut, date_fin, tarif_jeune, tarif_adulte, "
        "   frais_inscription_jeune, frais_inscription_adulte, statut) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, 'Active') "
        "ON CONFLICT(libelle) DO UPDATE SET "
        "  date_debut               = excluded.date_debut, "
        "  date_fin                 = excluded.date_fin, "
        "  tarif_jeune              = excluded.tarif_jeune, "
        "  tarif_adulte             = excluded.tarif_adulte, "
        "  frais_inscription_jeune  = excluded.frais_inscription_jeune, "
        "  frais_inscription_adulte = excluded.frais_inscription_adulte, "
        "  statut                   = 'Active', "
        "  date_modification        = datetime('now')"));
    q.addBindValue(data.value("libelle").toString());
    q.addBindValue(data.value("dateDebut").toString());
    q.addBindValue(data.value("dateFin").toString());
    q.addBindValue(data.value("tarifJeune",             0.0).toDouble());
    q.addBindValue(data.value("tarifAdulte",            0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionJeune",  0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionAdulte", 0.0).toDouble());

    if (!q.exec())
        return Result<int>::error(q.lastError().text());

    QSqlQuery idQuery(db);
    idQuery.prepare(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE libelle = ? AND valide = 1 LIMIT 1"));
    idQuery.addBindValue(data.value("libelle").toString());
    if (!idQuery.exec() || !idQuery.next())
        return Result<int>::error(QStringLiteral("Impossible de retrouver l'année scolaire créée."));
    return Result<int>::success(idQuery.value(0).toInt());
}

Result<bool> SqliteSetupSchoolYearRepository::linkAllNiveauxToAnnee(int /*anneeId*/)
{
    // niveaux_actifs_par_annee no longer maintained — niveaux.annee_scolaire_id is the canonical FK.
    return Result<bool>::success(true);
}

Result<bool> SqliteSetupSchoolYearRepository::syncTarifs(int anneeId, double tarifJeune, double tarifAdulte)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO tarifs_mensualites (categorie, annee_scolaire_id, montant) VALUES (?, ?, ?)"));
    for (const auto& [cat, montant] : { std::pair<const char*, double>{"Jeune",  tarifJeune},
                                         std::pair<const char*, double>{"Adulte", tarifAdulte} }) {
        q.addBindValue(QLatin1String(cat));
        q.addBindValue(anneeId);
        q.addBindValue(montant);
        if (!q.exec())
            return Result<bool>::error(q.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteSetupSchoolYearRepository::updateActiveTarifs(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE annees_scolaires SET "
        "  tarif_jeune              = ?, "
        "  tarif_adulte             = ?, "
        "  frais_inscription_jeune  = ?, "
        "  frais_inscription_adulte = ?, "
        "  date_modification        = datetime('now') "
        "WHERE statut = 'Active' AND valide = 1"));
    q.addBindValue(data.value("tarifJeune",             0.0).toDouble());
    q.addBindValue(data.value("tarifAdulte",            0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionJeune",  0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionAdulte", 0.0).toDouble());

    if (!q.exec())
        return Result<bool>::error(q.lastError().text());

    // Sync tarifs_mensualites for the active year
    QSqlQuery qId(db);
    qId.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut = 'Active' AND valide = 1 LIMIT 1"));
    if (qId.next()) {
        const int anneeId = qId.value(0).toInt();
        auto res = syncTarifs(anneeId,
                              data.value("tarifJeune",  0.0).toDouble(),
                              data.value("tarifAdulte", 0.0).toDouble());
        if (!res.isOk()) return res;
    }
    return Result<bool>::success(true);
}
