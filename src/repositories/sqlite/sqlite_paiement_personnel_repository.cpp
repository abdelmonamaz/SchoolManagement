#include "sqlite_paiement_personnel_repository.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>

static constexpr const char* kCols =
    "id, personnel_id, mois, annee, somme_due, somme_payee, date_modification";

static PaiementMensuelPersonnel rowToPaiement(QSqlQuery& q) {
    PaiementMensuelPersonnel p;
    p.id = q.value(0).toInt();
    p.personnelId = q.value(1).toInt();
    p.mois = q.value(2).toInt();
    p.annee = q.value(3).toInt();
    p.sommeDue = q.value(4).toDouble();
    p.sommePaye = q.value(5).toDouble();
    p.dateModification = q.value(6).toDateTime();
    return p;
}

SqlitePaiementPersonnelRepository::SqlitePaiementPersonnelRepository(const QString& connectionName)
    : m_connectionName(connectionName)
{
}

Result<QList<PaiementMensuelPersonnel>> SqlitePaiementPersonnelRepository::getAll() {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    if (!q.exec(QStringLiteral("SELECT %1 FROM paiements_personnel").arg(kCols))) {
        return Result<QList<PaiementMensuelPersonnel>>::error(
            QStringLiteral("Erreur SELECT paiements_personnel : ") + q.lastError().text());
    }

    QList<PaiementMensuelPersonnel> list;
    while (q.next()) {
        list.append(rowToPaiement(q));
    }
    return Result<QList<PaiementMensuelPersonnel>>::success(std::move(list));
}

Result<std::optional<PaiementMensuelPersonnel>> SqlitePaiementPersonnelRepository::getById(int id) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral("SELECT %1 FROM paiements_personnel WHERE id = ?").arg(kCols));
    q.addBindValue(id);

    if (!q.exec()) {
        return Result<std::optional<PaiementMensuelPersonnel>>::error(
            QStringLiteral("Erreur SELECT paiements_personnel BY ID: ") + q.lastError().text());
    }

    if (q.next()) {
        return Result<std::optional<PaiementMensuelPersonnel>>::success(rowToPaiement(q));
    }
    return Result<std::optional<PaiementMensuelPersonnel>>::success(std::nullopt);
}

Result<int> SqlitePaiementPersonnelRepository::create(const PaiementMensuelPersonnel& entity) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral(
        "INSERT INTO paiements_personnel "
        "(personnel_id, mois, annee, somme_due, somme_payee, date_modification) "
        "VALUES (?, ?, ?, ?, ?, ?)"));

    q.addBindValue(entity.personnelId);
    q.addBindValue(entity.mois);
    q.addBindValue(entity.annee);
    q.addBindValue(entity.sommeDue);
    q.addBindValue(entity.sommePaye);
    q.addBindValue(entity.dateModification.toString(Qt::ISODate));

    if (!q.exec()) {
        return Result<int>::error(
            QStringLiteral("Erreur INSERT paiements_personnel: ") + q.lastError().text());
    }

    return Result<int>::success(q.lastInsertId().toInt());
}

Result<bool> SqlitePaiementPersonnelRepository::update(const PaiementMensuelPersonnel& entity) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral(
        "UPDATE paiements_personnel SET "
        "personnel_id = ?, mois = ?, annee = ?, "
        "somme_due = ?, somme_payee = ?, date_modification = ? "
        "WHERE id = ?"));

    q.addBindValue(entity.personnelId);
    q.addBindValue(entity.mois);
    q.addBindValue(entity.annee);
    q.addBindValue(entity.sommeDue);
    q.addBindValue(entity.sommePaye);
    q.addBindValue(entity.dateModification.toString(Qt::ISODate));
    q.addBindValue(entity.id);

    if (!q.exec()) {
        return Result<bool>::error(
            QStringLiteral("Erreur UPDATE paiements_personnel: ") + q.lastError().text());
    }

    return Result<bool>::success(true);
}

Result<bool> SqlitePaiementPersonnelRepository::remove(int id) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral("DELETE FROM paiements_personnel WHERE id = ?"));
    q.addBindValue(id);

    if (!q.exec()) {
        return Result<bool>::error(
            QStringLiteral("Erreur DELETE paiements_personnel: ") + q.lastError().text());
    }

    return Result<bool>::success(true);
}

Result<std::optional<PaiementMensuelPersonnel>>
SqlitePaiementPersonnelRepository::getByPersonnelAndMonth(int personnelId, int mois, int annee) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral(
        "SELECT %1 FROM paiements_personnel "
        "WHERE personnel_id = ? AND mois = ? AND annee = ?").arg(kCols));

    q.addBindValue(personnelId);
    q.addBindValue(mois);
    q.addBindValue(annee);

    if (!q.exec()) {
        return Result<std::optional<PaiementMensuelPersonnel>>::error(
            QStringLiteral("Erreur SELECT paiements_personnel BY PERSONNEL AND MONTH: ") + q.lastError().text());
    }

    if (q.next()) {
        return Result<std::optional<PaiementMensuelPersonnel>>::success(rowToPaiement(q));
    }
    return Result<std::optional<PaiementMensuelPersonnel>>::success(std::nullopt);
}

Result<QList<PaiementMensuelPersonnel>>
SqlitePaiementPersonnelRepository::getByMonth(int mois, int annee) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    q.prepare(QStringLiteral(
        "SELECT %1 FROM paiements_personnel "
        "WHERE mois = ? AND annee = ?").arg(kCols));

    q.addBindValue(mois);
    q.addBindValue(annee);

    if (!q.exec()) {
        return Result<QList<PaiementMensuelPersonnel>>::error(
            QStringLiteral("Erreur SELECT paiements_personnel BY MONTH: ") + q.lastError().text());
    }

    QList<PaiementMensuelPersonnel> list;
    while (q.next()) {
        list.append(rowToPaiement(q));
    }
    return Result<QList<PaiementMensuelPersonnel>>::success(std::move(list));
}

Result<bool> SqlitePaiementPersonnelRepository::upsert(const PaiementMensuelPersonnel& paiement) {
    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    // INSERT OR REPLACE (utilise la contrainte UNIQUE sur personnel_id, mois, annee)
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO paiements_personnel "
        "(personnel_id, mois, annee, somme_due, somme_payee, date_modification) "
        "VALUES (?, ?, ?, ?, ?, ?)"));

    q.addBindValue(paiement.personnelId);
    q.addBindValue(paiement.mois);
    q.addBindValue(paiement.annee);
    q.addBindValue(paiement.sommeDue);
    q.addBindValue(paiement.sommePaye);
    q.addBindValue(paiement.dateModification.toString(Qt::ISODate));

    if (!q.exec()) {
        return Result<bool>::error(
            QStringLiteral("Erreur UPSERT paiements_personnel: ") + q.lastError().text());
    }

    return Result<bool>::success(true);
}
