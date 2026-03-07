#pragma once

#include <QList>
#include <QVariantList>

#include "repositories/irepository.h"
#include "models/eleve.h"
#include "models/inscription.h"

class IEleveRepository : public IRepository<Eleve> {
public:
    ~IEleveRepository() override = default;

    virtual Result<QList<Eleve>> getByClasseId(int classeId) = 0;
    virtual Result<QList<Eleve>> getBySchoolYear(const QString& anneeScolaire) = 0;
    virtual Result<int> countAll() = 0;
    virtual Result<bool> unassignClasse(int classeId) = 0;
    virtual Result<bool> removeFromClasse(int studentId) = 0;
    virtual Result<bool> assignToClasse(int studentId, int classeId) = 0;
    virtual Result<QList<Eleve>> getUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie) = 0;

    // Enrollments
    virtual Result<int> createEnrollment(const Inscription& inscription) = 0;
    virtual Result<bool> updateEnrollment(const Inscription& inscription) = 0;
    virtual Result<QList<Inscription>> getEnrollmentsByStudentId(int studentId) = 0;
    virtual Result<std::optional<Inscription>> getEnrollmentByYear(int studentId, const QString& anneeScolaire) = 0;
    virtual Result<QList<Inscription>> getEnrollmentsForYear(const QString& anneeScolaire) = 0;
    virtual Result<QList<Inscription>> getEnrollmentsForActiveYear() = 0;
    virtual Result<bool> deleteEnrollment(int enrollmentId) = 0;

    // School years
    virtual Result<QVariantList> getSchoolYears() = 0;
};
