#include "controllers/exams_controller.h"
#include "services/attendance_service.h"
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

static QVariantMap seanceToMap(const Seance& s) {
    return {
        {"id", s.id}, {"matiereId", s.matiereId}, {"profId", s.profId},
        {"salleId", s.salleId}, {"classeId", s.classeId},
        {"dateHeureDebut", s.dateHeureDebut.toString(Qt::ISODate)},
        {"dureeMinutes", s.dureeMinutes},
        {"typeSeance", categorieSeanceToString(s.typeSeance)}
    };
}

ExamsController::ExamsController(AttendanceService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &ExamsController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &ExamsController::onQueryError);
}

void ExamsController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void ExamsController::loadExamsByMonth(int month, int year) {
    setLoading(true);
    m_worker->submit("Exams.loadExamsByMonth", [svc = m_service, month, year]() -> QVariant {
        QDate firstDay(year, month, 1);
        QDateTime from(firstDay, QTime(0, 0));
        QDateTime to(firstDay.addMonths(1).addDays(-1), QTime(23, 59, 59));

        auto result = svc->getSeancesByDateRange(from, to);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& s : result.value()) {
            if (s.typeSeance != GS::CategorieSeance::Cours) {
                list.append(seanceToMap(s));
            }
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
        auto result = svc->createSeance(s);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
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

    if (queryId == "Exams.loadExamsByMonth") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_exams = result.toList(); emit examsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Exams.createExam") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Examen créé");
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

    if (queryId == "Exams.loadExamsByMonth") {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
