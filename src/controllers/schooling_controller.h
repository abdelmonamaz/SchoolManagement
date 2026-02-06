#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class SchoolingService;

class SchoolingController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList niveaux READ niveaux NOTIFY niveauxChanged)
    Q_PROPERTY(QVariantList classes READ classes NOTIFY classesChanged)
    Q_PROPERTY(QVariantList matieres READ matieres NOTIFY matieresChanged)
    Q_PROPERTY(QVariantList salles READ salles NOTIFY sallesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit SchoolingController(SchoolingService* service, QObject* parent = nullptr);

    QVariantList niveaux() const { return m_niveaux; }
    QVariantList classes() const { return m_classes; }
    QVariantList matieres() const { return m_matieres; }
    QVariantList salles() const { return m_salles; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadNiveaux();
    Q_INVOKABLE void loadClassesByNiveau(int niveauId);
    Q_INVOKABLE void loadMatieresByNiveau(int niveauId);
    Q_INVOKABLE void loadSalles();

    Q_INVOKABLE void createNiveau(const QString& nom);
    Q_INVOKABLE void updateNiveau(int id, const QString& nom);
    Q_INVOKABLE void deleteNiveau(int id);

    Q_INVOKABLE void createClasse(const QString& nom, int niveauId);
    Q_INVOKABLE void updateClasse(int id, const QString& nom, int niveauId);
    Q_INVOKABLE void deleteClasse(int id);

    Q_INVOKABLE void createMatiere(const QString& nom, int niveauId);
    Q_INVOKABLE void deleteMatiere(int id);

    Q_INVOKABLE void createSalle(const QVariantMap& data);
    Q_INVOKABLE void updateSalle(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteSalle(int id);

signals:
    void niveauxChanged();
    void classesChanged();
    void matieresChanged();
    void sallesChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private:
    void setLoading(bool v);
    void setError(const QString& e);

    SchoolingService* m_service = nullptr;
    QVariantList m_niveaux;
    QVariantList m_classes;
    QVariantList m_matieres;
    QVariantList m_salles;
    bool m_loading = false;
    QString m_errorMessage;
};
