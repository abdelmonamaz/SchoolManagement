#pragma once

#include <QList>
#include <QString>

#include "common/result.h"
#include "models/niveau.h"
#include "models/salle.h"

class INiveauRepository;
class IClasseRepository;
class IMatiereRepository;
class IMatiereExamenRepository;
class ISalleRepository;
class IEquipementRepository;

class SchoolingService {
public:
    SchoolingService(INiveauRepository* niveauRepo, IClasseRepository* classeRepo,
                     IMatiereRepository* matiereRepo, IMatiereExamenRepository* matiereExamenRepo,
                     ISalleRepository* salleRepo, IEquipementRepository* equipementRepo);

    // Niveaux
    Result<QList<Niveau>> getAllNiveaux();
    Result<int> createNiveau(const QString& nom);
    Result<bool> updateNiveau(int id, const QString& nom);
    Result<bool> deleteNiveau(int id);

    // Classes
    Result<QList<Classe>> getAllClasses();
    Result<QList<Classe>> getClassesByNiveau(int niveauId);
    Result<int> createClasse(const QString& nom, int niveauId);
    Result<bool> updateClasse(int id, const QString& nom, int niveauId);
    Result<bool> deleteClasse(int id);

    // Matieres
    Result<QList<Matiere>> getAllMatieres();
    Result<QList<Matiere>> getMatieresByNiveau(int niveauId);
    Result<int>  createMatiere(const QString& nom, int niveauId);
    Result<bool> updateMatiere(int id, const QString& nom, int niveauId, int nombreSeances, int dureeSeanceMinutes);
    Result<bool> deleteMatiere(int id);

    // MatiereExamens
    Result<QList<MatiereExamen>> getExamensByMatiere(int matiereId);
    Result<int>  createMatiereExamen(int matiereId, const QString& titre);
    Result<bool> updateMatiereExamen(int id, const QString& titre);
    Result<bool> deleteMatiereExamen(int id);

    // Salles
    Result<QList<Salle>> getAllSalles();
    Result<int> createSalle(const QString& nom, int capacite, const QString& equipement);
    Result<bool> updateSalle(int id, const QString& nom, int capacite, const QString& equipement);
    Result<bool> deleteSalle(int id);

    // Equipements
    Result<QList<Equipement>> getAllEquipements();
    Result<int> createEquipement(const QString& nom);
    Result<bool> deleteEquipement(int id);

private:
    INiveauRepository* m_niveauRepo;
    IClasseRepository* m_classeRepo;
    IMatiereRepository* m_matiereRepo;
    IMatiereExamenRepository* m_matiereExamenRepo;
    ISalleRepository* m_salleRepo;
    IEquipementRepository* m_equipementRepo;
};
