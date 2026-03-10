#include "services/student_service.h"

#include <algorithm>

#include "repositories/ieleve_repository.h"
#include "repositories/iniveau_repository.h"
#include "models/inscription.h"

StudentService::StudentService(IEleveRepository* eleveRepo, IClasseRepository* classeRepo)
    : m_eleveRepo(eleveRepo)
    , m_classeRepo(classeRepo)
{
}

Result<int> StudentService::enrollStudent(const Inscription& inscription) {
    auto existing = m_eleveRepo->getEnrollmentByYear(inscription.eleveId, inscription.anneeScolaire);
    if (!existing.isOk()) return Result<int>::error(existing.errorMessage());
    if (existing.value().has_value()) {
        return Result<int>::error("L'élève a déjà une inscription pour l'année scolaire " + inscription.anneeScolaire + ".");
    }
    return m_eleveRepo->createEnrollment(inscription);
}

Result<bool> StudentService::updateEnrollment(const Inscription& inscription) {
    auto existing = m_eleveRepo->getEnrollmentByYear(inscription.eleveId, inscription.anneeScolaire);
    if (!existing.isOk()) return Result<bool>::error(existing.errorMessage());
    if (existing.value().has_value() && existing.value()->id != inscription.id) {
        return Result<bool>::error("L'élève a déjà une inscription pour l'année scolaire " + inscription.anneeScolaire + ".");
    }
    return m_eleveRepo->updateEnrollment(inscription);
}

Result<QList<Inscription>> StudentService::getEnrollmentsForStudent(int studentId) {
    return m_eleveRepo->getEnrollmentsByStudentId(studentId);
}

Result<QList<Inscription>> StudentService::getEnrollmentsForYear(const QString& anneeScolaire) {
    return m_eleveRepo->getEnrollmentsForYear(anneeScolaire);
}

Result<QList<Inscription>> StudentService::getEnrollmentsForActiveYear() {
    return m_eleveRepo->getEnrollmentsForActiveYear();
}

Result<bool> StudentService::deleteEnrollment(int enrollmentId) {
    return m_eleveRepo->deleteEnrollment(enrollmentId);
}

Result<QVariantList> StudentService::loadSchoolYears() {
    return m_eleveRepo->getSchoolYears();
}

Result<QList<Eleve>> StudentService::getStudentsByClasseAndYear(int classeId, int anneeId) {
    return m_eleveRepo->getByClasseAndYear(classeId, anneeId);
}

Result<QList<Eleve>> StudentService::getAllStudents()
{
    return m_eleveRepo->getAll();
}

Result<QList<Eleve>> StudentService::getStudentsByClasse(int classeId)
{
    return m_eleveRepo->getByClasseId(classeId);
}

Result<QList<Eleve>> StudentService::getStudentsBySchoolYear(const QString& anneeScolaire)
{
    return m_eleveRepo->getBySchoolYear(anneeScolaire);
}

Result<std::optional<Eleve>> StudentService::getStudentById(int id)
{
    return m_eleveRepo->getById(id);
}

Result<int> StudentService::createStudent(const QString& nom, const QString& prenom, const QString& sexe,
                                           const QString& telephone, const QString& adresse,
                                           const QString& dateNaissance, const QString& nomParent,
                                           const QString& telParent, const QString& commentaire,
                                           GS::TypePublic categorie,
                                           const QString& cinEleve, const QString& cinParent)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom de l'eleve ne peut pas etre vide.");
    }
    if (prenom.trimmed().isEmpty()) {
        return Result<int>::error("Le prenom de l'eleve ne peut pas etre vide.");
    }

    Eleve e;
    e.nom = nom.trimmed();
    e.prenom = prenom.trimmed();
    e.sexe = sexe;
    e.telephone = telephone.trimmed();
    e.adresse = adresse.trimmed();
    e.dateNaissance = dateNaissance.trimmed();
    e.nomParent = nomParent.trimmed();
    e.telParent = telParent.trimmed();
    e.commentaire = commentaire.trimmed();
    e.categorie = categorie;
    e.cinEleve = cinEleve.trimmed();
    e.cinParent = cinParent.trimmed();
    return m_eleveRepo->create(e);
}

Result<bool> StudentService::updateStudent(const Eleve& eleve)
{
    if (eleve.nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom de l'eleve ne peut pas etre vide.");
    }
    if (eleve.prenom.trimmed().isEmpty()) {
        return Result<bool>::error("Le prenom de l'eleve ne peut pas etre vide.");
    }

    return m_eleveRepo->update(eleve);
}

Result<bool> StudentService::deleteStudent(int id)
{
    return m_eleveRepo->remove(id);
}

Result<int> StudentService::getTotalCount()
{
    return m_eleveRepo->countAll();
}

Result<bool> StudentService::unassignStudentsFromClasse(int classeId)
{
    return m_eleveRepo->unassignClasse(classeId);
}

Result<bool> StudentService::removeStudentFromClasse(int studentId)
{
    return m_eleveRepo->removeFromClasse(studentId);
}

Result<bool> StudentService::assignToClasse(int studentId, int classeId)
{
    return m_eleveRepo->assignToClasse(studentId, classeId);
}

Result<QList<Eleve>> StudentService::getUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie)
{
    return m_eleveRepo->getUnassignedStudents(niveauId, sexe, categorie);
}

Result<QList<Eleve>> StudentService::searchByName(const QString& query)
{
    auto result = m_eleveRepo->getAll();
    if (!result.isOk()) {
        return Result<QList<Eleve>>::error(result.errorMessage());
    }

    const QString lowerQuery = query.trimmed().toLower();
    if (lowerQuery.isEmpty()) {
        return result;
    }

    QList<Eleve> filtered;
    const auto& all = result.value();
    std::copy_if(all.begin(), all.end(), std::back_inserter(filtered),
                 [&lowerQuery](const Eleve& e) {
                     return e.nom.toLower().contains(lowerQuery)
                         || e.prenom.toLower().contains(lowerQuery);
                 });

    return Result<QList<Eleve>>::success(std::move(filtered));
}

