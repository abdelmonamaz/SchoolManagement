#include "controllers/dashboard_controller.h"
#include "services/dashboard_service.h"

static QString categorieSeanceToString(GS::CategorieSeance c) {
    switch (c) {
        case GS::CategorieSeance::Cours: return QStringLiteral("Cours");
        case GS::CategorieSeance::Examen: return QStringLiteral("Examen");
        case GS::CategorieSeance::Evenement: return QStringLiteral("Événement");
    }
    return QStringLiteral("Cours");
}

static QString typePresenceToString(GS::TypePresence t) {
    switch (t) {
        case GS::TypePresence::Present: return QStringLiteral("Présent");
        case GS::TypePresence::Absent: return QStringLiteral("Absent");
        case GS::TypePresence::Retard: return QStringLiteral("Retard");
    }
    return QStringLiteral("Présent");
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

DashboardController::DashboardController(DashboardService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void DashboardController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void DashboardController::loadDashboard() {
    setLoading(true);

    // Total students
    auto studentsResult = m_service->getTotalStudents();
    if (studentsResult.isOk()) m_totalStudents = studentsResult.value();

    // Active courses
    auto coursesResult = m_service->getActiveCoursesCount();
    if (coursesResult.isOk()) m_activeCourses = coursesResult.value();

    // Average attendance
    auto attendanceResult = m_service->getAverageAttendanceRate();
    if (attendanceResult.isOk()) m_averageAttendance = attendanceResult.value();

    // School average
    auto avgResult = m_service->getSchoolAverage();
    if (avgResult.isOk()) m_schoolAverage = avgResult.value();

    // Live sessions
    auto liveResult = m_service->getLiveSessions();
    if (liveResult.isOk()) {
        m_liveSessions.clear();
        for (const auto& s : liveResult.value()) m_liveSessions.append(seanceToMap(s));
    }

    // Recent grades
    auto gradesResult = m_service->getRecentGrades(10);
    if (gradesResult.isOk()) {
        m_recentGrades.clear();
        for (const auto& p : gradesResult.value()) m_recentGrades.append(participationToMap(p));
    }

    // Upcoming exams
    auto examsResult = m_service->getUpcomingExams(5);
    if (examsResult.isOk()) {
        m_upcomingExams.clear();
        for (const auto& s : examsResult.value()) m_upcomingExams.append(seanceToMap(s));
    }

    emit dataChanged();
    setLoading(false);
}
