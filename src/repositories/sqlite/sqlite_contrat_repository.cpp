#include "repositories/sqlite/sqlite_contrat_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

static Contrat readContrat(const QSqlQuery& query) {
    Contrat c;
    c.id = query.value(0).toInt();
    c.personnelId = query.value(1).toInt();
    c.poste = query.value(2).toString();
    c.specialite = query.value(3).toString();
    c.modePaie = query.value(4).toString();
    c.valeurBase = query.value(5).toDouble();
    c.dateDebut = QDate::fromString(query.value(6).toString(), Qt::ISODate);
    QString dateFin = query.value(7).toString();
    if (!dateFin.isEmpty())
        c.dateFin = QDate::fromString(dateFin, Qt::ISODate);
    return c;
}

SqliteContratRepository::SqliteContratRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Contrat>> SqliteContratRepository::getByPersonnelId(int personnelId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, personnel_id, poste, specialite, mode_paie, valeur_base, date_debut, date_fin "
        "FROM contrats WHERE personnel_id = ? ORDER BY date_debut DESC"));
    query.addBindValue(personnelId);
    if (!query.exec())
        return Result<QList<Contrat>>::error(query.lastError().text());

    QList<Contrat> list;
    while (query.next())
        list.append(readContrat(query));
    return Result<QList<Contrat>>::success(list);
}

Result<std::optional<Contrat>> SqliteContratRepository::getActiveContrat(int personnelId, const QDate& date) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, personnel_id, poste, specialite, mode_paie, valeur_base, date_debut, date_fin "
        "FROM contrats "
        "WHERE personnel_id = ? AND date_debut <= ? AND (date_fin IS NULL OR date_fin >= ?) "
        "ORDER BY date_debut DESC LIMIT 1"));
    query.addBindValue(personnelId);
    query.addBindValue(date.toString(Qt::ISODate));
    query.addBindValue(date.toString(Qt::ISODate));
    if (!query.exec())
        return Result<std::optional<Contrat>>::error(query.lastError().text());

    if (query.next())
        return Result<std::optional<Contrat>>::success(readContrat(query));
    return Result<std::optional<Contrat>>::success(std::nullopt);
}

Result<QList<Contrat>> SqliteContratRepository::getActiveContrats(const QDate& date) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, personnel_id, poste, specialite, mode_paie, valeur_base, date_debut, date_fin "
        "FROM contrats "
        "WHERE date_debut <= ? AND (date_fin IS NULL OR date_fin >= ?) "
        "ORDER BY personnel_id, date_debut DESC"));
    query.addBindValue(date.toString(Qt::ISODate));
    query.addBindValue(date.toString(Qt::ISODate));
    if (!query.exec())
        return Result<QList<Contrat>>::error(query.lastError().text());

    QList<Contrat> list;
    while (query.next())
        list.append(readContrat(query));
    return Result<QList<Contrat>>::success(list);
}

Result<QList<Contrat>> SqliteContratRepository::getContratsForPeriod(const QDate& from, const QDate& to) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // A contract overlaps [from, to] if: date_debut <= to AND (date_fin IS NULL OR date_fin >= from)
    query.prepare(QStringLiteral(
        "SELECT id, personnel_id, poste, specialite, mode_paie, valeur_base, date_debut, date_fin "
        "FROM contrats "
        "WHERE date_debut <= ? AND (date_fin IS NULL OR date_fin >= ?) "
        "ORDER BY personnel_id, date_debut DESC"));
    query.addBindValue(to.toString(Qt::ISODate));
    query.addBindValue(from.toString(Qt::ISODate));
    if (!query.exec())
        return Result<QList<Contrat>>::error(query.lastError().text());

    QList<Contrat> list;
    while (query.next())
        list.append(readContrat(query));
    return Result<QList<Contrat>>::success(list);
}

Result<int> SqliteContratRepository::create(const Contrat& contrat) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO contrats (personnel_id, poste, specialite, mode_paie, valeur_base, date_debut, date_fin) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(contrat.personnelId);
    query.addBindValue(contrat.poste);
    query.addBindValue(contrat.specialite);
    query.addBindValue(contrat.modePaie);
    query.addBindValue(contrat.valeurBase);
    query.addBindValue(contrat.dateDebut.toString(Qt::ISODate));
    query.addBindValue(contrat.dateFin.isValid() ? contrat.dateFin.toString(Qt::ISODate) : QVariant());
    if (!query.exec())
        return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteContratRepository::update(const Contrat& contrat) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE contrats SET poste=?, specialite=?, mode_paie=?, valeur_base=?, date_debut=?, date_fin=? "
        "WHERE id=?"));
    query.addBindValue(contrat.poste);
    query.addBindValue(contrat.specialite);
    query.addBindValue(contrat.modePaie);
    query.addBindValue(contrat.valeurBase);
    query.addBindValue(contrat.dateDebut.toString(Qt::ISODate));
    query.addBindValue(contrat.dateFin.isValid() ? contrat.dateFin.toString(Qt::ISODate) : QVariant());
    query.addBindValue(contrat.id);
    if (!query.exec())
        return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteContratRepository::remove(int contratId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM contrats WHERE id = ?"));
    query.addBindValue(contratId);
    if (!query.exec())
        return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteContratRepository::closeContrat(int contratId, const QDate& dateFin) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE contrats SET date_fin = ? WHERE id = ?"));
    query.addBindValue(dateFin.toString(Qt::ISODate));
    query.addBindValue(contratId);
    if (!query.exec())
        return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteContratRepository::hasOverlap(int personnelId, const QDate& dateDebut, const QDate& dateFin, int excludeContratId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // Two intervals [A_start, A_end] and [B_start, B_end] overlap when A_start <= B_end AND B_start <= A_end
    // For open-ended contracts (date_fin IS NULL), treat them as extending to infinity
    QString sql = QStringLiteral(
        "SELECT COUNT(*) FROM contrats "
        "WHERE personnel_id = ? AND id != ? "
        "AND date_debut <= ? "
        "AND (date_fin IS NULL OR date_fin >= ?)");
    query.prepare(sql);
    query.addBindValue(personnelId);
    query.addBindValue(excludeContratId);
    // If dateFin is invalid (open-ended new contract), use a far-future date for the overlap check
    QString endStr = dateFin.isValid() ? dateFin.toString(Qt::ISODate) : "9999-12-31";
    query.addBindValue(endStr);
    query.addBindValue(dateDebut.toString(Qt::ISODate));
    if (!query.exec() || !query.next())
        return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(query.value(0).toInt() > 0);
}

Result<int> SqliteContratRepository::countByPersonnelId(int personnelId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT COUNT(*) FROM contrats WHERE personnel_id = ?"));
    query.addBindValue(personnelId);
    if (!query.exec() || !query.next())
        return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.value(0).toInt());
}
