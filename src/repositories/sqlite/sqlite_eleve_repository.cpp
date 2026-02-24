#include "repositories/sqlite/sqlite_eleve_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

static QString typePublicToString(GS::TypePublic t) {
    switch (t) {
        case GS::TypePublic::Jeune: return QStringLiteral("Jeune");
        case GS::TypePublic::Adulte: return QStringLiteral("Adulte");
    }
    return QStringLiteral("Jeune");
}

static GS::TypePublic stringToTypePublic(const QString& s) {
    if (s == QStringLiteral("Adulte")) return GS::TypePublic::Adulte;
    return GS::TypePublic::Jeune;
}

static Eleve rowToEleve(const QSqlQuery& query) {
    Eleve e;
    e.id            = query.value(0).toInt();
    e.nom           = query.value(1).toString();
    e.prenom        = query.value(2).toString();
    e.sexe          = query.value(3).toString();
    e.telephone     = query.value(4).toString();
    e.adresse       = query.value(5).toString();
    e.dateNaissance = query.value(6).toString();
    e.nomParent     = query.value(7).toString();
    e.telParent     = query.value(8).toString();
    e.commentaire   = query.value(9).toString();
    e.categorie     = stringToTypePublic(query.value(10).toString());
    e.classeId      = query.value(11).toInt();
    return e;
}

SqliteEleveRepository::SqliteEleveRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Eleve>> SqliteEleveRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT id, nom, prenom, sexe, telephone, adresse, date_naissance, nom_parent, tel_parent, commentaire, categorie, classe_id FROM eleves"))) {
        return Result<QList<Eleve>>::error(query.lastError().text());
    }
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleve(query));
    return Result<QList<Eleve>>::success(list);
}

Result<std::optional<Eleve>> SqliteEleveRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, sexe, telephone, adresse, date_naissance, nom_parent, tel_parent, commentaire, categorie, classe_id FROM eleves WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Eleve>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Eleve>>::success(rowToEleve(query));
    return Result<std::optional<Eleve>>::success(std::nullopt);
}

Result<int> SqliteEleveRepository::create(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO eleves (nom, prenom, sexe, telephone, adresse, date_naissance, nom_parent, tel_parent, commentaire, categorie, classe_id)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.sexe);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.dateNaissance);
    query.addBindValue(entity.nomParent);
    query.addBindValue(entity.telParent);
    query.addBindValue(entity.commentaire);
    query.addBindValue(typePublicToString(entity.categorie));
    query.addBindValue(entity.classeId > 0 ? entity.classeId : QVariant());
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEleveRepository::update(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE eleves SET nom=?, prenom=?, sexe=?, telephone=?, adresse=?, date_naissance=?, nom_parent=?, tel_parent=?, commentaire=?, categorie=?, classe_id=? WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.prenom);
    query.addBindValue(entity.sexe);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.dateNaissance);
    query.addBindValue(entity.nomParent);
    query.addBindValue(entity.telParent);
    query.addBindValue(entity.commentaire);
    query.addBindValue(typePublicToString(entity.categorie));
    query.addBindValue(entity.classeId > 0 ? entity.classeId : QVariant());
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM eleves WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Eleve>> SqliteEleveRepository::getByClasseId(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, prenom, sexe, telephone, adresse, date_naissance, nom_parent, tel_parent, commentaire, categorie, classe_id FROM eleves WHERE classe_id = ?"));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleve(query));
    return Result<QList<Eleve>>::success(list);
}

Result<int> SqliteEleveRepository::countAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM eleves"))) {
        return Result<int>::error(query.lastError().text());
    }
    query.next();
    return Result<int>::success(query.value(0).toInt());
}

Result<bool> SqliteEleveRepository::unassignClasse(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE eleves SET classe_id = NULL WHERE classe_id = ?"));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::removeFromClasse(int studentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE eleves SET classe_id = NULL WHERE id = ?"));
    query.addBindValue(studentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::assignToClasse(int studentId, int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE eleves SET classe_id = ? WHERE id = ?"));
    query.addBindValue(classeId);
    query.addBindValue(studentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Eleve>> SqliteEleveRepository::getUnassignedStudents(int niveauId, const QString& anneeScolaire, const QString& sexe, const QString& categorie) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    
    QString sql = "SELECT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, e.date_naissance, e.nom_parent, e.tel_parent, e.commentaire, e.categorie, e.classe_id "
                  "FROM eleves e "
                  "JOIN inscriptions_eleves i ON e.id = i.eleve_id "
                  "WHERE (e.classe_id IS NULL OR e.classe_id = 0) "
                  "AND i.niveau_id = ? AND i.annee_scolaire = ?";

    QVariantList binds;
    binds << niveauId << anneeScolaire;

    if (sexe != "all") {
        sql += " AND e.sexe = ?";
        binds << sexe;
    }
    if (categorie != "all") {
        sql += " AND e.categorie = ?";
        binds << categorie;
    }

    query.prepare(sql);
    for (const auto& bind : binds) {
        query.addBindValue(bind);
    }

    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    
    QList<Eleve> list;
    while (query.next()) {
        list.append(rowToEleve(query));
    }
    return Result<QList<Eleve>>::success(list);
}

// ── Enrollments ──

Result<int> SqliteEleveRepository::createEnrollment(const Inscription& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO inscriptions_eleves (eleve_id, annee_scolaire, niveau_id, resultat, frais_inscription_paye, montant_inscription)"
        " VALUES (?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.eleveId);
    query.addBindValue(entity.anneeScolaire);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.resultat);
    query.addBindValue(entity.fraisInscriptionPaye ? 1 : 0);
    query.addBindValue(entity.montantInscription);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEleveRepository::updateEnrollment(const Inscription& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET annee_scolaire=?, niveau_id=?, resultat=?, frais_inscription_paye=?, montant_inscription=? WHERE id=?"));
    query.addBindValue(entity.anneeScolaire);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.resultat);
    query.addBindValue(entity.fraisInscriptionPaye ? 1 : 0);
    query.addBindValue(entity.montantInscription);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Inscription>> SqliteEleveRepository::getEnrollmentsByStudentId(int studentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, eleve_id, annee_scolaire, niveau_id, resultat, frais_inscription_paye, montant_inscription, date_inscription FROM inscriptions_eleves WHERE eleve_id = ? ORDER BY date_inscription DESC"));
    query.addBindValue(studentId);
    if (!query.exec()) return Result<QList<Inscription>>::error(query.lastError().text());
    QList<Inscription> list;
    while (query.next()) {
        Inscription i;
        i.id = query.value(0).toInt();
        i.eleveId = query.value(1).toInt();
        i.anneeScolaire = query.value(2).toString();
        i.niveauId = query.value(3).toInt();
        i.resultat = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription = query.value(6).toDouble();
        i.dateInscription = query.value(7).toString();
        list.append(i);
    }
    return Result<QList<Inscription>>::success(list);
}

Result<std::optional<Inscription>> SqliteEleveRepository::getEnrollmentByYear(int studentId, const QString& anneeScolaire) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, eleve_id, annee_scolaire, niveau_id, resultat, frais_inscription_paye, montant_inscription, date_inscription FROM inscriptions_eleves WHERE eleve_id = ? AND annee_scolaire = ?"));
    query.addBindValue(studentId);
    query.addBindValue(anneeScolaire);
    if (!query.exec()) return Result<std::optional<Inscription>>::error(query.lastError().text());
    if (query.next()) {
        Inscription i;
        i.id = query.value(0).toInt();
        i.eleveId = query.value(1).toInt();
        i.anneeScolaire = query.value(2).toString();
        i.niveauId = query.value(3).toInt();
        i.resultat = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription = query.value(6).toDouble();
        i.dateInscription = query.value(7).toString();
        return Result<std::optional<Inscription>>::success(i);
    }
    return Result<std::optional<Inscription>>::success(std::nullopt);
}

Result<bool> SqliteEleveRepository::deleteEnrollment(int enrollmentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM inscriptions_eleves WHERE id = ?"));
    query.addBindValue(enrollmentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}
