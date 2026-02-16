#include "controllers/attendance_controller.h"
#include "services/attendance_service.h"
#include "database/database_worker.h"

static QString categorieSeanceToString(GS::CategorieSeance c) {
    switch (c) {
        case GS::CategorieSeance::Cours: return QStringLiteral("Cours");
        case GS::CategorieSeance::Examen: return QStringLiteral("Examen");
        case GS::CategorieSeance::Evenement: return QStringLiteral("Événement");
    }
    return QStringLiteral("Cours");
}

static GS::CategorieSeance stringToCategorieSeance(const QString& s) {
    if (s == QStringLiteral("Examen")) return GS::CategorieSeance::Examen;
    if (s == QStringLiteral("Événement")) return GS::CategorieSeance::Evenement;
    return GS::CategorieSeance::Cours;
}

static QString typePresenceToString(GS::TypePresence t) {
    switch (t) {
        case GS::TypePresence::Present: return QStringLiteral("Présent");
        case GS::TypePresence::Absent: return QStringLiteral("Absent");
        case GS::TypePresence::Retard: return QStringLiteral("Retard");
    }
    return QStringLiteral("Présent");
}

static GS::TypePresence stringToTypePresence(const QString& s) {
    if (s == QStringLiteral("Absent")) return GS::TypePresence::Absent;
    if (s == QStringLiteral("Retard")) return GS::TypePresence::Retard;
    return GS::TypePresence::Present;
}

static QVariantMap seanceToMap(const Seance& s) {
    return {
        {"id", s.id}, {"matiereId", s.matiereId}, {"profId", s.profId},
        {"salleId", s.salleId}, {"classeId", s.classeId},
        {"dateHeureDebut", s.dateHeureDebut.toString(Qt::ISODate)},
        {"dureeMinutes", s.dureeMinutes},
        {"typeSeance", categorieSeanceToString(s.typeSeance)}
    };
}

static QVariantMap participationToMap(const Participation& p) {
    return {
        {"id", p.id}, {"seanceId", p.seanceId}, {"eleveId", p.eleveId},
        {"statut", typePresenceToString(p.statut)},
        {"note", p.note < 0 ? QVariant() : QVariant(p.note)},
        {"estInvite", p.estInvite}
    };
}

AttendanceController::AttendanceController(AttendanceService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &AttendanceController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &AttendanceController::onQueryError);
}

void AttendanceController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void AttendanceController::loadSeancesByDateRange(const QString& from, const QString& to) {
    setLoading(true);
    m_worker->submit("Attendance.loadSeancesByDateRange", [svc = m_service, from, to]() -> QVariant {
        auto result = svc->getSeancesByDateRange(
            QDateTime::fromString(from, Qt::ISODate),
            QDateTime::fromString(to, Qt::ISODate));
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& s : result.value()) list.append(seanceToMap(s));
        return list;
    });
}

void AttendanceController::loadSeancesByClasse(int classeId) {
    setLoading(true);
    m_worker->submit("Attendance.loadSeancesByClasse", [svc = m_service, classeId]() -> QVariant {
        auto result = svc->getSeancesByClasse(classeId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& s : result.value()) list.append(seanceToMap(s));
        return list;
    });
}

void AttendanceController::createSeance(const QVariantMap& data) {
    m_worker->submit("Attendance.createSeance", [svc = m_service, data]() -> QVariant {
        Seance s;
        s.matiereId = data.value("matiereId").toInt();
        s.profId = data.value("profId").toInt();
        s.salleId = data.value("salleId").toInt();
        s.classeId = data.value("classeId").toInt();
        s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
        s.dureeMinutes = data.value("dureeMinutes", 60).toInt();
        s.typeSeance = stringToCategorieSeance(data.value("typeSeance").toString());
        auto result = svc->createSeance(s);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void AttendanceController::updateSeance(int id, const QVariantMap& data) {
    m_worker->submit("Attendance.updateSeance", [svc = m_service, id, data]() -> QVariant {
        Seance s;
        s.id = id;
        s.matiereId = data.value("matiereId").toInt();
        s.profId = data.value("profId").toInt();
        s.salleId = data.value("salleId").toInt();
        s.classeId = data.value("classeId").toInt();
        s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
        s.dureeMinutes = data.value("dureeMinutes", 60).toInt();
        s.typeSeance = stringToCategorieSeance(data.value("typeSeance").toString());
        auto result = svc->updateSeance(s);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void AttendanceController::deleteSeance(int id) {
    m_worker->submit("Attendance.deleteSeance", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteSeance(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void AttendanceController::loadParticipations(int seanceId) {
    setLoading(true);
    m_worker->submit("Attendance.loadParticipations", [svc = m_service, seanceId]() -> QVariant {
        auto result = svc->getParticipationsBySeance(seanceId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(participationToMap(p));
        return list;
    });
}

void AttendanceController::recordParticipation(const QVariantMap& data) {
    m_worker->submit("Attendance.recordParticipation", [svc = m_service, data]() -> QVariant {
        Participation p;
        p.seanceId = data.value("seanceId").toInt();
        p.eleveId = data.value("eleveId").toInt();
        p.statut = stringToTypePresence(data.value("statut").toString());
        p.note = data.value("note", -1.0).toDouble();
        p.estInvite = data.value("estInvite", false).toBool();
        auto result = svc->recordParticipation(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void AttendanceController::updateParticipation(int id, const QVariantMap& data) {
    m_worker->submit("Attendance.updateParticipation", [svc = m_service, id, data]() -> QVariant {
        Participation p;
        p.id = id;
        p.seanceId = data.value("seanceId").toInt();
        p.eleveId = data.value("eleveId").toInt();
        p.statut = stringToTypePresence(data.value("statut").toString());
        p.note = data.value("note", -1.0).toDouble();
        p.estInvite = data.value("estInvite", false).toBool();
        auto result = svc->updateParticipation(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

// ─── Async result handlers ───

void AttendanceController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Attendance.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Attendance.loadSeancesByDateRange" || queryId == "Attendance.loadSeancesByClasse") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_seances = result.toList(); emit seancesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Attendance.loadParticipations") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_participations = result.toList(); emit participationsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Attendance.createSeance") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Séance créée");
    }
    else if (queryId == "Attendance.updateSeance") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Séance mise à jour");
    }
    else if (queryId == "Attendance.deleteSeance") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Séance supprimée");
    }
    else if (queryId == "Attendance.recordParticipation") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Présence enregistrée");
    }
    else if (queryId == "Attendance.updateParticipation") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Présence mise à jour");
    }
}

void AttendanceController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Attendance.")) return;

    if (queryId.startsWith("Attendance.load")) {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
