#include "repositories/sqlite/sqlite_paiement_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

static PaiementMensualite rowToPaiement(const QSqlQuery& q) {
    PaiementMensualite p;
    p.id = q.value(0).toInt();
    p.eleveId = q.value(1).toInt();
    p.montantPaye = q.value(2).toDouble();
    p.datePaiement = QDate::fromString(q.value(3).toString(), Qt::ISODate);
    p.moisConcerne = q.value(4).toInt();
    p.anneeConcernee = q.value(5).toInt();
    p.justificatifPath = q.value(6).toString();
    return p;
}

static const auto kCols = QStringLiteral(
    "id, eleve_id, montant_paye, date_paiement, mois_concerne, annee_concernee, justificatif_path");

SqlitePaiementRepository::SqlitePaiementRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<PaiementMensualite>> SqlitePaiementRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM paiements_mensualites").arg(kCols))) {
        return Result<QList<PaiementMensualite>>::error(query.lastError().text());
    }
    QList<PaiementMensualite> list;
    while (query.next()) list.append(rowToPaiement(query));
    return Result<QList<PaiementMensualite>>::success(list);
}

Result<std::optional<PaiementMensualite>> SqlitePaiementRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM paiements_mensualites WHERE id = ?").arg(kCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<PaiementMensualite>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<PaiementMensualite>>::success(rowToPaiement(query));
    return Result<std::optional<PaiementMensualite>>::success(std::nullopt);
}

Result<int> SqlitePaiementRepository::create(const PaiementMensualite& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO paiements_mensualites (eleve_id, montant_paye, date_paiement, mois_concerne, annee_concernee, justificatif_path) "
        "VALUES (?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.eleveId);
    query.addBindValue(entity.montantPaye);
    query.addBindValue(entity.datePaiement.toString(Qt::ISODate));
    query.addBindValue(entity.moisConcerne);
    query.addBindValue(entity.anneeConcernee);
    query.addBindValue(entity.justificatifPath);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqlitePaiementRepository::update(const PaiementMensualite& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE paiements_mensualites SET eleve_id=?, montant_paye=?, date_paiement=?, "
        "mois_concerne=?, annee_concernee=?, justificatif_path=? WHERE id=?"));
    query.addBindValue(entity.eleveId);
    query.addBindValue(entity.montantPaye);
    query.addBindValue(entity.datePaiement.toString(Qt::ISODate));
    query.addBindValue(entity.moisConcerne);
    query.addBindValue(entity.anneeConcernee);
    query.addBindValue(entity.justificatifPath);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqlitePaiementRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM paiements_mensualites WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<PaiementMensualite>> SqlitePaiementRepository::getByMonth(int month, int year) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM paiements_mensualites WHERE mois_concerne = ? AND annee_concernee = ?").arg(kCols));
    query.addBindValue(month);
    query.addBindValue(year);
    if (!query.exec()) return Result<QList<PaiementMensualite>>::error(query.lastError().text());
    QList<PaiementMensualite> list;
    while (query.next()) list.append(rowToPaiement(query));
    return Result<QList<PaiementMensualite>>::success(list);
}

Result<QList<PaiementMensualite>> SqlitePaiementRepository::getByEleveId(int eleveId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM paiements_mensualites WHERE eleve_id = ?").arg(kCols));
    query.addBindValue(eleveId);
    if (!query.exec()) return Result<QList<PaiementMensualite>>::error(query.lastError().text());
    QList<PaiementMensualite> list;
    while (query.next()) list.append(rowToPaiement(query));
    return Result<QList<PaiementMensualite>>::success(list);
}

Result<bool> SqlitePaiementRepository::deleteByEleveAndMonth(int eleveId, int month, int year) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "DELETE FROM paiements_mensualites WHERE eleve_id = ? AND mois_concerne = ? AND annee_concernee = ?"));
    query.addBindValue(eleveId);
    query.addBindValue(month);
    query.addBindValue(year);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}
