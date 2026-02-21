#include "controllers/dashboard_controller.h"
#include "services/dashboard_service.h"
#include "services/schooling_service.h"
#include "services/staff_service.h"
#include "services/student_service.h"
#include "database/database_worker.h"

#include <QDateTime>

DashboardController::DashboardController(DashboardService* service,
                                         SchoolingService* schoolingService,
                                         StaffService* staffService,
                                         StudentService* studentService,
                                         DatabaseWorker* worker,
                                         QObject* parent)
    : QObject(parent), m_service(service),
      m_schoolingService(schoolingService), m_staffService(staffService),
      m_studentService(studentService), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &DashboardController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &DashboardController::onQueryError);
}

void DashboardController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void DashboardController::loadDashboard() {
    setLoading(true);

    m_worker->submit("Dashboard.load",
        [dashSvc = m_service, schoolSvc = m_schoolingService,
         staffSvc = m_staffService, studentSvc = m_studentService]() -> QVariant
    {
        QVariantMap data;

        // Build lookup maps
        QMap<int, QString> salles, matieres, classes, profs, eleves;

        auto sallesR = schoolSvc->getAllSalles();
        if (sallesR.isOk()) for (const auto& s : sallesR.value()) salles[s.id] = s.nom;

        auto matieresR = schoolSvc->getAllMatieres();
        if (matieresR.isOk()) for (const auto& m : matieresR.value()) matieres[m.id] = m.nom;

        auto classesR = schoolSvc->getAllClasses();
        if (classesR.isOk()) for (const auto& c : classesR.value()) classes[c.id] = c.nom;

        auto profsR = staffSvc->getAllPersonnel();
        if (profsR.isOk()) for (const auto& p : profsR.value()) profs[p.id] = p.prenom + " " + p.nom;

        auto elevesR = studentSvc->getAllStudents();
        if (elevesR.isOk()) for (const auto& e : elevesR.value()) eleves[e.id] = e.prenom + " " + e.nom;

        // Scalar stats
        auto studentsResult = dashSvc->getTotalStudents();
        data["totalStudents"] = studentsResult.isOk() ? studentsResult.value() : 0;

        auto coursesResult = dashSvc->getActiveCoursesCount();
        data["activeCourses"] = coursesResult.isOk() ? coursesResult.value() : 0;

        auto attendanceResult = dashSvc->getAverageAttendanceRate();
        data["averageAttendance"] = attendanceResult.isOk() ? attendanceResult.value() : 0.0;

        auto avgResult = dashSvc->getSchoolAverage();
        data["schoolAverage"] = avgResult.isOk() ? avgResult.value() : 0.0;

        // Live sessions (enriched)
        QVariantList liveList;
        auto liveResult = dashSvc->getLiveSessions();
        if (liveResult.isOk()) {
            QDateTime now = QDateTime::currentDateTime();
            for (const auto& s : liveResult.value()) {
                QDateTime end = s.dateHeureDebut.addSecs(s.dureeMinutes * 60);
                int elapsed = s.dateHeureDebut.secsTo(now);
                int total = s.dureeMinutes * 60;
                int progress = total > 0 ? qBound(0, elapsed * 100 / total, 100) : 0;
                QString timeSlot = s.dateHeureDebut.toString("HH:mm") + " - " + end.toString("HH:mm");

                liveList.append(QVariantMap{
                    {"id", s.id},
                    {"room", salles.value(s.salleId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"subject", matieres.value(s.matiereId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"className", classes.value(s.classeId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"prof", profs.value(s.profId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"timeSlot", timeSlot},
                    {"progress", progress}
                });
            }
        }
        data["liveSessions"] = liveList;

        // Recent grades (enriched)
        QVariantList gradesList;
        auto gradesResult = dashSvc->getRecentGrades(10);
        if (gradesResult.isOk()) {
            for (const auto& p : gradesResult.value()) {
                gradesList.append(QVariantMap{
                    {"id", p.id},
                    {"student", eleves.value(p.eleveId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"note", p.note},
                    {"score", QString::number(p.note, 'f', 1) + "/20"}
                });
            }
        }
        data["recentGrades"] = gradesList;

        // Upcoming exams (enriched)
        QVariantList examsList;
        auto examsResult = dashSvc->getUpcomingExams(5);
        if (examsResult.isOk()) {
            for (const auto& s : examsResult.value()) {
                examsList.append(QVariantMap{
                    {"id", s.id},
                    {"title", matieres.value(s.matiereId, QStringLiteral("Examen"))},
                    {"className", classes.value(s.classeId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"room", salles.value(s.salleId, QString::fromUtf8("\xe2\x80\x94"))},
                    {"day", QString::number(s.dateHeureDebut.date().day())},
                    {"month", s.dateHeureDebut.toString("MMM").toUpper()},
                    {"time", s.dateHeureDebut.toString("HH:mm")}
                });
            }
        }
        data["upcomingExams"] = examsList;

        return data;
    });
}

void DashboardController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (queryId != "Dashboard.load") return;

    auto data = result.toMap();

    m_totalStudents = data["totalStudents"].toInt();
    m_activeCourses = data["activeCourses"].toInt();
    m_averageAttendance = data["averageAttendance"].toDouble();
    m_schoolAverage = data["schoolAverage"].toDouble();
    m_liveSessions = data["liveSessions"].toList();
    m_recentGrades = data["recentGrades"].toList();
    m_upcomingExams = data["upcomingExams"].toList();

    emit dataChanged();
    setLoading(false);
}

void DashboardController::onQueryError(const QString& queryId, const QString& error) {
    if (queryId != "Dashboard.load") return;

    m_errorMessage = error;
    emit errorMessageChanged();
    setLoading(false);
}
