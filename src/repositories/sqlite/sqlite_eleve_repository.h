#pragma once

#include "repositories/ieleve_repository.h"
#include <QString>

class SqliteEleveRepository : public IEleveRepository {
public:
    explicit SqliteEleveRepository(const QString& connectionName);

    Result<QList<Eleve>> getAll() override;
    Result<std::optional<Eleve>> getById(int id) override;
    Result<int> create(const Eleve& entity) override;
    Result<bool> update(const Eleve& entity) override;
    Result<bool> remove(int id) override;

    Result<QList<Eleve>> getByClasseId(int classeId) override;
    Result<QList<Eleve>> getBySchoolYear(const QString& anneeScolaire) override;
    Result<int> countAll() override;

    Result<bool> unassignClasse(int classeId) override;
    Result<bool> removeFromClasse(int studentId) override;
    Result<bool> assignToClasse(int studentId, int classeId) override;
    Result<QList<Eleve>> getUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie) override;

    // Enrollments
    Result<int> createEnrollment(const Inscription& inscription) override;
    Result<bool> updateEnrollment(const Inscription& inscription) override;
    Result<QList<Inscription>> getEnrollmentsByStudentId(int studentId) override;
    Result<std::optional<Inscription>> getEnrollmentByYear(int studentId, const QString& anneeScolaire) override;
    Result<QList<Inscription>> getEnrollmentsForYear(const QString& anneeScolaire) override;
    Result<QList<Inscription>> getEnrollmentsForActiveYear() override;
    Result<bool> deleteEnrollment(int enrollmentId) override;

    // Bulletin helpers
    Result<QList<Eleve>> getByClasseAndYear(int classeId, int anneeId) override;

    // School years
    Result<QVariantList> getSchoolYears() override;

private:
    QString m_connectionName;
};

