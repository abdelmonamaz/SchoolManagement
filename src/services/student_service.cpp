#include "services/student_service.h"

#include <algorithm>

#include "repositories/ieleve_repository.h"
#include "repositories/iniveau_repository.h"

StudentService::StudentService(IEleveRepository* eleveRepo, IClasseRepository* classeRepo)
    : m_eleveRepo(eleveRepo)
    , m_classeRepo(classeRepo)
{
}

Result<QList<Eleve>> StudentService::getAllStudents()
{
    return m_eleveRepo->getAll();
}

Result<QList<Eleve>> StudentService::getStudentsByClasse(int classeId)
{
    return m_eleveRepo->getByClasseId(classeId);
}

Result<std::optional<Eleve>> StudentService::getStudentById(int id)
{
    return m_eleveRepo->getById(id);
}

Result<int> StudentService::createStudent(const QString& nom, const QString& prenom,
                                           const QString& telephone, const QString& adresse,
                                           const QString& dateNaissance,
                                           GS::TypePublic categorie, int classeId)
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
    e.telephone = telephone.trimmed();
    e.adresse = adresse.trimmed();
    e.dateNaissance = dateNaissance.trimmed();
    e.categorie = categorie;
    e.classeId = classeId;
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
