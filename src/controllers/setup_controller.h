#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class DatabaseWorker;
class INiveauRepository;
class IAssociationRepository;
class ISetupSchoolYearRepository;

// Contrôleur gérant le flux "Mise en marche" (premier lancement) et
// l'accès aux paramètres globaux (tarifs, frais, infos association).
// Toutes les opérations DB sont déléguées au DatabaseWorker.
class SetupController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY isInitializedChanged)
    Q_PROPERTY(bool isChecking    READ isChecking    NOTIFY isCheckingChanged)
    Q_PROPERTY(QVariantMap associationData READ associationData NOTIFY associationDataChanged)
    Q_PROPERTY(QVariantList niveaux READ niveaux NOTIFY niveauxChanged)
    // Tarifs + frais de l'année scolaire active
    // { id, libelle, tarifJeune, tarifAdulte, fraisInscriptionJeune, fraisInscriptionAdulte, dateDebut, dateFin }
    Q_PROPERTY(QVariantMap activeTarifs READ activeTarifs NOTIFY activeTarifsChanged)

public:
    explicit SetupController(INiveauRepository* niveauRepo,
                             IAssociationRepository* assocRepo,
                             ISetupSchoolYearRepository* schoolYearRepo,
                             DatabaseWorker* worker,
                             QObject* parent = nullptr);

    bool isInitialized() const { return m_initialized; }
    bool isChecking()    const { return m_isChecking; }
    QVariantMap associationData() const { return m_associationData; }
    QVariantList niveaux() const { return m_niveaux; }
    QVariantMap activeTarifs() const { return m_activeTarifs; }

    // ── Initialisation ──
    Q_INVOKABLE void checkInitialized();

    // ── Étape 1 : Identité de l'association ──
    Q_INVOKABLE void saveAssociation(const QVariantMap& data);

    // ── Étape 2 : Catalogue des niveaux ──
    Q_INVOKABLE void loadNiveaux();
    Q_INVOKABLE void createNiveau(const QString& nom, int parentLevelId = 0);
    Q_INVOKABLE void updateNiveau(int id, const QString& nom, int parentLevelId = 0);
    Q_INVOKABLE void deleteNiveau(int id);

    // ── Étape 3 : Première année scolaire ──
    // data : { libelle, dateDebut, dateFin, tarifJeune, tarifAdulte,
    //          fraisInscriptionJeune, fraisInscriptionAdulte }
    Q_INVOKABLE void completeSetup(const QVariantMap& anneeData);

    // ── Paramètres globaux ──
    // data : { tarifJeune, tarifAdulte, fraisInscriptionJeune, fraisInscriptionAdulte }
    Q_INVOKABLE void updateTarifs(const QVariantMap& data);

    // Recalcule la catégorie (Jeune/Adulte) de tous les élèves selon l'âge de passage.
    Q_INVOKABLE void recalculeCategories(int agePassage);

signals:
    void isInitializedChanged();
    void isCheckingChanged();
    void associationDataChanged();
    void niveauxChanged();
    void activeTarifsChanged();
    void niveauCreated(int id);
    void setupCompleted();
    void operationFailed(const QString& error);
    void categoriesRecalculees(int count);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    INiveauRepository*         m_niveauRepo    = nullptr;
    IAssociationRepository*    m_assocRepo     = nullptr;
    ISetupSchoolYearRepository* m_schoolYearRepo = nullptr;
    DatabaseWorker*            m_worker        = nullptr;
    bool m_initialized = false;
    bool m_isChecking  = true;   // true until checkInitialized() returns
    QVariantMap m_associationData;
    QVariantList m_niveaux;
    QVariantMap m_activeTarifs;
};
