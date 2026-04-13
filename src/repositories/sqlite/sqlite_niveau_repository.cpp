#include "repositories/sqlite/sqlite_niveau_repository.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

// --- SqliteNiveauRepository ---

SqliteNiveauRepository::SqliteNiveauRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Niveau>> SqliteNiveauRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec(
            "SELECT n.id, n.nom, COALESCE(n.parent_level_id,0), n.annee_scolaire_id, COALESCE(n.is_freestyle,0) "
            "FROM niveaux n "
            "JOIN annees_scolaires a ON n.annee_scolaire_id = a.id "
            "WHERE n.valide = 1 AND a.statut = 'Active' AND a.valide = 1 "
            "ORDER BY n.id")) {
        return Result<QList<Niveau>>::error(query.lastError().text());
    }

    QList<Niveau> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .parentLevelId = query.value(2).toInt(),
            .anneeScolaireId = query.value(3).toInt(),
            .isFreestyle = query.value(4).toBool()
        });
    }
    qDebug() << "[NiveauRepo::getAll] =>" << list.size() << "niveaux. IDs:"
             << [&]{ QStringList s; for (const auto& n : list) s << QString("%1(%2,annee=%3)").arg(n.id).arg(n.nom).arg(n.anneeScolaireId); return s.join(","); }();
    return Result<QList<Niveau>>::success(std::move(list));
}

Result<std::optional<Niveau>> SqliteNiveauRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, COALESCE(parent_level_id, 0), COALESCE(annee_scolaire_id, 0), COALESCE(is_freestyle, 0) FROM niveaux WHERE id = ? AND valide = 1");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Niveau>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Niveau>>::success(std::nullopt);
    }
    return Result<std::optional<Niveau>>::success(Niveau{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .parentLevelId = query.value(2).toInt(),
        .anneeScolaireId = query.value(3).toInt(),
        .isFreestyle = query.value(4).toBool()
    });
}

Result<int> SqliteNiveauRepository::create(const Niveau& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);

    // Resolve active year
    QSqlQuery qYear(db);
    qYear.exec("SELECT id FROM annees_scolaires WHERE statut='Active' AND valide=1 LIMIT 1");
    const int activeYearId = qYear.next() ? qYear.value(0).toInt() : 0;

    QSqlQuery query(db);
    query.prepare("INSERT INTO niveaux (nom, parent_level_id, annee_scolaire_id, is_freestyle) VALUES (?, NULLIF(?, 0), NULLIF(?, 0), ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.parentLevelId);
    query.addBindValue(activeYearId > 0 ? activeYearId : entity.anneeScolaireId);
    query.addBindValue(entity.isFreestyle ? 1 : 0);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    const int newId = query.lastInsertId().toInt();
    return Result<int>::success(newId);
}

Result<bool> SqliteNiveauRepository::update(const Niveau& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    // annee_scolaire_id : si 0, on preserve l'existant (COALESCE) pour ne pas casser le lien avec l'année
    query.prepare("UPDATE niveaux SET nom = ?, parent_level_id = NULLIF(?, 0), "
                  "annee_scolaire_id = COALESCE(NULLIF(?, 0), annee_scolaire_id), "
                  "is_freestyle = ?, date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.parentLevelId);
    query.addBindValue(entity.anneeScolaireId);
    query.addBindValue(entity.isFreestyle ? 1 : 0);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteNiveauRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE niveaux SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<QList<Niveau>> SqliteNiveauRepository::getAllGlobal()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec(
            "SELECT id, nom, COALESCE(parent_level_id,0), COALESCE(annee_scolaire_id,0), COALESCE(is_freestyle,0) "
            "FROM niveaux WHERE valide = 1 ORDER BY id")) {
        return Result<QList<Niveau>>::error(query.lastError().text());
    }
    QList<Niveau> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .parentLevelId = query.value(2).toInt(),
            .anneeScolaireId = query.value(3).toInt(),
            .isFreestyle = query.value(4).toBool()
        });
    }
    return Result<QList<Niveau>>::success(std::move(list));
}

Result<bool> SqliteNiveauRepository::removeAndDetachChildren(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    q.prepare("UPDATE niveaux SET valide = 0, date_invalidation = datetime('now'), "
              "date_modification = datetime('now') WHERE id = ?");
    q.addBindValue(id);
    if (!q.exec())
        return Result<bool>::error(q.lastError().text());

    QSqlQuery fix(db);
    fix.prepare("UPDATE niveaux SET parent_level_id = NULL WHERE parent_level_id = ?");
    fix.addBindValue(id);
    fix.exec(); // non-fatal if this fails

    return Result<bool>::success(true);
}

// --- SqliteClasseRepository ---

SqliteClasseRepository::SqliteClasseRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Classe>> SqliteClasseRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec("SELECT id, nom, niveau_id FROM classes WHERE valide = 1")) {
        return Result<QList<Classe>>::error(query.lastError().text());
    }

    QList<Classe> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt()
        });
    }
    return Result<QList<Classe>>::success(std::move(list));
}

Result<std::optional<Classe>> SqliteClasseRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id FROM classes WHERE id = ? AND valide = 1");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Classe>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Classe>>::success(std::nullopt);
    }
    return Result<std::optional<Classe>>::success(Classe{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .niveauId = query.value(2).toInt()
    });
}

Result<int> SqliteClasseRepository::create(const Classe& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO classes (nom, niveau_id) VALUES (?, ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteClasseRepository::update(const Classe& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE classes SET nom = ?, niveau_id = ? , date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteClasseRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);

    if (!db.transaction())
        return Result<bool>::error("Transaction impossible: " + db.lastError().text());

    QSqlQuery query(db);

    // 1. Supprimer les séances liées aux cours et examens de cette classe.
    //    ON DELETE CASCADE sur seances → supprime en cascade participations, cours et examens.
    query.prepare(
        "DELETE FROM seances WHERE id IN ("
        "  SELECT seance_id FROM cours    WHERE classe_id = ? "
        "  UNION "
        "  SELECT seance_id FROM examens  WHERE classe_id = ?"
        ")");
    query.addBindValue(id);
    query.addBindValue(id);
    if (!query.exec()) {
        db.rollback();
        return Result<bool>::error("Erreur suppression séances: " + query.lastError().text());
    }

    // 2. Libérer l'affectation de classe dans les inscriptions (classe normale)
    query.prepare("UPDATE inscriptions_eleves SET classe_id = NULL WHERE classe_id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        db.rollback();
        return Result<bool>::error("Erreur nullification classe_id: " + query.lastError().text());
    }

    // 3. Libérer l'affectation de salle dans les inscriptions (niveau de type hall/freestyle)
    query.prepare("UPDATE inscriptions_eleves SET hall_classe_id = NULL WHERE hall_classe_id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        db.rollback();
        return Result<bool>::error("Erreur nullification hall_classe_id: " + query.lastError().text());
    }

    // 4. Suppression douce de la classe
    query.prepare("UPDATE classes SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        db.rollback();
        return Result<bool>::error(query.lastError().text());
    }

    if (!db.commit()) {
        db.rollback();
        return Result<bool>::error("Erreur commit: " + db.lastError().text());
    }

    return Result<bool>::success(true);
}

Result<QList<Classe>> SqliteClasseRepository::getByNiveauId(int niveauId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, nom, niveau_id FROM classes WHERE niveau_id = ? AND valide = 1");
    query.addBindValue(niveauId);

    if (!query.exec()) {
        return Result<QList<Classe>>::error(query.lastError().text());
    }

    QList<Classe> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt()
        });
    }
    qDebug() << "[ClasseRepo::getByNiveauId] niveauId=" << niveauId << "=>" << list.size() << "classes:"
             << [&]{ QStringList s; for (const auto& c : list) s << QString("%1(%2)").arg(c.id).arg(c.nom); return s.join(","); }();
    return Result<QList<Classe>>::success(std::move(list));
}

// --- SqliteMatiereRepository ---

SqliteMatiereRepository::SqliteMatiereRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<Matiere>> SqliteMatiereRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);

    if (!query.exec(
            "SELECT m.id, m.nom, m.niveau_id, m.nombre_seances, m.duree_seance_minutes, "
            "       COALESCE(s.numero, 0), COALESCE(m.coefficient, 1.0) "
            "FROM matieres m "
            "LEFT JOIN semestres s ON m.semestre_id = s.id "
            "WHERE m.valide = 1")) {
        return Result<QList<Matiere>>::error(query.lastError().text());
    }

    QList<Matiere> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt(),
            .nombreSeances = query.value(3).toInt(),
            .dureeSeanceMinutes = query.value(4).toInt(),
            .semestreNumero = query.value(5).toInt(),
            .coefficient = query.value(6).toDouble()
        });
    }
    return Result<QList<Matiere>>::success(std::move(list));
}

Result<std::optional<Matiere>> SqliteMatiereRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(
        "SELECT m.id, m.nom, m.niveau_id, m.nombre_seances, m.duree_seance_minutes, "
        "       COALESCE(s.numero, 0), COALESCE(m.coefficient, 1.0) "
        "FROM matieres m "
        "LEFT JOIN semestres s ON m.semestre_id = s.id "
        "WHERE m.id = ? AND m.valide = 1");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<std::optional<Matiere>>::error(query.lastError().text());
    }
    if (!query.next()) {
        return Result<std::optional<Matiere>>::success(std::nullopt);
    }
    return Result<std::optional<Matiere>>::success(Matiere{
        .id = query.value(0).toInt(),
        .nom = query.value(1).toString(),
        .niveauId = query.value(2).toInt(),
        .nombreSeances = query.value(3).toInt(),
        .dureeSeanceMinutes = query.value(4).toInt(),
        .semestreNumero = query.value(5).toInt(),
        .coefficient = query.value(6).toDouble()
    });
}

Result<int> SqliteMatiereRepository::create(const Matiere& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO matieres (nom, niveau_id, nombre_seances, duree_seance_minutes, coefficient) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.nombreSeances);
    query.addBindValue(entity.dureeSeanceMinutes);
    query.addBindValue(entity.coefficient > 0 ? entity.coefficient : 1.0);

    if (!query.exec()) {
        return Result<int>::error(query.lastError().text());
    }
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteMatiereRepository::update(const Matiere& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matieres SET nom = ?, niveau_id = ?, nombre_seances = ?, duree_seance_minutes = ?, coefficient = ?, date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.nom);
    query.addBindValue(entity.niveauId);
    query.addBindValue(entity.nombreSeances);
    query.addBindValue(entity.dureeSeanceMinutes);
    query.addBindValue(entity.coefficient > 0 ? entity.coefficient : 1.0);
    query.addBindValue(entity.id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<bool> SqliteMatiereRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matieres SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        return Result<bool>::error(query.lastError().text());
    }
    return Result<bool>::success(true);
}

Result<QList<Matiere>> SqliteMatiereRepository::getByNiveauId(int niveauId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare(
        "SELECT m.id, m.nom, m.niveau_id, m.nombre_seances, m.duree_seance_minutes, "
        "       COALESCE(s.numero, 0), COALESCE(m.coefficient, 1.0) "
        "FROM matieres m "
        "LEFT JOIN semestres s ON m.semestre_id = s.id "
        "WHERE m.niveau_id = ? AND m.valide = 1");
    query.addBindValue(niveauId);

    if (!query.exec()) {
        return Result<QList<Matiere>>::error(query.lastError().text());
    }

    QList<Matiere> list;
    while (query.next()) {
        list.append({
            .id = query.value(0).toInt(),
            .nom = query.value(1).toString(),
            .niveauId = query.value(2).toInt(),
            .nombreSeances = query.value(3).toInt(),
            .dureeSeanceMinutes = query.value(4).toInt(),
            .semestreNumero = query.value(5).toInt(),
            .coefficient = query.value(6).toDouble()
        });
    }
    return Result<QList<Matiere>>::success(std::move(list));
}

Result<bool> SqliteMatiereRepository::setMatiereSemestre(int matiereId, int semestreNumero)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);

    if (semestreNumero <= 0) {
        q.prepare(QStringLiteral(
            "UPDATE matieres SET semestre_id = NULL, date_modification = datetime('now') "
            "WHERE id = ? AND valide = 1"));
        q.addBindValue(matiereId);
    } else {
        q.prepare(QStringLiteral(
            "UPDATE matieres SET "
            "  semestre_id = (SELECT s.id FROM semestres s "
            "                 JOIN annees_scolaires a ON s.annee_scolaire_id = a.id "
            "                 WHERE s.numero = ? AND a.statut = 'Active' AND a.valide = 1 "
            "                 AND s.valide = 1 LIMIT 1), "
            "  date_modification = datetime('now') "
            "WHERE id = ? AND valide = 1"));
        q.addBindValue(semestreNumero);
        q.addBindValue(matiereId);
    }

    if (!q.exec())
        return Result<bool>::error(q.lastError().text());
    return Result<bool>::success(true);
}

// --- SqliteMatiereExamenRepository ---

SqliteMatiereExamenRepository::SqliteMatiereExamenRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<MatiereExamen>> SqliteMatiereExamenRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    QString sql = "SELECT me.id, me.matiere_id, me.type_examen_id, te.titre "
                  "FROM matiere_examens me "
                  "JOIN type_examen te ON me.type_examen_id = te.id "
                  "WHERE me.valide = 1 "
                  "ORDER BY me.id";
    if (!query.exec(sql))
        return Result<QList<MatiereExamen>>::error(query.lastError().text());
    QList<MatiereExamen> list;
    while (query.next())
        list.append({ .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .typeExamenId = query.value(2).toInt(), .titre = query.value(3).toString() });
    return Result<QList<MatiereExamen>>::success(std::move(list));
}

Result<std::optional<MatiereExamen>> SqliteMatiereExamenRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT me.id, me.matiere_id, me.type_examen_id, te.titre "
                  "FROM matiere_examens me "
                  "JOIN type_examen te ON me.type_examen_id = te.id "
                  "WHERE me.id = ? AND me.valide = 1");
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<MatiereExamen>>::error(query.lastError().text());
    if (!query.next()) return Result<std::optional<MatiereExamen>>::success(std::nullopt);
    return Result<std::optional<MatiereExamen>>::success(MatiereExamen{
        .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .typeExamenId = query.value(2).toInt(), .titre = query.value(3).toString()
    });
}

Result<int> SqliteMatiereExamenRepository::create(const MatiereExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("INSERT INTO matiere_examens (matiere_id, type_examen_id) VALUES (?, ?)");
    query.addBindValue(entity.matiereId);
    query.addBindValue(entity.typeExamenId);
    if (!query.exec()) return Result<int>::error(query.lastError().text());
    return Result<int>::success(query.lastInsertId().toInt());
}

Result<bool> SqliteMatiereExamenRepository::update(const MatiereExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matiere_examens SET type_examen_id = ?, date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.typeExamenId);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteMatiereExamenRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE matiere_examens SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<QList<MatiereExamen>> SqliteMatiereExamenRepository::getByMatiereId(int matiereId)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT me.id, me.matiere_id, me.type_examen_id, te.titre "
                  "FROM matiere_examens me "
                  "JOIN type_examen te ON me.type_examen_id = te.id "
                  "WHERE me.matiere_id = ? AND me.valide = 1 ORDER BY me.id");
    query.addBindValue(matiereId);
    if (!query.exec()) return Result<QList<MatiereExamen>>::error(query.lastError().text());
    QList<MatiereExamen> list;
    while (query.next())
        list.append({ .id = query.value(0).toInt(), .matiereId = query.value(1).toInt(), .typeExamenId = query.value(2).toInt(), .titre = query.value(3).toString() });
    return Result<QList<MatiereExamen>>::success(std::move(list));
}

// --- SqliteTypeExamenRepository ---

SqliteTypeExamenRepository::SqliteTypeExamenRepository(QString connectionName)
    : m_connectionName(std::move(connectionName)) {}

Result<QList<TypeExamen>> SqliteTypeExamenRepository::getAll()
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    if (!query.exec("SELECT id, titre FROM type_examen WHERE valide = 1 ORDER BY titre"))
        return Result<QList<TypeExamen>>::error(query.lastError().text());
    QList<TypeExamen> list;
    while (query.next())
        list.append({ .id = query.value(0).toInt(), .titre = query.value(1).toString() });
    return Result<QList<TypeExamen>>::success(std::move(list));
}

Result<std::optional<TypeExamen>> SqliteTypeExamenRepository::getById(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("SELECT id, titre FROM type_examen WHERE id = ? AND valide = 1");
    query.addBindValue(id);
    if (!query.exec()) return Result<std::optional<TypeExamen>>::error(query.lastError().text());
    if (!query.next()) return Result<std::optional<TypeExamen>>::success(std::nullopt);
    return Result<std::optional<TypeExamen>>::success(TypeExamen{
        .id = query.value(0).toInt(), .titre = query.value(1).toString()
    });
}

Result<int> SqliteTypeExamenRepository::create(const TypeExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    const QString normalised = entity.titre.trimmed();

    // Step 1 : re-activate a soft-deleted entry with the same title
    QSqlQuery qReactivate(db);
    qReactivate.prepare(
        "UPDATE type_examen SET valide = 1, date_modification = datetime('now'), date_invalidation = NULL "
        "WHERE LOWER(titre) = LOWER(?) AND valide = 0");
    qReactivate.addBindValue(normalised);
    if (!qReactivate.exec())
        qWarning() << "[TypeExamenRepo::create] re-activate failed:" << qReactivate.lastError().text();
    else if (qReactivate.numRowsAffected() > 0)
        qInfo() << "[TypeExamenRepo::create] re-activated soft-deleted entry:" << normalised;

    // Step 2 : INSERT, ignoring if a valide entry already exists
    QSqlQuery qInsert(db);
    qInsert.prepare("INSERT OR IGNORE INTO type_examen (titre) VALUES (?)");
    qInsert.addBindValue(normalised);
    if (!qInsert.exec())
        return Result<int>::error(qInsert.lastError().text());

    // Step 3 : retrieve the id (works whether it was inserted or already existed)
    QSqlQuery qSelect(db);
    qSelect.prepare("SELECT id FROM type_examen WHERE LOWER(titre) = LOWER(?) AND valide = 1");
    qSelect.addBindValue(normalised);
    if (!qSelect.exec() || !qSelect.next())
        return Result<int>::error(qSelect.lastError().text().isEmpty()
                                  ? "Impossible de récupérer la ligne"
                                  : qSelect.lastError().text());

    int id = qSelect.value(0).toInt();
    qInfo() << "[TypeExamenRepo::create] id=" << id << "titre=" << normalised;
    return Result<int>::success(id);
}

Result<bool> SqliteTypeExamenRepository::update(const TypeExamen& entity)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE type_examen SET titre = ?, date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(entity.titre);
    query.addBindValue(entity.id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}

Result<bool> SqliteTypeExamenRepository::remove(int id)
{
    auto db = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(db);
    query.prepare("UPDATE type_examen SET valide = 0, date_invalidation = datetime('now'), date_modification = datetime('now') WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) return Result<bool>::error(query.lastError().text());
    return Result<bool>::success(true);
}
