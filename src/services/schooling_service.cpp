#include "services/schooling_service.h"

#include "repositories/iniveau_repository.h"
#include "repositories/isalle_repository.h"

SchoolingService::SchoolingService(INiveauRepository* niveauRepo, IClasseRepository* classeRepo,
                                   IMatiereRepository* matiereRepo, ISalleRepository* salleRepo,
                                   IEquipementRepository* equipementRepo)
    : m_niveauRepo(niveauRepo)
    , m_classeRepo(classeRepo)
    , m_matiereRepo(matiereRepo)
    , m_salleRepo(salleRepo)
    , m_equipementRepo(equipementRepo)
{
}

// --- Niveaux ---

Result<QList<Niveau>> SchoolingService::getAllNiveaux()
{
    return m_niveauRepo->getAll();
}

Result<int> SchoolingService::createNiveau(const QString& nom)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom du niveau ne peut pas etre vide.");
    }

    Niveau n;
    n.nom = nom.trimmed();
    return m_niveauRepo->create(n);
}

Result<bool> SchoolingService::updateNiveau(int id, const QString& nom)
{
    if (nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom du niveau ne peut pas etre vide.");
    }

    Niveau n;
    n.id = id;
    n.nom = nom.trimmed();
    return m_niveauRepo->update(n);
}

Result<bool> SchoolingService::deleteNiveau(int id)
{
    return m_niveauRepo->remove(id);
}

// --- Classes ---

Result<QList<Classe>> SchoolingService::getAllClasses()
{
    return m_classeRepo->getAll();
}

Result<QList<Classe>> SchoolingService::getClassesByNiveau(int niveauId)
{
    return m_classeRepo->getByNiveauId(niveauId);
}

Result<int> SchoolingService::createClasse(const QString& nom, int niveauId)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom de la classe ne peut pas etre vide.");
    }

    Classe c;
    c.nom = nom.trimmed();
    c.niveauId = niveauId;
    return m_classeRepo->create(c);
}

Result<bool> SchoolingService::updateClasse(int id, const QString& nom, int niveauId)
{
    if (nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom de la classe ne peut pas etre vide.");
    }

    Classe c;
    c.id = id;
    c.nom = nom.trimmed();
    c.niveauId = niveauId;
    return m_classeRepo->update(c);
}

Result<bool> SchoolingService::deleteClasse(int id)
{
    return m_classeRepo->remove(id);
}

// --- Matieres ---

Result<QList<Matiere>> SchoolingService::getAllMatieres()
{
    return m_matiereRepo->getAll();
}

Result<QList<Matiere>> SchoolingService::getMatieresByNiveau(int niveauId)
{
    return m_matiereRepo->getByNiveauId(niveauId);
}

Result<int> SchoolingService::createMatiere(const QString& nom, int niveauId)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom de la matiere ne peut pas etre vide.");
    }

    Matiere m;
    m.nom = nom.trimmed();
    m.niveauId = niveauId;
    return m_matiereRepo->create(m);
}

Result<bool> SchoolingService::deleteMatiere(int id)
{
    return m_matiereRepo->remove(id);
}

// --- Salles ---

Result<QList<Salle>> SchoolingService::getAllSalles()
{
    return m_salleRepo->getAll();
}

Result<int> SchoolingService::createSalle(const QString& nom, int capacite, const QString& equipement)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom de la salle ne peut pas etre vide.");
    }
    if (capacite <= 0) {
        return Result<int>::error("La capacite doit etre superieure a zero.");
    }

    Salle s;
    s.nom = nom.trimmed();
    s.capaciteChaises = capacite;
    s.equipement = equipement.trimmed();
    return m_salleRepo->create(s);
}

Result<bool> SchoolingService::updateSalle(int id, const QString& nom, int capacite, const QString& equipement)
{
    if (nom.trimmed().isEmpty()) {
        return Result<bool>::error("Le nom de la salle ne peut pas etre vide.");
    }
    if (capacite <= 0) {
        return Result<bool>::error("La capacite doit etre superieure a zero.");
    }

    Salle s;
    s.id = id;
    s.nom = nom.trimmed();
    s.capaciteChaises = capacite;
    s.equipement = equipement.trimmed();
    return m_salleRepo->update(s);
}

Result<bool> SchoolingService::deleteSalle(int id)
{
    return m_salleRepo->remove(id);
}

// --- Equipements ---

Result<QList<Equipement>> SchoolingService::getAllEquipements()
{
    return m_equipementRepo->getAll();
}

Result<int> SchoolingService::createEquipement(const QString& nom)
{
    if (nom.trimmed().isEmpty()) {
        return Result<int>::error("Le nom de l'equipement ne peut pas etre vide.");
    }

    Equipement e;
    e.nom = nom.trimmed();
    return m_equipementRepo->create(e);
}

Result<bool> SchoolingService::deleteEquipement(int id)
{
    return m_equipementRepo->remove(id);
}
