#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class SchoolingService;
class DatabaseWorker;

class SchoolingController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList niveaux READ niveaux NOTIFY niveauxChanged)
    Q_PROPERTY(QVariantList classes READ classes NOTIFY classesChanged)
    Q_PROPERTY(QVariantList allClasses READ allClasses NOTIFY allClassesChanged)
    Q_PROPERTY(QVariantList matieres READ matieres NOTIFY matieresChanged)
    Q_PROPERTY(QVariantList allMatieres READ allMatieres NOTIFY allMatieresChanged)
    Q_PROPERTY(QVariantList salles READ salles NOTIFY sallesChanged)
    Q_PROPERTY(QVariantList equipements READ equipements NOTIFY equipementsChanged)
    Q_PROPERTY(QVariantList matiereExamens READ matiereExamens NOTIFY matiereExamensChanged)
    Q_PROPERTY(QVariantList typeExamens READ typeExamens NOTIFY typeExamensChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit SchoolingController(SchoolingService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList niveaux() const { return m_niveaux; }
    QVariantList classes() const { return m_classes; }
    QVariantList allClasses() const { return m_allClasses; }
    QVariantList matieres() const { return m_matieres; }
    QVariantList allMatieres() const { return m_allMatieres; }
    QVariantList salles() const { return m_salles; }
    QVariantList equipements() const { return m_equipements; }
    QVariantList matiereExamens() const { return m_matiereExamens; }
    QVariantList typeExamens() const { return m_typeExamens; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadNiveaux();
    Q_INVOKABLE void loadAllClasses();
    Q_INVOKABLE void loadClassesByNiveau(int niveauId);
    Q_INVOKABLE void loadAllMatieres();
    Q_INVOKABLE void loadMatieresByNiveau(int niveauId);
    Q_INVOKABLE void loadSalles();
    Q_INVOKABLE void loadEquipements();

    Q_INVOKABLE void createNiveau(const QString& nom);
    Q_INVOKABLE void updateNiveau(int id, const QString& nom);
    Q_INVOKABLE void deleteNiveau(int id);

    Q_INVOKABLE void createClasse(const QString& nom, int niveauId);
    Q_INVOKABLE void updateClasse(int id, const QString& nom, int niveauId);
    Q_INVOKABLE void deleteClasse(int id);

    Q_INVOKABLE void createMatiere(const QString& nom, int niveauId);
    Q_INVOKABLE void updateMatiere(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteMatiere(int id);

    Q_INVOKABLE void loadMatiereExamens(int matiereId);
    Q_INVOKABLE void createMatiereExamen(int matiereId, int typeExamenId);
    Q_INVOKABLE void createTypeAndMatiereExamen(int matiereId, const QString& titre);
    Q_INVOKABLE void updateMatiereExamen(int id, const QString& titre);
    Q_INVOKABLE void deleteMatiereExamen(int id);

    Q_INVOKABLE void loadTypeExamens();
    Q_INVOKABLE void createTypeExamen(const QString& titre);
    Q_INVOKABLE void updateTypeExamen(int id, const QString& titre);
    Q_INVOKABLE void deleteTypeExamen(int id);

    Q_INVOKABLE void createSalle(const QVariantMap& data);
    Q_INVOKABLE void updateSalle(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteSalle(int id);

    Q_INVOKABLE void createEquipement(const QString& nom);
    Q_INVOKABLE void deleteEquipement(int id);

signals:
    void niveauxChanged();
    void classesChanged();
    void allClassesChanged();
    void matieresChanged();
    void allMatieresChanged();
    void sallesChanged();
    void equipementsChanged();
    void matiereExamensChanged();
    void typeExamensChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);
    void classeCreated(int classeId);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);
    void setError(const QString& e);

    SchoolingService* m_service = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_niveaux;
    QVariantList m_classes;
    QVariantList m_allClasses;
    QVariantList m_matieres;
    QVariantList m_allMatieres;
    QVariantList m_salles;
    QVariantList m_equipements;
    QVariantList m_matiereExamens;
    QVariantList m_typeExamens;
    bool m_loading = false;
    QString m_errorMessage;
};
