#pragma once

#include <QDateTime>
#include <QList>

#include "common/result.h"
#include "models/seance.h"

class ISeanceRepository;
class IParticipationRepository;
class IEleveRepository;

class AttendanceService {
public:
    AttendanceService(ISeanceRepository* seanceRepo, IParticipationRepository* participationRepo,
                      IEleveRepository* eleveRepo, const QString& connectionName = {});

    Result<QList<Seance>> getSeancesByDateRange(const QDateTime& from, const QDateTime& to);
    Result<QList<Seance>> getSeancesByClasse(int classeId);
    Result<int> createSeance(const Seance& seance);
    Result<bool> updateSeance(const Seance& seance);
    Result<bool> deleteSeance(int id);

    // Participations
    Result<QList<Participation>> getParticipationsBySeance(int seanceId);
    Result<int> recordParticipation(const Participation& p);
    Result<bool> updateParticipation(const Participation& p);
    Result<bool> deleteParticipation(int id);

    // Attendance validation flag
    Result<bool> setPresenceValide(int seanceId, bool valide);

    // Stats
    Result<double> getAttendanceRate(int classeId, const QDateTime& from, const QDateTime& to);

private:
    ISeanceRepository* m_seanceRepo;
    IParticipationRepository* m_participationRepo;
    IEleveRepository* m_eleveRepo;
    QString m_connectionName;
};
