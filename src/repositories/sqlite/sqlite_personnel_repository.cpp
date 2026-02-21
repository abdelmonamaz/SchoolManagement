#include "repositories/sqlite/sqlite_personnel_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

static QString statutProfToString(GS::StatutProf s) {
    switch (s) {
        case GS::StatutProf::Actif: return QStringLiteral("Actif");
        case GS::StatutProf::EnConge: return QStringLiteral("En congé");
    }
    return QStringLiteral("Actif");
}

static GS::StatutProf stringToStatutProf(const QString& s) {
    if (s == QStringLiteral("En congé")) return GS::StatutProf::EnConge;
    return GS::StatutProf::Actif;
}

SqlitePersonnelRepository::SqlitePersonnelRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Personnel>> SqlitePersonnelRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, poste, specialite, mode_paie, valeur_base, paye_pendant_vacances, heures_travalies, statut, prix_heure_actuel FROM personnel"))) {
        return Result<QList<Personnel>>::error(query.lastError().text());
    }

    QList<Personnel> list;
    while (query.next()) {
        Personnel p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.prenom = query.value(2).toString();
        p.telephone = query.value(3).toString();
        p.adresse = query.value(4).toString();
        p.poste = query.value(5).toString();
        p.specialite = query.value(6).toString();
        p.modePaie = query.value(7).toString();
        p.valeurBase = query.value(8).toDouble();
        p.payePendantVacances = query.value(9).toBool();
        p.heuresTravailes = query.value(10).toInt();
        p.statut = stringToStatutProf(query.value(11).toString());
        p.prixHeureActuel = query.value(12).toDouble();
        list.append(p);
    }
    return Result<QList<Personnel>>::success(list);
}

Result<std::optional<Personnel>> SqlitePersonnelRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, telephone, adresse, poste, specialite, mode_paie, valeur_base, paye_pendant_vacances, heures_travalies, statut, prix_heure_actuel FROM personnel WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) {
        return Result<std::optional<Personnel>>::error(query.lastError().text());
    }

    if (query.next()) {
        Personnel p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.prenom = query.value(2).toString();
        p.telephone = query.value(3).toString();
        p.adresse = query.value(4).toString();
        p.poste = query.value(5).toString();
        p.specialite = query.value(6).toString();
        p.modePaie = query.value(7).toString();
        p.valeurBase = query.value(8).toDouble();
        p.payePendantVacances = query.value(9).toBool();
        p.heuresTravailes = query.value(10).toInt();
        p.statut = stringToStatutProf(query.value(11).toString());
        p.prixHeureActuel = query.value(12).toDouble();
        return Result<std::optional<Personnel>>::success(p);
    }
    return Result<std::optional<Personnel>>::success(std::nullopt);
}

Result<int> SqlitePersonnelRepository::create(const Personnel& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO personnel (nom, prenom, telephone, adresse, poste, specialite, mode_paie, valeur_base, paye_pendant_vacances, heures_travalies, statut, prix_heure_actuel) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));

    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.poste);
    query.addBindValue(entity.specialite);
    query.addBindValue(entity.modePaie);
    query.addBindValue(entity.valeurBase);
    query.addBindValue(entity.payePendantVacances);
    query.addBindValue(entity.heuresTravailes);
    query.addBindValue(statutProfToString(entity.statut));
    query.addBindValue(entity.prixHeureActuel);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqlitePersonnelRepository::update(const Personnel& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE personnel SET nom=?, prenom=?, telephone=?, adresse=?, poste=?, specialite=?, mode_paie=?, valeur_base=?, paye_pendant_vacances=?, heures_travalies=?, statut=?, prix_heure_actuel=? "
        "WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.poste);
    query.addBindValue(entity.specialite);
    query.addBindValue(entity.modePaie);
    query.addBindValue(entity.valeurBase);
    query.addBindValue(entity.payePendantVacances);
    query.addBindValue(entity.heuresTravailes);
    query.addBindValue(statutProfToString(entity.statut));
    query.addBindValue(entity.prixHeureActuel);
    query.addBindValue(entity.id);
    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqlitePersonnelRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM personnel WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<QList<TarifPersonnelHistorique>> SqlitePersonnelRepository::getTarifHistorique(int profId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, prof_id, nouveau_prix, date_changement FROM tarifs_profs_historique "
        "WHERE prof_id = ? ORDER BY date_changement DESC"));
    query.addBindValue(profId);
    if (!query.exec()) {
        return Result<QList<TarifPersonnelHistorique>>::error(query.lastError().text());
    }

    QList<TarifPersonnelHistorique> list;
    while (query.next()) {
        TarifPersonnelHistorique t;
        t.id = query.value(0).toInt();
        t.profId = query.value(1).toInt();
        t.nouveauPrix = query.value(2).toDouble();
        t.dateChangement = QDateTime::fromString(query.value(3).toString(), Qt::ISODate);
        list.append(t);
    }
    return Result<QList<TarifPersonnelHistorique>>::success(list);
}

Result<int> SqlitePersonnelRepository::addTarifHistorique(const TarifPersonnelHistorique& tarif) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO tarifs_profs_historique (prof_id, nouveau_prix, date_changement) VALUES (?, ?, ?)"));
    query.addBindValue(tarif.profId);
    query.addBindValue(tarif.nouveauPrix);
    query.addBindValue(tarif.dateChangement.toString(Qt::ISODate));
    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}
