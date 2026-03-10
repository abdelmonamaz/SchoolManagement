#include "repositories/sqlite/sqlite_eleve_repository.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariantMap>

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

// 13 columns: id(0) nom(1) prenom(2) sexe(3) telephone(4) adresse(5)
//             date_naissance(6) nom_parent(7) tel_parent(8) commentaire(9)
//             categorie(10) cin_eleve(11) cin_parent(12)
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
    e.cinEleve      = query.value(11).toString();
    e.cinParent     = query.value(12).toString();
    return e;
}

// 17 columns: rowToEleve(13) + inscrit(13) frais_paye(14) classe_id_from_inscription(15) niveau_id(16)
static Eleve rowToEleveWithStatus(const QSqlQuery& query) {
    Eleve e = rowToEleve(query);
    e.inscritAnneeActive   = query.value(13).toInt() != 0;
    e.fraisPayeAnneeActive = query.value(14).toInt() != 0;
    e.classeId             = query.value(15).toInt();
    e.niveauId             = query.value(16).toInt();
    return e;
}

SqliteEleveRepository::SqliteEleveRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Eleve>> SqliteEleveRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral(
            "SELECT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, "
            "  e.date_naissance, e.nom_parent, e.tel_parent, e.commentaire, "
            "  e.categorie, COALESCE(e.cin_eleve,''), COALESCE(e.cin_parent,''), "
            "  CASE WHEN i.id IS NOT NULL THEN 1 ELSE 0 END, "
            "  COALESCE(i.frais_inscription_paye, 0), "
            "  COALESCE(i.classe_id, 0), "
            "  COALESCE(i.niveau_id, 0) "
            "FROM eleves e "
            "LEFT JOIN inscriptions_eleves i ON e.id = i.eleve_id "
            "  AND i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1) "
            "  AND i.valide = 1 "
            "WHERE e.valide = 1 "
            "ORDER BY e.nom, e.prenom"))) {
        return Result<QList<Eleve>>::error(query.lastError().text());
    }
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleveWithStatus(query));
    return Result<QList<Eleve>>::success(list);
}

Result<std::optional<Eleve>> SqliteEleveRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, nom, prenom, sexe, telephone, adresse, date_naissance, nom_parent, tel_parent, "
        "  commentaire, categorie, COALESCE(cin_eleve,''), COALESCE(cin_parent,'') "
        "FROM eleves WHERE id = ? AND valide = 1"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Eleve>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Eleve>>::success(rowToEleve(query));
    return Result<std::optional<Eleve>>::success(std::nullopt);
}

Result<int> SqliteEleveRepository::create(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO eleves (nom, prenom, sexe, telephone, adresse, date_naissance, "
        "  nom_parent, tel_parent, commentaire, categorie, cin_eleve, cin_parent)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
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
    query.addBindValue(entity.cinEleve.isEmpty() ? QVariant() : entity.cinEleve);
    query.addBindValue(entity.cinParent.isEmpty() ? QVariant() : entity.cinParent);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEleveRepository::update(const Eleve& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE eleves SET nom=?, prenom=?, sexe=?, telephone=?, adresse=?, date_naissance=?, "
        "  nom_parent=?, tel_parent=?, commentaire=?, categorie=?, "
        "  cin_eleve=?, cin_parent=?, date_modification = datetime('now') WHERE id=?"));
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
    query.addBindValue(entity.cinEleve.isEmpty() ? QVariant() : entity.cinEleve);
    query.addBindValue(entity.cinParent.isEmpty() ? QVariant() : entity.cinParent);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    bool ok = query.prepare(QStringLiteral(
        "UPDATE eleves SET valide = 0, date_invalidation = datetime('now'), "
        "date_modification = datetime('now') WHERE id = ?"));
    if (!ok) {
        ok = query.prepare(QStringLiteral("UPDATE eleves SET valide = 0 WHERE id = ?"));
    }

    if (!ok) return Result<bool>::error(QStringLiteral("Erreur preparation SQL: ") + query.lastError().text());

    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(QStringLiteral("Erreur execution SQL: ") + query.lastError().text());

    return Result<bool>::success(true);
}

Result<QList<Eleve>> SqliteEleveRepository::getBySchoolYear(const QString& anneeScolaire) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT DISTINCT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, "
        "  e.date_naissance, e.nom_parent, e.tel_parent, e.commentaire, e.categorie, "
        "  COALESCE(e.cin_eleve,''), COALESCE(e.cin_parent,''), "
        "  1, i.frais_inscription_paye, COALESCE(i.classe_id, 0), COALESCE(i.niveau_id, 0) "
        "FROM eleves e "
        "JOIN inscriptions_eleves i ON e.id = i.eleve_id "
        "WHERE e.valide = 1 "
        "AND i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE libelle = ? AND valide=1 LIMIT 1) "
        "AND i.valide = 1 "
        "ORDER BY e.nom, e.prenom"));
    query.addBindValue(anneeScolaire);
    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleveWithStatus(query));
    return Result<QList<Eleve>>::success(list);
}

Result<QList<Eleve>> SqliteEleveRepository::getByClasseId(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, "
        "  e.date_naissance, e.nom_parent, e.tel_parent, e.commentaire, "
        "  e.categorie, COALESCE(e.cin_eleve,''), COALESCE(e.cin_parent,''), "
        "  1, COALESCE(i.frais_inscription_paye, 0), ?, COALESCE(i.niveau_id, 0) "
        "FROM eleves e "
        "JOIN inscriptions_eleves i ON e.id = i.eleve_id "
        "  AND i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1) "
        "  AND i.valide = 1 "
        "WHERE i.classe_id = ? AND e.valide = 1"));
    query.addBindValue(classeId);  // col 15 = classe_id for rowToEleveWithStatus
    query.addBindValue(classeId);  // WHERE i.classe_id = ?
    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleveWithStatus(query));
    return Result<QList<Eleve>>::success(list);
}

Result<QList<Eleve>> SqliteEleveRepository::getByClasseAndYear(int classeId, int anneeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, "
        "  e.date_naissance, e.nom_parent, e.tel_parent, e.commentaire, "
        "  e.categorie, COALESCE(e.cin_eleve,''), COALESCE(e.cin_parent,''), "
        "  1, COALESCE(i.frais_inscription_paye, 0), "
        "  COALESCE(i.classe_id, 0), COALESCE(i.niveau_id, 0) "
        "FROM eleves e "
        "JOIN inscriptions_eleves i ON e.id = i.eleve_id "
        "WHERE i.classe_id = ? AND i.annee_scolaire_id = ? "
        "  AND i.valide = 1 AND e.valide = 1 "
        "ORDER BY e.nom, e.prenom"));
    query.addBindValue(classeId);
    query.addBindValue(anneeId);
    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());
    QList<Eleve> list;
    while (query.next()) list.append(rowToEleveWithStatus(query));
    return Result<QList<Eleve>>::success(list);
}

Result<int> SqliteEleveRepository::countAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT COUNT(*) FROM eleves WHERE valide = 1"))) {
        return Result<int>::error(query.lastError().text());
    }
    query.next();
    return Result<int>::success(query.value(0).toInt());
}

Result<bool> SqliteEleveRepository::unassignClasse(int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET classe_id = NULL, date_modification = datetime('now') "
        "WHERE classe_id = ? AND valide = 1 "
        "AND annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"));
    query.addBindValue(classeId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::removeFromClasse(int studentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET classe_id = NULL, date_modification = datetime('now') "
        "WHERE eleve_id = ? AND valide = 1 "
        "AND annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"));
    query.addBindValue(studentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteEleveRepository::assignToClasse(int studentId, int classeId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET classe_id = ?, date_modification = datetime('now') "
        "WHERE eleve_id = ? AND valide = 1 "
        "AND annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"));
    query.addBindValue(classeId);
    query.addBindValue(studentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Eleve>> SqliteEleveRepository::getUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie) {
    qDebug() << "[SqliteEleveRepo::getUnassignedStudents] niveauId=" << niveauId
             << "sexe=" << sexe << "categorie=" << categorie;
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    QString sql = QStringLiteral(
        "SELECT e.id, e.nom, e.prenom, e.sexe, e.telephone, e.adresse, e.date_naissance, "
        "  e.nom_parent, e.tel_parent, e.commentaire, e.categorie, "
        "  COALESCE(e.cin_eleve,''), COALESCE(e.cin_parent,'') "
        "FROM eleves e "
        "JOIN inscriptions_eleves i ON e.id = i.eleve_id "
        "WHERE e.valide = 1 AND (i.classe_id IS NULL OR i.classe_id = 0) "
        "AND i.valide = 1 "
        "AND i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)");

    QVariantList binds;

    if (niveauId > 0) {
        sql += QStringLiteral(" AND i.niveau_id = ?");
        binds << niveauId;
    }

    if (sexe != "all") {
        sql += QStringLiteral(" AND e.sexe = ?");
        binds << sexe;
    }
    if (categorie != "all") {
        sql += QStringLiteral(" AND e.categorie = ?");
        binds << categorie;
    }

    qDebug() << "[SqliteEleveRepo::getUnassignedStudents] SQL:" << sql << "binds:" << binds;
    query.prepare(sql);
    for (const auto& bind : binds) {
        query.addBindValue(bind);
    }

    if (!query.exec()) return Result<QList<Eleve>>::error(query.lastError().text());

    QList<Eleve> list;
    while (query.next()) {
        list.append(rowToEleve(query));
    }
    qDebug() << "[SqliteEleveRepo::getUnassignedStudents] => " << list.size() << "élève(s) trouvé(s)";
    return Result<QList<Eleve>>::success(list);
}

// ── Enrollments ──

Result<int> SqliteEleveRepository::createEnrollment(const Inscription& entity) {
    auto db = QSqlDatabase::database(m_connectionName);

    // Resolve annee_scolaire_id from text if not provided, fall back to active year
    int anneeId = entity.annee_scolaire_id;
    if (anneeId == 0) {
        QSqlQuery idQ(db);
        if (!entity.anneeScolaire.isEmpty()) {
            idQ.prepare(QStringLiteral(
                "SELECT COALESCE("
                "  (SELECT id FROM annees_scolaires WHERE libelle = ? AND valide=1 LIMIT 1),"
                "  (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"
                ")"));
            idQ.addBindValue(entity.anneeScolaire);
        } else {
            idQ.prepare(QStringLiteral(
                "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
        }
        if (idQ.exec() && idQ.next()) anneeId = idQ.value(0).toInt();
    }

    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO inscriptions_eleves "
        "  (eleve_id, annee_scolaire_id, niveau_id, resultat, frais_inscription_paye, "
        "   montant_inscription, date_inscription, justificatif_path)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.eleveId);
    query.addBindValue(anneeId > 0 ? anneeId : QVariant());
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.resultat);
    query.addBindValue(entity.fraisInscriptionPaye ? 1 : 0);
    query.addBindValue(entity.montantInscription);
    query.addBindValue(entity.dateInscription.isEmpty() ? QDate::currentDate().toString(Qt::ISODate) : entity.dateInscription);
    query.addBindValue(entity.justificatifPath);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteEleveRepository::updateEnrollment(const Inscription& entity) {
    auto db = QSqlDatabase::database(m_connectionName);

    // Resolve annee_scolaire_id from text if not provided, fall back to active year
    int anneeId = entity.annee_scolaire_id;
    if (anneeId == 0) {
        QSqlQuery idQ(db);
        if (!entity.anneeScolaire.isEmpty()) {
            idQ.prepare(QStringLiteral(
                "SELECT COALESCE("
                "  (SELECT id FROM annees_scolaires WHERE libelle = ? AND valide=1 LIMIT 1),"
                "  (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"
                ")"));
            idQ.addBindValue(entity.anneeScolaire);
        } else {
            idQ.prepare(QStringLiteral(
                "SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1"));
        }
        if (idQ.exec() && idQ.next()) anneeId = idQ.value(0).toInt();
    }

    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET annee_scolaire_id=?, niveau_id=?, resultat=?, "
        "  frais_inscription_paye=?, montant_inscription=?, date_inscription=?, "
        "  justificatif_path=?, date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(anneeId > 0 ? anneeId : QVariant());
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.resultat);
    query.addBindValue(entity.fraisInscriptionPaye ? 1 : 0);
    query.addBindValue(entity.montantInscription);
    query.addBindValue(entity.dateInscription.isEmpty() ? QDate::currentDate().toString(Qt::ISODate) : entity.dateInscription);
    query.addBindValue(entity.justificatifPath);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Inscription>> SqliteEleveRepository::getEnrollmentsByStudentId(int studentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.eleve_id, COALESCE(a.libelle,''), i.niveau_id, i.resultat, i.frais_inscription_paye, "
        "  i.montant_inscription, i.date_inscription, i.justificatif_path, "
        "  COALESCE(i.annee_scolaire_id, 0), COALESCE(i.classe_id, 0) "
        "FROM inscriptions_eleves i "
        "LEFT JOIN annees_scolaires a ON a.id = i.annee_scolaire_id "
        "WHERE i.eleve_id = ? AND i.valide = 1 ORDER BY i.date_inscription DESC"));
    query.addBindValue(studentId);
    if (!query.exec()) return Result<QList<Inscription>>::error(query.lastError().text());
    QList<Inscription> list;
    while (query.next()) {
        Inscription i;
        i.id                   = query.value(0).toInt();
        i.eleveId              = query.value(1).toInt();
        i.anneeScolaire        = query.value(2).toString();
        i.niveauId             = query.value(3).toInt();
        i.resultat             = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription   = query.value(6).toDouble();
        i.dateInscription      = query.value(7).toString();
        i.justificatifPath     = query.value(8).toString();
        i.annee_scolaire_id    = query.value(9).toInt();
        i.classeId             = query.value(10).toInt();
        list.append(i);
    }
    return Result<QList<Inscription>>::success(list);
}

Result<std::optional<Inscription>> SqliteEleveRepository::getEnrollmentByYear(int studentId, const QString& anneeScolaire) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.eleve_id, COALESCE(a.libelle,''), i.niveau_id, i.resultat, i.frais_inscription_paye, "
        "  i.montant_inscription, i.date_inscription, i.justificatif_path, "
        "  COALESCE(i.annee_scolaire_id, 0), COALESCE(i.classe_id, 0) "
        "FROM inscriptions_eleves i "
        "LEFT JOIN annees_scolaires a ON a.id = i.annee_scolaire_id "
        "WHERE i.eleve_id = ? "
        "AND i.annee_scolaire_id = COALESCE("
        "  (SELECT id FROM annees_scolaires WHERE libelle = ? AND valide=1 LIMIT 1),"
        "  (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1)"
        ") "
        "AND i.valide = 1"));
    query.addBindValue(studentId);
    query.addBindValue(anneeScolaire);
    if (!query.exec()) return Result<std::optional<Inscription>>::error(query.lastError().text());
    if (query.next()) {
        Inscription i;
        i.id                   = query.value(0).toInt();
        i.eleveId              = query.value(1).toInt();
        i.anneeScolaire        = query.value(2).toString();
        i.niveauId             = query.value(3).toInt();
        i.resultat             = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription   = query.value(6).toDouble();
        i.dateInscription      = query.value(7).toString();
        i.justificatifPath     = query.value(8).toString();
        i.annee_scolaire_id    = query.value(9).toInt();
        i.classeId             = query.value(10).toInt();
        return Result<std::optional<Inscription>>::success(i);
    }
    return Result<std::optional<Inscription>>::success(std::nullopt);
}

Result<QList<Inscription>> SqliteEleveRepository::getEnrollmentsForYear(const QString& anneeScolaire) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.eleve_id, COALESCE(a.libelle,''), i.niveau_id, i.resultat, i.frais_inscription_paye, "
        "  i.montant_inscription, i.date_inscription, i.justificatif_path, "
        "  COALESCE(i.annee_scolaire_id, 0), COALESCE(i.classe_id, 0) "
        "FROM inscriptions_eleves i "
        "LEFT JOIN annees_scolaires a ON a.id = i.annee_scolaire_id "
        "WHERE i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE libelle = ? AND valide=1 LIMIT 1) "
        "AND i.valide = 1"));
    query.addBindValue(anneeScolaire);
    if (!query.exec()) return Result<QList<Inscription>>::error(query.lastError().text());
    QList<Inscription> list;
    while (query.next()) {
        Inscription i;
        i.id                   = query.value(0).toInt();
        i.eleveId              = query.value(1).toInt();
        i.anneeScolaire        = query.value(2).toString();
        i.niveauId             = query.value(3).toInt();
        i.resultat             = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription   = query.value(6).toDouble();
        i.dateInscription      = query.value(7).toString();
        i.justificatifPath     = query.value(8).toString();
        i.annee_scolaire_id    = query.value(9).toInt();
        i.classeId             = query.value(10).toInt();
        list.append(i);
    }
    return Result<QList<Inscription>>::success(list);
}

Result<QList<Inscription>> SqliteEleveRepository::getEnrollmentsForActiveYear() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.eleve_id, COALESCE(a.libelle,''), i.niveau_id, i.resultat, i.frais_inscription_paye, "
        "  i.montant_inscription, i.date_inscription, i.justificatif_path, "
        "  COALESCE(i.annee_scolaire_id, 0), COALESCE(i.classe_id, 0) "
        "FROM inscriptions_eleves i "
        "LEFT JOIN annees_scolaires a ON a.id = i.annee_scolaire_id "
        "WHERE i.annee_scolaire_id = (SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1) "
        "AND i.valide = 1"));
    if (!query.exec()) return Result<QList<Inscription>>::error(query.lastError().text());
    QList<Inscription> list;
    while (query.next()) {
        Inscription i;
        i.id                   = query.value(0).toInt();
        i.eleveId              = query.value(1).toInt();
        i.anneeScolaire        = query.value(2).toString();
        i.niveauId             = query.value(3).toInt();
        i.resultat             = query.value(4).toString();
        i.fraisInscriptionPaye = query.value(5).toInt() != 0;
        i.montantInscription   = query.value(6).toDouble();
        i.dateInscription      = query.value(7).toString();
        i.justificatifPath     = query.value(8).toString();
        i.annee_scolaire_id    = query.value(9).toInt();
        i.classeId             = query.value(10).toInt();
        list.append(i);
    }
    return Result<QList<Inscription>>::success(list);
}

Result<bool> SqliteEleveRepository::deleteEnrollment(int enrollmentId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    bool ok = query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET valide = 0, frais_inscription_paye = 0, "
        "date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    if (!ok) ok = query.prepare(QStringLiteral(
        "UPDATE inscriptions_eleves SET valide = 0, frais_inscription_paye = 0 WHERE id = ?"));
    if (!ok) return Result<bool>::error(query.lastError().text());
    query.addBindValue(enrollmentId);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QVariantList> SqliteEleveRepository::getSchoolYears() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral(
            "SELECT id, libelle FROM annees_scolaires WHERE valide = 1 ORDER BY libelle DESC"))) {
        return Result<QVariantList>::error(query.lastError().text());
    }
    QVariantList list;
    while (query.next()) {
        list.append(QVariantMap{{"id", query.value(0).toInt()}, {"libelle", query.value(1).toString()}});
    }
    return Result<QVariantList>::success(list);
}
