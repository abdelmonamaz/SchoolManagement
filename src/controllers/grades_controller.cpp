#include "controllers/grades_controller.h"
#include "services/grades_service.h"

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

GradesController::GradesController(GradesService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void GradesController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void GradesController::loadGradesBySeance(int seanceId) {
    setLoading(true);
    auto result = m_service->getGradesBySeance(seanceId);
    if (result.isOk()) {
        m_grades.clear();
        for (const auto& p : result.value()) m_grades.append(participationToMap(p));
        emit gradesChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void GradesController::loadGradesByStudent(int eleveId) {
    setLoading(true);
    auto result = m_service->getGradesByStudent(eleveId);
    if (result.isOk()) {
        m_grades.clear();
        for (const auto& p : result.value()) m_grades.append(participationToMap(p));
        emit gradesChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void GradesController::saveGrade(int participationId, double note) {
    auto result = m_service->saveGrade(participationId, note);
    if (result.isOk()) emit operationSucceeded("Note enregistrée");
    else emit operationFailed(result.errorMessage());
}

void GradesController::saveGrades(const QVariantList& grades) {
    QList<QPair<int, double>> gradesList;
    for (const auto& g : grades) {
        auto map = g.toMap();
        gradesList.append({map.value("participationId").toInt(), map.value("note").toDouble()});
    }
    auto result = m_service->saveGrades(gradesList);
    if (result.isOk()) emit operationSucceeded("Notes enregistrées");
    else emit operationFailed(result.errorMessage());
}

void GradesController::loadClassAverage(int seanceId) {
    auto result = m_service->calculateAverage(seanceId);
    if (result.isOk()) {
        m_classAverage = result.value();
        emit classAverageChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
}
