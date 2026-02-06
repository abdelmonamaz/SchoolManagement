#include "controllers/attendance_controller.h"
#include "services/attendance_service.h"

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

AttendanceController::AttendanceController(AttendanceService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void AttendanceController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void AttendanceController::loadSeancesByDateRange(const QString& from, const QString& to) {
    setLoading(true);
    auto result = m_service->getSeancesByDateRange(
        QDateTime::fromString(from, Qt::ISODate),
        QDateTime::fromString(to, Qt::ISODate));
    if (result.isOk()) {
        m_seances.clear();
        for (const auto& s : result.value()) m_seances.append(seanceToMap(s));
        emit seancesChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void AttendanceController::loadSeancesByClasse(int classeId) {
    setLoading(true);
    auto result = m_service->getSeancesByClasse(classeId);
    if (result.isOk()) {
        m_seances.clear();
        for (const auto& s : result.value()) m_seances.append(seanceToMap(s));
        emit seancesChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void AttendanceController::createSeance(const QVariantMap& data) {
    Seance s;
    s.matiereId = data.value("matiereId").toInt();
    s.profId = data.value("profId").toInt();
    s.salleId = data.value("salleId").toInt();
    s.classeId = data.value("classeId").toInt();
    s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
    s.dureeMinutes = data.value("dureeMinutes", 60).toInt();
    s.typeSeance = stringToCategorieSeance(data.value("typeSeance").toString());
    auto result = m_service->createSeance(s);
    if (result.isOk()) {
        emit operationSucceeded("Séance créée");
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void AttendanceController::updateSeance(int id, const QVariantMap& data) {
    Seance s;
    s.id = id;
    s.matiereId = data.value("matiereId").toInt();
    s.profId = data.value("profId").toInt();
    s.salleId = data.value("salleId").toInt();
    s.classeId = data.value("classeId").toInt();
    s.dateHeureDebut = QDateTime::fromString(data.value("dateHeureDebut").toString(), Qt::ISODate);
    s.dureeMinutes = data.value("dureeMinutes", 60).toInt();
    s.typeSeance = stringToCategorieSeance(data.value("typeSeance").toString());
    auto result = m_service->updateSeance(s);
    if (result.isOk()) {
        emit operationSucceeded("Séance mise à jour");
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void AttendanceController::deleteSeance(int id) {
    auto result = m_service->deleteSeance(id);
    if (result.isOk()) emit operationSucceeded("Séance supprimée");
    else emit operationFailed(result.errorMessage());
}

void AttendanceController::loadParticipations(int seanceId) {
    setLoading(true);
    auto result = m_service->getParticipationsBySeance(seanceId);
    if (result.isOk()) {
        m_participations.clear();
        for (const auto& p : result.value()) m_participations.append(participationToMap(p));
        emit participationsChanged();
    } else {
        m_errorMessage = result.errorMessage(); emit errorMessageChanged();
    }
    setLoading(false);
}

void AttendanceController::recordParticipation(const QVariantMap& data) {
    Participation p;
    p.seanceId = data.value("seanceId").toInt();
    p.eleveId = data.value("eleveId").toInt();
    p.statut = stringToTypePresence(data.value("statut").toString());
    p.note = data.value("note", -1.0).toDouble();
    p.estInvite = data.value("estInvite", false).toBool();
    auto result = m_service->recordParticipation(p);
    if (result.isOk()) emit operationSucceeded("Présence enregistrée");
    else emit operationFailed(result.errorMessage());
}

void AttendanceController::updateParticipation(int id, const QVariantMap& data) {
    Participation p;
    p.id = id;
    p.seanceId = data.value("seanceId").toInt();
    p.eleveId = data.value("eleveId").toInt();
    p.statut = stringToTypePresence(data.value("statut").toString());
    p.note = data.value("note", -1.0).toDouble();
    p.estInvite = data.value("estInvite", false).toBool();
    auto result = m_service->updateParticipation(p);
    if (result.isOk()) emit operationSucceeded("Présence mise à jour");
    else emit operationFailed(result.errorMessage());
}
