#include "controllers/grades_controller.h"
#include "services/grades_service.h"
#include "database/database_worker.h"

static QString typePresenceToString(GS::TypePresence t) {
    switch (t) {
        case GS::TypePresence::Present: return QStringLiteral("Présent");
        case GS::TypePresence::Absent: return QStringLiteral("Absent");
        case GS::TypePresence::Retard: return QStringLiteral("Retard");
    }
    return QStringLiteral("Présent");
}

static QVariantMap participationToMap(const Participation& p) {
    return {
        {"id", p.id}, {"seanceId", p.seanceId}, {"eleveId", p.eleveId},
        {"statut", typePresenceToString(p.statut)},
        {"note", p.note < 0 ? QVariant() : QVariant(p.note)},
        {"estInvite", p.estInvite}
    };
}

GradesController::GradesController(GradesService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &GradesController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &GradesController::onQueryError);
}

void GradesController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void GradesController::loadGradesBySeance(int seanceId) {
    setLoading(true);
    m_worker->submit("Grades.loadGradesBySeance", [svc = m_service, seanceId]() -> QVariant {
        auto result = svc->getGradesBySeance(seanceId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(participationToMap(p));
        return list;
    });
}

void GradesController::loadGradesByStudent(int eleveId) {
    setLoading(true);
    m_worker->submit("Grades.loadGradesByStudent", [svc = m_service, eleveId]() -> QVariant {
        auto result = svc->getGradesByStudent(eleveId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(participationToMap(p));
        return list;
    });
}

void GradesController::saveGrade(int participationId, double note) {
    m_worker->submit("Grades.saveGrade", [svc = m_service, participationId, note]() -> QVariant {
        auto result = svc->saveGrade(participationId, note);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void GradesController::saveGrades(const QVariantList& grades) {
    m_worker->submit("Grades.saveGrades", [svc = m_service, grades]() -> QVariant {
        QList<QPair<int, double>> gradesList;
        for (const auto& g : grades) {
            auto map = g.toMap();
            gradesList.append({map.value("participationId").toInt(), map.value("note").toDouble()});
        }
        auto result = svc->saveGrades(gradesList);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void GradesController::loadClassAverage(int seanceId) {
    m_worker->submit("Grades.loadClassAverage", [svc = m_service, seanceId]() -> QVariant {
        auto result = svc->calculateAverage(seanceId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"average", result.value()}};
    });
}

void GradesController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Grades.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Grades.loadGradesBySeance" || queryId == "Grades.loadGradesByStudent") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_grades = result.toList(); emit gradesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Grades.saveGrade") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Note enregistrée");
    }
    else if (queryId == "Grades.saveGrades") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Notes enregistrées");
    }
    else if (queryId == "Grades.loadClassAverage") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_classAverage = map["average"].toDouble(); emit classAverageChanged(); }
    }
}

void GradesController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Grades.")) return;

    if (queryId.startsWith("Grades.load")) {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
