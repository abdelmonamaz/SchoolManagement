#include "repositories/sqlite/sqlite_setup_repository.h"

#include <QDate>
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

    if (!q.next()) {
        qDebug() << "[SqliteAssociationRepository] getConfig: No row found in association_config";
        return {};
    }

    const bool init = q.value(0).toInt() == 1;
    const int  age  = q.value(5).toInt();
    const QString langue = q.value(6).toString();
    
    qDebug() << "[SqliteAssociationRepository] getConfig: retrieved langue =" << langue;

    return {
        {"initialized", init},
        {"associationData", QVariantMap{
            {"nomAssociation",   q.value(1).toString()},
            {"adresse",          q.value(2).toString()},
            {"exerciceDebut",    q.value(3).toString()},
            {"exerciceFin",      q.value(4).toString()},
            {"agePassageAdulte", age > 0 ? age : 12},
            {"langue",           langue}
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

Result<int> SqliteSetupSchoolYearRepository::initDraftYear()
{
    auto db = QSqlDatabase::database(m_connectionName);

    // If an active year already exists, reuse it.
    QSqlQuery qExist(db);
    qExist.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (qExist.next())
        return Result<int>::success(qExist.value(0).toInt());

    // Compute default academic year based on current date.
    const QDate today = QDate::currentDate();
    const int startYear = today.month() < 9 ? today.year() - 1 : today.year();
    const QString libelle   = QString("%1-%2").arg(startYear).arg(startYear + 1);
    const QString dateDebut = QString("%1-09-01").arg(startYear);
    const QString dateFin   = QString("%1-06-30").arg(startYear + 1);

    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT INTO annees_scolaires (libelle, date_debut, date_fin, statut, date_modification) "
        "VALUES (?, ?, ?, 'Active', datetime('now'))"));
    q.addBindValue(libelle);
    q.addBindValue(dateDebut);
    q.addBindValue(dateFin);
    if (!q.exec())
        return Result<int>::error(q.lastError().text());

    qInfo() << "[SetupRepo] initDraftYear: created draft year" << libelle;
    return Result<int>::success(q.lastInsertId().toInt());
}

Result<int> SqliteSetupSchoolYearRepository::finalizeActiveYear(const QVariantMap& data)
{
    auto db = QSqlDatabase::database(m_connectionName);

    // Update existing active row with the final data from step 3.
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "UPDATE annees_scolaires SET "
        "  libelle                  = ?, "
        "  date_debut               = ?, "
        "  date_fin                 = ?, "
        "  tarif_jeune              = ?, "
        "  tarif_adulte             = ?, "
        "  frais_inscription_jeune  = ?, "
        "  frais_inscription_adulte = ?, "
        "  date_modification        = datetime('now') "
        "WHERE statut = 'Active' AND valide = 1"));
    q.addBindValue(data.value("libelle").toString());
    q.addBindValue(data.value("dateDebut").toString());
    q.addBindValue(data.value("dateFin").toString());
    q.addBindValue(data.value("tarifJeune",             0.0).toDouble());
    q.addBindValue(data.value("tarifAdulte",            0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionJeune",  0.0).toDouble());
    q.addBindValue(data.value("fraisInscriptionAdulte", 0.0).toDouble());

    if (!q.exec())
        return Result<int>::error(q.lastError().text());

    // Fallback: no active row found — create via upsert.
    if (q.numRowsAffected() == 0)
        return upsertAnneeScolaire(data);

    QSqlQuery qId(db);
    qId.exec(QStringLiteral(
        "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
    if (!qId.next())
        return Result<int>::error(QStringLiteral("Impossible de retrouver l'année scolaire active."));
    return Result<int>::success(qId.value(0).toInt());
}

Result<bool> SqliteSetupSchoolYearRepository::createDefaultSemestres(int anneeId,
                                                                      const QString& dateDebut,
                                                                      const QString& dateFin,
                                                                      const QString& s1DateFin,
                                                                      const QString& s2DateDebut)
{
    const QDate d1 = QDate::fromString(dateDebut, Qt::ISODate);
    if (!d1.isValid())
        return Result<bool>::error(QStringLiteral("Date de début invalide: ") + dateDebut);

    const int nextYear = d1.year() + 1;
    const QString s1End   = !s1DateFin.isEmpty()   ? s1DateFin   : QString("%1-01-14").arg(nextYear);
    const QString s2Start = !s2DateDebut.isEmpty() ? s2DateDebut : QString("%1-01-15").arg(nextYear);

    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare(QStringLiteral(
        "INSERT OR IGNORE INTO semestres "
        "  (annee_scolaire_id, nom, numero, date_debut, date_fin) "
        "VALUES (?, ?, ?, ?, ?)"));

    const struct { const char* nom; int num; const QString& debut; const QString& fin; } semestres[2] = {
        {"Semestre 1", 1, dateDebut, s1End},
        {"Semestre 2", 2, s2Start,   dateFin},
    };

    for (const auto& s : semestres) {
        q.addBindValue(anneeId);
        q.addBindValue(QLatin1String(s.nom));
        q.addBindValue(s.num);
        q.addBindValue(s.debut);
        q.addBindValue(s.fin);
        if (!q.exec())
            return Result<bool>::error(q.lastError().text());
    }

    qInfo() << "[SetupRepo] createDefaultSemestres: S1" << dateDebut << "→" << s1End
            << "/ S2" << s2Start << "→" << dateFin;
    return Result<bool>::success(true);
}

QVariantList SqliteSetupSchoolYearRepository::getActiveSemestres()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.exec(QStringLiteral(
        "SELECT s.id, s.numero, s.nom, s.date_debut, s.date_fin "
        "FROM semestres s "
        "JOIN annees_scolaires a ON s.annee_scolaire_id = a.id "
        "WHERE a.statut = 'Active' AND a.valide = 1 AND s.valide = 1 "
        "ORDER BY s.numero"));

    QVariantList list;
    while (q.next()) {
        list.append(QVariantMap{
            {"id",        q.value(0).toInt()},
            {"numero",    q.value(1).toInt()},
            {"nom",       q.value(2).toString()},
            {"dateDebut", q.value(3).toString()},
            {"dateFin",   q.value(4).toString()}
        });
    }
    return list;
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
