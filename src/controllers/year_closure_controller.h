#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class DatabaseWorker;
class IYearClosureRepository;

class YearClosureController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantMap  closureStats        READ closureStats        NOTIFY closureStatsChanged)
    Q_PROPERTY(QVariantList studentProgressions READ studentProgressions NOTIFY studentProgressionsChanged)
    Q_PROPERTY(QVariantList incompleteSessions  READ incompleteSessions  NOTIFY incompleteSessionsChanged)
    Q_PROPERTY(QVariantMap  archivageStats      READ archivageStats      NOTIFY archivageStatsChanged)
    Q_PROPERTY(bool         isLoading           READ isLoading           NOTIFY isLoadingChanged)

public:
    explicit YearClosureController(IYearClosureRepository* repo,
                                   DatabaseWorker* worker,
                                   QObject* parent = nullptr);

    QVariantMap  closureStats()        const { return m_closureStats; }
    QVariantList studentProgressions() const { return m_studentProgressions; }
    QVariantList incompleteSessions()  const { return m_incompleteSessions; }
    QVariantMap  archivageStats()      const { return m_archivageStats; }
    bool         isLoading()           const { return m_isLoading; }

    // Load overview stats (step 1)
    Q_INVOKABLE void loadStats();

    // Load per-student progressions with possible next levels (step 2)
    Q_INVOKABLE void loadStudentProgressions();

    // Load archivage statistics for step 3 (sessions done/planned, exams, attendance)
    Q_INVOKABLE void loadArchivageStats();

    // Execute the full year closure.
    // progressions: list of { inscriptionId, eleveId, niveauActuelId, categorie, resultat, niveauSuivantId }
    // niveauSuivantId = 0 means "diplômé" (no new inscription created)
    Q_INVOKABLE void executeYearClosure(const QString& newLabel,
                                        const QString& dateDebut,
                                        const QString& dateFin,
                                        const QVariantList& progressions);

signals:
    void closureStatsChanged();
    void studentProgressionsChanged();
    void incompleteSessionsChanged();
    void archivageStatsChanged();
    void isLoadingChanged();

    void closureSuccess(const QString& newYearLabel);
    void closureError(const QString& message);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setIsLoading(bool v);

    IYearClosureRepository* m_repo    = nullptr;
    DatabaseWorker*         m_worker  = nullptr;
    QVariantMap  m_closureStats;
    QVariantList m_studentProgressions;
    QVariantList m_incompleteSessions;
    QVariantMap  m_archivageStats;
    bool         m_isLoading = false;
};
