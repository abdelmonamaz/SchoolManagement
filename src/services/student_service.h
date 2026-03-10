#pragma once

#include <QList>
#include <QString>
#include <QVariantList>
#include <optional>

#include "common/result.h"
#include "models/eleve.h"
#include "models/inscription.h"

class IEleveRepository;
class IClasseRepository;

class StudentService {
public:
    StudentService(IEleveRepository* eleveRepo, IClasseRepository* classeRepo);

    Result<QList<Eleve>> getAllStudents();
    Result<QList<Eleve>> getStudentsByClasse(int classeId);
    Result<QList<Eleve>> getStudentsBySchoolYear(const QString& anneeScolaire);
    Result<std::optional<Eleve>> getStudentById(int id);
    Result<int> createStudent(const QString& nom, const QString& prenom, const QString& sexe,
                              const QString& telephone, const QString& adresse,
                              const QString& dateNaissance, const QString& nomParent,
                              const QString& telParent, const QString& commentaire,
                              GS::TypePublic categorie,
                              const QString& cinEleve = QString(),
                              const QString& cinParent = QString());
    Result<bool> updateStudent(const Eleve& eleve);
    Result<bool> deleteStudent(int id);
    Result<int> getTotalCount();
    Result<QList<Eleve>> searchByName(const QString& query);

    Result<bool> unassignStudentsFromClasse(int classeId);
    Result<bool> removeStudentFromClasse(int studentId);
    Result<bool> assignToClasse(int studentId, int classeId);
    Result<QList<Eleve>> getUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie);

    // Enrollments
    Result<int> enrollStudent(const Inscription& inscription);
    Result<bool> updateEnrollment(const Inscription& inscription);
    Result<QList<Inscription>> getEnrollmentsForStudent(int studentId);
    Result<QList<Inscription>> getEnrollmentsForYear(const QString& anneeScolaire);
    Result<QList<Inscription>> getEnrollmentsForActiveYear();
    Result<bool> deleteEnrollment(int enrollmentId);
    Result<QVariantList> loadSchoolYears();
    Result<QList<Eleve>> getStudentsByClasseAndYear(int classeId, int anneeId);

private:
    IEleveRepository* m_eleveRepo;
    IClasseRepository* m_classeRepo;
};


