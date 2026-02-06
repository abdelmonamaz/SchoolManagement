#pragma once

#include <QList>
#include <QString>
#include <optional>

#include "common/result.h"
#include "models/eleve.h"

class IEleveRepository;
class IClasseRepository;

class StudentService {
public:
    StudentService(IEleveRepository* eleveRepo, IClasseRepository* classeRepo);

    Result<QList<Eleve>> getAllStudents();
    Result<QList<Eleve>> getStudentsByClasse(int classeId);
    Result<std::optional<Eleve>> getStudentById(int id);
    Result<int> createStudent(const QString& nom, const QString& prenom, const QString& telephone,
                              const QString& adresse, GS::TypePublic categorie, int classeId);
    Result<bool> updateStudent(const Eleve& eleve);
    Result<bool> deleteStudent(int id);
    Result<int> getTotalCount();
    Result<QList<Eleve>> searchByName(const QString& query);

private:
    IEleveRepository* m_eleveRepo;
    IClasseRepository* m_classeRepo;
};
