#include "controllers/exams_controller.h"
#include "services/attendance_service.h"

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

ExamsController::ExamsController(AttendanceService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void ExamsController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void ExamsController::loadExamsByMonth(int month, int year) {
    setLoading(true);
    QDate firstDay(year, month, 1);
    QDateTime from(firstDay, QTime(0, 0));
    QDateTime to(firstDay.addMonths(1).addDays(-1), QTime(23, 59, 59));

    auto result = m_service->getSeancesByDateRange(from, to);
    if (result.isOk()) {
        m_exams.clear();
        for (const auto& s : result.value()) {
            if (s.typeSeance != GS::CategorieSeance::Cours) {
                m_exams.append(seanceToMap(s));
            }
        }
        emit examsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void ExamsController::createExam(const QVariantMap& data) {
    Seance s;
    s.matiereId = data.value("matiereId").toInt();
    s.profId = data.value("profId").toInt();
    s.salleId = data.value("salleId").toInt();
    s.classeId = data.value("classeId").toInt();
    s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
    s.dureeMinutes = data.value("dureeMinutes", 120).toInt();
    s.typeSeance = stringToCategorieSeance(data.value("typeSeance", "Examen").toString());
    auto result = m_service->createSeance(s);
    if (result.isOk()) emit operationSucceeded("Examen créé");
    else emit operationFailed(result.errorMessage());
}

void ExamsController::updateExam(int id, const QVariantMap& data) {
    Seance s;
    s.id = id;
    s.matiereId = data.value("matiereId").toInt();
    s.profId = data.value("profId").toInt();
    s.salleId = data.value("salleId").toInt();
    s.classeId = data.value("classeId").toInt();
    s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
    s.dureeMinutes = data.value("dureeMinutes", 120).toInt();
    s.typeSeance = stringToCategorieSeance(data.value("typeSeance", "Examen").toString());
    auto result = m_service->updateSeance(s);
    if (result.isOk()) emit operationSucceeded("Examen mis à jour");
    else emit operationFailed(result.errorMessage());
}

void ExamsController::deleteExam(int id) {
    auto result = m_service->deleteSeance(id);
    if (result.isOk()) emit operationSucceeded("Examen supprimé");
    else emit operationFailed(result.errorMessage());
}
