#include "controllers/exams_controller.h"
#include "services/attendance_service.h"
#include "services/schooling_service.h"
#include "services/staff_service.h"
#include "database/database_worker.h"

#include <QDate>

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

// Build a rich map with resolved entity names
static QVariantMap seanceToRichMap(const Seance& s,
                                   const QHash<int, QString>& matiereNames,
                                   const QHash<int, QString>& profNames,
                                   const QHash<int, QString>& classeNames,
                                   const QHash<int, QString>& salleNames)
{
    QString dayName;
    int dow = s.dateHeureDebut.date().dayOfWeek(); // 1=Mon, 7=Sun
    switch (dow) {
        case 1: dayName = QStringLiteral("Lundi"); break;
        case 2: dayName = QStringLiteral("Mardi"); break;
        case 3: dayName = QStringLiteral("Mercredi"); break;
        case 4: dayName = QStringLiteral("Jeudi"); break;
        case 5: dayName = QStringLiteral("Vendredi"); break;
        case 6: dayName = QStringLiteral("Samedi"); break;
        case 7: dayName = QStringLiteral("Dimanche"); break;
    }

    return {
        {"id", s.id},
        {"matiereId", s.matiereId},
        {"profId", s.profId},
        {"salleId", s.salleId},
        {"classeId", s.classeId},
        {"dateHeureDebut", s.dateHeureDebut.toString(Qt::ISODate)},
        {"dureeMinutes", s.dureeMinutes},
        {"typeSeance", categorieSeanceToString(s.typeSeance)},
        {"titre", s.titre},
        {"descriptif", s.descriptif},
        // Resolved names
        {"subject", matiereNames.value(s.matiereId, QStringLiteral("—"))},
        {"professor", profNames.value(s.profId, QStringLiteral("—"))},
        {"className", classeNames.value(s.classeId, QStringLiteral("—"))},
        {"room", salleNames.value(s.salleId, QStringLiteral("—"))},
        // Convenience fields
        {"day", dayName},
        {"dayOfMonth", s.dateHeureDebut.date().day()},
        {"time", s.dateHeureDebut.time().toString(QStringLiteral("HH:mm"))}
    };
}

// Helper: build lookup hashes from services
struct LookupData {
    QHash<int, QString> matiereNames;
    QHash<int, QString> profNames;
    QHash<int, QString> classeNames;
    QHash<int, QString> salleNames;
};

static LookupData buildLookups(SchoolingService* schoolingSvc, StaffService* staffSvc) {
    LookupData d;

    auto matieres = schoolingSvc->getAllMatieres();
    if (matieres.isOk()) {
        for (const auto& m : matieres.value())
            d.matiereNames.insert(m.id, m.nom);
    }

    auto classes = schoolingSvc->getAllClasses();
    if (classes.isOk()) {
        for (const auto& c : classes.value())
            d.classeNames.insert(c.id, c.nom);
    }

    auto salles = schoolingSvc->getAllSalles();
    if (salles.isOk()) {
        for (const auto& s : salles.value())
            d.salleNames.insert(s.id, s.nom);
    }

    auto profs = staffSvc->getAllPersonnel();
    if (profs.isOk()) {
        for (const auto& p : profs.value())
            d.profNames.insert(p.id, p.nom);
    }

    return d;
}

// Helper: compute ISO week date range
static QPair<QDateTime, QDateTime> weekDateRange(int week, int year) {
    // ISO 8601: Week 1 contains Jan 4
    QDate jan4(year, 1, 4);
    int dow = jan4.dayOfWeek(); // 1=Mon
    QDate mondayW1 = jan4.addDays(1 - dow);
    QDate monday = mondayW1.addDays((week - 1) * 7);
    QDate sunday = monday.addDays(6);
    return { QDateTime(monday, QTime(0, 0)), QDateTime(sunday, QTime(23, 59, 59)) };
}

ExamsController::ExamsController(AttendanceService* service,
                                 SchoolingService* schoolingService,
                                 StaffService* staffService,
                                 DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service),
      m_schoolingService(schoolingService), m_staffService(staffService),
      m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &ExamsController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &ExamsController::onQueryError);
}

void ExamsController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void ExamsController::loadExamsByMonth(int month, int year) {
    setLoading(true);
    m_worker->submit("Exams.loadExamsByMonth",
        [svc = m_service, schoolingSvc = m_schoolingService, staffSvc = m_staffService, month, year]() -> QVariant {
        QDate firstDay(year, month, 1);
        QDateTime from(firstDay, QTime(0, 0));
        QDateTime to(firstDay.addMonths(1).addDays(-1), QTime(23, 59, 59));

        auto result = svc->getSeancesByDateRange(from, to);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        auto lookups = buildLookups(schoolingSvc, staffSvc);

        QVariantList list;
        for (const auto& s : result.value()) {
            if (s.typeSeance != GS::CategorieSeance::Cours) {
                list.append(seanceToRichMap(s, lookups.matiereNames, lookups.profNames,
                                            lookups.classeNames, lookups.salleNames));
            }
        }
        return list;
    });
}

void ExamsController::loadAllSessionsByMonth(int month, int year) {
    setLoading(true);
    m_worker->submit("Exams.loadAllSessionsByMonth",
        [svc = m_service, schoolingSvc = m_schoolingService, staffSvc = m_staffService, month, year]() -> QVariant {
        QDate firstDay(year, month, 1);
        QDateTime from(firstDay, QTime(0, 0));
        QDateTime to(firstDay.addMonths(1).addDays(-1), QTime(23, 59, 59));

        auto result = svc->getSeancesByDateRange(from, to);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        auto lookups = buildLookups(schoolingSvc, staffSvc);

        QVariantList list;
        for (const auto& s : result.value()) {
            list.append(seanceToRichMap(s, lookups.matiereNames, lookups.profNames,
                                        lookups.classeNames, lookups.salleNames));
        }
        return list;
    });
}

void ExamsController::loadSessionsByWeek(int week, int year) {
    setLoading(true);
    m_worker->submit("Exams.loadSessionsByWeek",
        [svc = m_service, schoolingSvc = m_schoolingService, staffSvc = m_staffService, week, year]() -> QVariant {
        auto [from, to] = weekDateRange(week, year);

        auto result = svc->getSeancesByDateRange(from, to);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        auto lookups = buildLookups(schoolingSvc, staffSvc);

        QVariantList list;
        for (const auto& s : result.value()) {
            list.append(seanceToRichMap(s, lookups.matiereNames, lookups.profNames,
                                        lookups.classeNames, lookups.salleNames));
        }
        return list;
    });
}

void ExamsController::createExam(const QVariantMap& data) {
    m_worker->submit("Exams.createExam", [svc = m_service, data]() -> QVariant {
        Seance s;
        s.matiereId = data.value("matiereId").toInt();
        s.profId = data.value("profId").toInt();
        s.salleId = data.value("salleId").toInt();
        s.classeId = data.value("classeId").toInt();
        s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
        s.dureeMinutes = data.value("dureeMinutes", 120).toInt();
        s.typeSeance = stringToCategorieSeance(data.value("typeSeance", "Examen").toString());
        s.titre = data.value("titre").toString();
        s.descriptif = data.value("descriptif").toString();
        auto result = svc->createSeance(s);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void ExamsController::createCourseWithRecurrence(const QVariantMap& data, const QString& recurrence) {
    m_worker->submit("Exams.createCourseWithRecurrence", [svc = m_service, data, recurrence]() -> QVariant {
        Seance base;
        base.matiereId = data.value("matiereId").toInt();
        base.profId = data.value("profId").toInt();
        base.salleId = data.value("salleId").toInt();
        base.classeId = data.value("classeId").toInt();
        base.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
        base.dureeMinutes = data.value("dureeMinutes", 120).toInt();
        base.typeSeance = GS::CategorieSeance::Cours;

        if (recurrence == QStringLiteral("none")) {
            auto result = svc->createSeance(base);
            if (!result.isOk())
                return QVariantMap{{"error", result.errorMessage()}};
            return QVariantMap{{"success", true}, {"count", 1}};
        }

        // Determine date range for recurrence
        int year = base.dateHeureDebut.date().year();
        QDate endDate;
        QDate startDate = base.dateHeureDebut.date();

        if (recurrence == QStringLiteral("full")) {
            // Full school year: September to June
            if (startDate.month() >= 9) {
                startDate = QDate(year, 9, 1);
                endDate = QDate(year + 1, 6, 30);
            } else {
                startDate = QDate(year - 1, 9, 1);
                endDate = QDate(year, 6, 30);
            }
            // Find the first occurrence of the same day-of-week on or after startDate
            int targetDow = base.dateHeureDebut.date().dayOfWeek();
            int startDow = startDate.dayOfWeek();
            int diff = targetDow - startDow;
            if (diff < 0) diff += 7;
            startDate = startDate.addDays(diff);
        } else {
            // "remaining": from current date to end of school year (June)
            if (startDate.month() >= 9) {
                endDate = QDate(year + 1, 6, 30);
            } else {
                endDate = QDate(year, 6, 30);
            }
        }

        int count = 0;
        QDate current = startDate;
        QTime baseTime = base.dateHeureDebut.time();

        while (current <= endDate) {
            Seance s = base;
            s.dateHeureDebut = QDateTime(current, baseTime);
            auto result = svc->createSeance(s);
            if (!result.isOk())
                return QVariantMap{{"error", result.errorMessage()}, {"created", count}};
            count++;
            current = current.addDays(7);
        }

        return QVariantMap{{"success", true}, {"count", count}};
    });
}

void ExamsController::updateExam(int id, const QVariantMap& data) {
    m_worker->submit("Exams.updateExam", [svc = m_service, id, data]() -> QVariant {
        Seance s;
        s.id = id;
        s.matiereId = data.value("matiereId").toInt();
        s.profId = data.value("profId").toInt();
        s.salleId = data.value("salleId").toInt();
        s.classeId = data.value("classeId").toInt();
        s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
        s.dureeMinutes = data.value("dureeMinutes", 120).toInt();
        s.typeSeance = stringToCategorieSeance(data.value("typeSeance", "Examen").toString());
        s.titre = data.value("titre").toString();
        s.descriptif = data.value("descriptif").toString();
        auto result = svc->updateSeance(s);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void ExamsController::deleteExam(int id) {
    m_worker->submit("Exams.deleteExam", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteSeance(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void ExamsController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Exams.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Exams.loadExamsByMonth" || queryId == "Exams.loadAllSessionsByMonth") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_exams = result.toList(); emit examsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Exams.loadSessionsByWeek") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_weekSessions = result.toList(); emit weekSessionsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Exams.createExam" || queryId == "Exams.createCourseWithRecurrence") {
        if (isError) emit operationFailed(map["error"].toString());
        else {
            int count = map.value("count", 1).toInt();
            if (count > 1)
                emit operationSucceeded(QString("%1 sessions créées").arg(count));
            else
                emit operationSucceeded("Session créée");
        }
    }
    else if (queryId == "Exams.updateExam") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Examen mis à jour");
    }
    else if (queryId == "Exams.deleteExam") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Examen supprimé");
    }
}

void ExamsController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Exams.")) return;

    if (queryId == "Exams.loadExamsByMonth" || queryId == "Exams.loadAllSessionsByMonth"
        || queryId == "Exams.loadSessionsByWeek") {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
