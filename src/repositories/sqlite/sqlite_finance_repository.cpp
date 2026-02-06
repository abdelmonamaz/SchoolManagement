#include "repositories/sqlite/sqlite_finance_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

// ─── Enum helpers ───

static QString statutProjetToString(GS::StatutProjet s) {
    switch (s) {
        case GS::StatutProjet::EnCours: return QStringLiteral("En cours");
        case GS::StatutProjet::Termine: return QStringLiteral("Terminé");
        case GS::StatutProjet::EnPause: return QStringLiteral("En pause");
    }
    return QStringLiteral("En cours");
}

static GS::StatutProjet stringToStatutProjet(const QString& s) {
    if (s == QStringLiteral("Terminé")) return GS::StatutProjet::Termine;
    if (s == QStringLiteral("En pause")) return GS::StatutProjet::EnPause;
    return GS::StatutProjet::EnCours;
}

// ═══════════════════════════════════════════════════════════════
// SqliteProjetRepository
// ═══════════════════════════════════════════════════════════════

SqliteProjetRepository::SqliteProjetRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Projet>> SqliteProjetRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, description, objectif_financier, statut FROM projets"))) {
        return Result<QList<Projet>>::error(query.lastError().text());
    }
    QList<Projet> list;
    while (query.next()) {
        Projet p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.description = query.value(2).toString();
        p.objectifFinancier = query.value(3).toDouble();
        p.statut = stringToStatutProjet(query.value(4).toString());
        list.append(p);
    }
    return Result<QList<Projet>>::success(list);
}

Result<std::optional<Projet>> SqliteProjetRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, description, objectif_financier, statut FROM projets WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Projet>>::error(query.lastError().text());
    if (query.next()) {
        Projet p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.description = query.value(2).toString();
        p.objectifFinancier = query.value(3).toDouble();
        p.statut = stringToStatutProjet(query.value(4).toString());
        return Result<std::optional<Projet>>::success(p);
    }
    return Result<std::optional<Projet>>::success(std::nullopt);
}

Result<int> SqliteProjetRepository::create(const Projet& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO projets (nom, description, objectif_financier, statut) VALUES (?, ?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.description);
    query.addBindValue(entity.objectifFinancier);
    query.addBindValue(statutProjetToString(entity.statut));
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteProjetRepository::update(const Projet& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE projets SET nom=?, description=?, objectif_financier=?, statut=? WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.description);
    query.addBindValue(entity.objectifFinancier);
    query.addBindValue(statutProjetToString(entity.statut));
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteProjetRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM projets WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

// ═══════════════════════════════════════════════════════════════
// SqliteDonateurRepository
// ═══════════════════════════════════════════════════════════════

SqliteDonateurRepository::SqliteDonateurRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Donateur>> SqliteDonateurRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, telephone, adresse FROM donateurs"))) {
        return Result<QList<Donateur>>::error(query.lastError().text());
    }
    QList<Donateur> list;
    while (query.next()) {
        Donateur d;
        d.id = query.value(0).toInt();
        d.nom = query.value(1).toString();
        d.telephone = query.value(2).toString();
        d.adresse = query.value(3).toString();
        list.append(d);
    }
    return Result<QList<Donateur>>::success(list);
}

Result<std::optional<Donateur>> SqliteDonateurRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, telephone, adresse FROM donateurs WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Donateur>>::error(query.lastError().text());
    if (query.next()) {
        Donateur d;
        d.id = query.value(0).toInt();
        d.nom = query.value(1).toString();
        d.telephone = query.value(2).toString();
        d.adresse = query.value(3).toString();
        return Result<std::optional<Donateur>>::success(d);
    }
    return Result<std::optional<Donateur>>::success(std::nullopt);
}

Result<int> SqliteDonateurRepository::create(const Donateur& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("INSERT INTO donateurs (nom, telephone, adresse) VALUES (?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteDonateurRepository::update(const Donateur& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE donateurs SET nom=?, telephone=?, adresse=? WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteDonateurRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM donateurs WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

// ═══════════════════════════════════════════════════════════════
// SqliteDonRepository
// ═══════════════════════════════════════════════════════════════

static Don rowToDon(const QSqlQuery& q) {
    Don d;
    d.id = q.value(0).toInt();
    d.donateurId = q.value(1).toInt();
    d.projetId = q.value(2).toInt();
    d.montant = q.value(3).toDouble();
    d.dateDon = QDate::fromString(q.value(4).toString(), Qt::ISODate);
    return d;
}

static const auto kDonCols = QStringLiteral("id, donateur_id, projet_id, montant, date_don");

SqliteDonRepository::SqliteDonRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Don>> SqliteDonRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM dons").arg(kDonCols))) {
        return Result<QList<Don>>::error(query.lastError().text());
    }
    QList<Don> list;
    while (query.next()) list.append(rowToDon(query));
    return Result<QList<Don>>::success(list);
}

Result<std::optional<Don>> SqliteDonRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM dons WHERE id = ?").arg(kDonCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Don>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Don>>::success(rowToDon(query));
    return Result<std::optional<Don>>::success(std::nullopt);
}

Result<int> SqliteDonRepository::create(const Don& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("INSERT INTO dons (donateur_id, projet_id, montant, date_don) VALUES (?, ?, ?, ?)"));
    query.addBindValue(entity.donateurId);
    query.addBindValue(entity.projetId);
    query.addBindValue(entity.montant);
    query.addBindValue(entity.dateDon.toString(Qt::ISODate));
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteDonRepository::update(const Don& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE dons SET donateur_id=?, projet_id=?, montant=?, date_don=? WHERE id=?"));
    query.addBindValue(entity.donateurId);
    query.addBindValue(entity.projetId);
    query.addBindValue(entity.montant);
    query.addBindValue(entity.dateDon.toString(Qt::ISODate));
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteDonRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM dons WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Don>> SqliteDonRepository::getByProjetId(int projetId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM dons WHERE projet_id = ?").arg(kDonCols));
    query.addBindValue(projetId);
    if (!query.exec()) return Result<QList<Don>>::error(query.lastError().text());
    QList<Don> list;
    while (query.next()) list.append(rowToDon(query));
    return Result<QList<Don>>::success(list);
}

Result<double> SqliteDonRepository::getTotalByProjet(int projetId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT COALESCE(SUM(montant), 0) FROM dons WHERE projet_id = ?"));
    query.addBindValue(projetId);
    if (!query.exec()) return Result<double>::error(query.lastError().text());
    query.next();
    return Result<double>::success(query.value(0).toDouble());
}
