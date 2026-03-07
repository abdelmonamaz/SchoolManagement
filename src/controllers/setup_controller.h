#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Contrôleur léger gérant le flux "Mise en marche" (premier lancement) +
// l'accès aux paramètres globaux (tarifs, frais, infos association) depuis
// le reste de l'application.
// Crée sa propre connexion SQLite sur le main thread (séparée du worker thread).
class SetupController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isInitialized READ isInitialized NOTIFY isInitializedChanged)
    Q_PROPERTY(QVariantMap associationData READ associationData NOTIFY associationDataChanged)
    Q_PROPERTY(QVariantList niveaux READ niveaux NOTIFY niveauxChanged)
    // Tarifs + frais de l'année scolaire active
    // { tarifJeune, tarifAdulte, fraisInscriptionJeune, fraisInscriptionAdulte }
    Q_PROPERTY(QVariantMap activeTarifs READ activeTarifs NOTIFY activeTarifsChanged)

public:
    // dbPath : chemin vers le fichier .db (même que DatabaseWorker)
    explicit SetupController(const QString& dbPath, QObject* parent = nullptr);

    bool isInitialized() const { return m_initialized; }
    QVariantMap associationData() const { return m_associationData; }
    QVariantList niveaux() const { return m_niveaux; }
    QVariantMap activeTarifs() const { return m_activeTarifs; }

    // ── Initialisation ──
    Q_INVOKABLE void checkInitialized();

    // ── Étape 1 : Identité de l'association ──
    Q_INVOKABLE bool saveAssociation(const QVariantMap& data);

    // ── Étape 2 : Catalogue des niveaux ──
    Q_INVOKABLE void loadNiveaux();
    Q_INVOKABLE int  createNiveau(const QString& nom, int parentLevelId = 0);
    Q_INVOKABLE bool updateNiveau(int id, const QString& nom, int parentLevelId = 0);
    Q_INVOKABLE bool deleteNiveau(int id);

    // ── Étape 3 : Première année scolaire ──
    // Crée l'année, lie tous les niveaux actifs et marque l'appli initialisée.
    // data : { libelle, dateDebut, dateFin, tarifJeune, tarifAdulte,
    //          fraisInscriptionJeune, fraisInscriptionAdulte }
    Q_INVOKABLE bool completeSetup(const QVariantMap& anneeData);

    // ── Paramètres globaux (depuis SettingsPage ou autre) ──
    // Met à jour les tarifs de l'année active + tarifs_mensualites (legacy).
    // data : { tarifJeune, tarifAdulte, fraisInscriptionJeune, fraisInscriptionAdulte }
    Q_INVOKABLE bool updateTarifs(const QVariantMap& data);

    // ── Recalcul des catégories élèves ──
    // Recalcule la catégorie (Jeune/Adulte) de tous les élèves existants selon le nouvel âge de passage.
    // Retourne le nombre d'élèves mis à jour, ou -1 en cas d'erreur.
    Q_INVOKABLE int recalculeCategories(int agePassage);

signals:
    void isInitializedChanged();
    void associationDataChanged();
    void niveauxChanged();
    void activeTarifsChanged();
    void setupCompleted();
    void operationFailed(const QString& error);
    void categoriesRecalculees(int count);

private:
    void loadActiveTarifs();

    QString m_connectionName;
    bool m_initialized = false;
    QVariantMap m_associationData;
    QVariantList m_niveaux;
    QVariantMap m_activeTarifs;
};
