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
    if (!query.exec(QStringLiteral("SELECT id, nom, description, objectif_financier, statut, date_debut, date_fin FROM projets WHERE valide = 1"))) {
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
        p.dateDebut = QDate::fromString(query.value(5).toString(), Qt::ISODate);
        p.dateFin = QDate::fromString(query.value(6).toString(), Qt::ISODate);
        list.append(p);
    }
    return Result<QList<Projet>>::success(list);
}

Result<std::optional<Projet>> SqliteProjetRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT id, nom, description, objectif_financier, statut, date_debut, date_fin FROM projets WHERE id = ? AND valide = 1"));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Projet>>::error(query.lastError().text());

    if (query.next()) {
        Projet p;
        p.id = query.value(0).toInt();
        p.nom = query.value(1).toString();
        p.description = query.value(2).toString();
        p.objectifFinancier = query.value(3).toDouble();
        p.statut = stringToStatutProjet(query.value(4).toString());
        p.dateDebut = QDate::fromString(query.value(5).toString(), Qt::ISODate);
        p.dateFin = QDate::fromString(query.value(6).toString(), Qt::ISODate);
        return Result<std::optional<Projet>>::success(p);
    }
    return Result<std::optional<Projet>>::success(std::nullopt);
}

Result<int> SqliteProjetRepository::create(const Projet& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO projets (nom, description, objectif_financier, statut, date_debut, date_fin) VALUES (?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.description);
    query.addBindValue(entity.objectifFinancier);
    query.addBindValue(statutProjetToString(entity.statut));
    query.addBindValue(entity.dateDebut.isValid() ? entity.dateDebut.toString(Qt::ISODate) : QVariant());
    query.addBindValue(entity.dateFin.isValid() ? entity.dateFin.toString(Qt::ISODate) : QVariant());
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteProjetRepository::update(const Projet& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE projets SET nom=?, description=?, objectif_financier=?, statut=?, date_debut=?, date_fin=? , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.description);
    query.addBindValue(entity.objectifFinancier);
    query.addBindValue(statutProjetToString(entity.statut));
    query.addBindValue(entity.dateDebut.isValid() ? entity.dateDebut.toString(Qt::ISODate) : QVariant());
    query.addBindValue(entity.dateFin.isValid() ? entity.dateFin.toString(Qt::ISODate) : QVariant());
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteProjetRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE projets SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

// ═══════════════════════════════════════════════════════════════
// SqliteDonateurRepository
// ═══════════════════════════════════════════════════════════════

SqliteDonateurRepository::SqliteDonateurRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

static const auto kDonateurCols = QStringLiteral(
    "id, nom, telephone, adresse, type_personne, cin, raison_sociale, matricule_fiscal, representant_legal");

static Donateur rowToDonateur(const QSqlQuery& q) {
    Donateur d;
    d.id               = q.value(0).toInt();
    d.nom              = q.value(1).toString();
    d.telephone        = q.value(2).toString();
    d.adresse          = q.value(3).toString();
    d.typePersonne     = q.value(4).toString();
    if (d.typePersonne.isEmpty()) d.typePersonne = QStringLiteral("Physique");
    d.cin              = q.value(5).toString();
    d.raisonSociale    = q.value(6).toString();
    d.matriculeFiscal  = q.value(7).toString();
    d.representantLegal = q.value(8).toString();
    return d;
}

Result<QList<Donateur>> SqliteDonateurRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM donateurs WHERE valide = 1").arg(kDonateurCols))) {
        return Result<QList<Donateur>>::error(query.lastError().text());
    }
    QList<Donateur> list;
    while (query.next()) list.append(rowToDonateur(query));
    return Result<QList<Donateur>>::success(list);
}

Result<std::optional<Donateur>> SqliteDonateurRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM donateurs WHERE id = ? AND valide = 1").arg(kDonateurCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Donateur>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Donateur>>::success(rowToDonateur(query));
    return Result<std::optional<Donateur>>::success(std::nullopt);
}

Result<int> SqliteDonateurRepository::create(const Donateur& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO donateurs (nom, telephone, adresse, type_personne, cin, raison_sociale, matricule_fiscal, representant_legal)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.typePersonne.isEmpty() ? QStringLiteral("Physique") : entity.typePersonne);
    query.addBindValue(entity.cin);
    query.addBindValue(entity.raisonSociale);
    query.addBindValue(entity.matriculeFiscal);
    query.addBindValue(entity.representantLegal);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteDonateurRepository::update(const Donateur& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE donateurs SET nom=?, telephone=?, adresse=?, type_personne=?, cin=?,"
        " raison_sociale=?, matricule_fiscal=?, representant_legal=? , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.nom);
    query.addBindValue(entity.telephone);
    query.addBindValue(entity.adresse);
    query.addBindValue(entity.typePersonne);
    query.addBindValue(entity.cin);
    query.addBindValue(entity.raisonSociale);
    query.addBindValue(entity.matriculeFiscal);
    query.addBindValue(entity.representantLegal);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteDonateurRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE donateurs SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

// ═══════════════════════════════════════════════════════════════
// SqliteDonRepository
// ═══════════════════════════════════════════════════════════════

static Don rowToDon(const QSqlQuery& q) {
    Don d;
    d.id                  = q.value(0).toInt();
    d.donateurId          = q.value(1).toInt();
    d.projetId            = q.value(2).toInt();
    d.montant             = q.value(3).toDouble();
    d.dateDon             = QDate::fromString(q.value(4).toString(), Qt::ISODate);
    d.natureDon           = q.value(5).toString();
    d.modePaiement        = q.value(6).toString();
    d.descriptionMateriel = q.value(7).toString();
    d.valeurEstimee       = q.value(8).toDouble();
    d.etatMateriel        = q.value(9).toString();
    d.justificatifPath    = q.value(10).toString();
    return d;
}

static const auto kDonCols = QStringLiteral(
    "id, donateur_id, projet_id, montant, date_don,"
    " nature_don, mode_paiement, description_materiel, valeur_estimee, etat_materiel, justificatif_path");

SqliteDonRepository::SqliteDonRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Don>> SqliteDonRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM dons WHERE valide = 1").arg(kDonCols))) {
        return Result<QList<Don>>::error(query.lastError().text());
    }
    QList<Don> list;
    while (query.next()) list.append(rowToDon(query));
    return Result<QList<Don>>::success(list);
}

Result<std::optional<Don>> SqliteDonRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM dons WHERE id = ? AND valide = 1").arg(kDonCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Don>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Don>>::success(rowToDon(query));
    return Result<std::optional<Don>>::success(std::nullopt);
}

Result<int> SqliteDonRepository::create(const Don& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO dons (donateur_id, projet_id, montant, date_don,"
        " nature_don, mode_paiement, description_materiel, valeur_estimee, etat_materiel, justificatif_path)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.donateurId);
    // projet_id : NULL si pas d'affectation (évite la violation de FK avec -1)
    query.addBindValue(entity.projetId > 0 ? QVariant(entity.projetId) : QVariant());
    query.addBindValue(entity.montant);
    query.addBindValue(entity.dateDon.isValid() ? entity.dateDon.toString(Qt::ISODate) : QDate::currentDate().toString(Qt::ISODate));
    query.addBindValue(entity.natureDon.isEmpty()    ? QStringLiteral("Numéraire") : entity.natureDon);
    query.addBindValue(entity.modePaiement.isEmpty() ? QStringLiteral("Espèces")   : entity.modePaiement);
    query.addBindValue(entity.descriptionMateriel);
    query.addBindValue(entity.valeurEstimee);
    query.addBindValue(entity.etatMateriel.isEmpty() ? QStringLiteral("Neuf") : entity.etatMateriel);
    query.addBindValue(entity.justificatifPath);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteDonRepository::update(const Don& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE dons SET donateur_id=?, projet_id=?, montant=?, date_don=?,"
        " nature_don=?, mode_paiement=?, description_materiel=?, valeur_estimee=?, etat_materiel=?, justificatif_path=?"
        " , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.donateurId);
    query.addBindValue(entity.projetId > 0 ? QVariant(entity.projetId) : QVariant());
    query.addBindValue(entity.montant);
    query.addBindValue(entity.dateDon.toString(Qt::ISODate));
    query.addBindValue(entity.natureDon);
    query.addBindValue(entity.modePaiement);
    query.addBindValue(entity.descriptionMateriel);
    query.addBindValue(entity.valeurEstimee);
    query.addBindValue(entity.etatMateriel);
    query.addBindValue(entity.justificatifPath);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteDonRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE dons SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Don>> SqliteDonRepository::getByProjetId(int projetId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM dons WHERE projet_id = ? AND valide = 1").arg(kDonCols));
    query.addBindValue(projetId);
    if (!query.exec()) return Result<QList<Don>>::error(query.lastError().text());
    QList<Don> list;
    while (query.next()) list.append(rowToDon(query));
    return Result<QList<Don>>::success(list);
}

Result<double> SqliteDonRepository::getTotalByProjet(int projetId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT COALESCE(SUM(CASE WHEN nature_don='Nature' THEN valeur_estimee ELSE montant END), 0) "
        " FROM dons WHERE valide = 1 AND projet_id = ?"));
    query.addBindValue(projetId);
    if (!query.exec()) return Result<double>::error(query.lastError().text());
    query.next();
    return Result<double>::success(query.value(0).toDouble());
}

// ═══════════════════════════════════════════════════════════════
// SqliteDepenseRepository
// ═══════════════════════════════════════════════════════════════

static const auto kDepenseCols = QStringLiteral(
    "id, libelle, montant, date, categorie, justificatif_path, notes");

static Depense rowToDepense(const QSqlQuery& q) {
    Depense d;
    d.id               = q.value(0).toInt();
    d.libelle          = q.value(1).toString();
    d.montant          = q.value(2).toDouble();
    d.date             = QDate::fromString(q.value(3).toString(), Qt::ISODate);
    d.categorie        = q.value(4).toString();
    d.justificatifPath = q.value(5).toString();
    d.notes            = q.value(6).toString();
    return d;
}

SqliteDepenseRepository::SqliteDepenseRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<Depense>> SqliteDepenseRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral("SELECT %1 FROM depenses WHERE valide = 1 ORDER BY date DESC").arg(kDepenseCols)))
        return Result<QList<Depense>>::error(query.lastError().text());
    QList<Depense> list;
    while (query.next()) list.append(rowToDepense(query));
    return Result<QList<Depense>>::success(list);
}

Result<std::optional<Depense>> SqliteDepenseRepository::getById(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("SELECT %1 FROM depenses WHERE id = ? AND valide = 1").arg(kDepenseCols));
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<Depense>>::error(query.lastError().text());
    if (query.next()) return Result<std::optional<Depense>>::success(rowToDepense(query));
    return Result<std::optional<Depense>>::success(std::nullopt);
}

Result<int> SqliteDepenseRepository::create(const Depense& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO depenses (libelle, montant, date, categorie, justificatif_path, notes)"
        " VALUES (?, ?, ?, ?, ?, ?)"));
    query.addBindValue(entity.libelle);
    query.addBindValue(entity.montant);
    query.addBindValue(entity.date.isValid() ? entity.date.toString(Qt::ISODate)
                                              : QDate::currentDate().toString(Qt::ISODate));
    query.addBindValue(entity.categorie.isEmpty() ? QStringLiteral("Autre") : entity.categorie);
    query.addBindValue(entity.justificatifPath);
    query.addBindValue(entity.notes);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteDepenseRepository::update(const Depense& entity) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE depenses SET libelle=?, montant=?, date=?, categorie=?, justificatif_path=?, notes=?"
        " , date_modification = datetime('now') WHERE id=?"));
    query.addBindValue(entity.libelle);
    query.addBindValue(entity.montant);
    query.addBindValue(entity.date.isValid() ? entity.date.toString(Qt::ISODate)
                                              : QDate::currentDate().toString(Qt::ISODate));
    query.addBindValue(entity.categorie);
    query.addBindValue(entity.justificatifPath);
    query.addBindValue(entity.notes);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteDepenseRepository::remove(int id) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE depenses SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?"));
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<Depense>> SqliteDepenseRepository::getByMonth(int month, int year) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT %1 FROM depenses "
        " WHERE valide = 1 AND strftime('%m', date) = ? AND strftime('%Y', date) = ?"
        " ORDER BY date DESC").arg(kDepenseCols));
    query.addBindValue(QString::number(month).rightJustified(2, '0'));
    query.addBindValue(QString::number(year));
    if (!query.exec()) return Result<QList<Depense>>::error(query.lastError().text());
    QList<Depense> list;
    while (query.next()) list.append(rowToDepense(query));
    return Result<QList<Depense>>::success(list);
}

// ─── SqliteTarifMensualiteRepository ─────────────────────────────────────────

static TarifMensualite rowToTarif(const QSqlQuery& q) {
    TarifMensualite t;
    t.id               = q.value(0).toInt();
    t.categorie        = q.value(1).toString();
    t.anneeScolaireId  = q.value(2).toInt();
    t.montant          = q.value(3).toDouble();
    return t;
}

SqliteTarifMensualiteRepository::SqliteTarifMensualiteRepository(const QString& connectionName)
    : m_connectionName(connectionName) {}

Result<QList<TarifMensualite>> SqliteTarifMensualiteRepository::getAll() {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(QStringLiteral(
            "SELECT t.id, t.categorie, t.annee_scolaire_id, t.montant "
            "FROM tarifs_mensualites t "
            "LEFT JOIN annees_scolaires a ON a.id = t.annee_scolaire_id "
            "WHERE t.valide = 1 ORDER BY a.libelle, t.categorie")))
        return Result<QList<TarifMensualite>>::error(query.lastError().text());
    QList<TarifMensualite> list;
    while (query.next()) list.append(rowToTarif(query));
    return Result<QList<TarifMensualite>>::success(list);
}

Result<QList<TarifMensualite>> SqliteTarifMensualiteRepository::getByYear(const QString& anneeScolaireLibelle) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT t.id, t.categorie, t.annee_scolaire_id, t.montant "
        "FROM tarifs_mensualites t "
        "JOIN annees_scolaires a ON a.id = t.annee_scolaire_id "
        "WHERE a.libelle = ? AND t.valide = 1"));
    query.addBindValue(anneeScolaireLibelle);
    if (!query.exec())
        return Result<QList<TarifMensualite>>::error(query.lastError().text());
    QList<TarifMensualite> list;
    while (query.next()) list.append(rowToTarif(query));
    return Result<QList<TarifMensualite>>::success(list);
}

Result<QList<TarifMensualite>> SqliteTarifMensualiteRepository::getByYearId(int anneeScolaireId) {
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, categorie, annee_scolaire_id, montant "
        "FROM tarifs_mensualites WHERE annee_scolaire_id = ? AND valide = 1"));
    query.addBindValue(anneeScolaireId);
    if (!query.exec())
        return Result<QList<TarifMensualite>>::error(query.lastError().text());
    QList<TarifMensualite> list;
    while (query.next()) list.append(rowToTarif(query));
    return Result<QList<TarifMensualite>>::success(list);
}
