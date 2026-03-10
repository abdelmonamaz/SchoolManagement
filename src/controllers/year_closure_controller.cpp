#include "controllers/year_closure_controller.h"
#include "database/database_worker.h"
#include "repositories/iyear_closure_repository.h"

#include <QDebug>

YearClosureController::YearClosureController(IYearClosureRepository* repo,
                                             DatabaseWorker* worker,
                                             QObject* parent)
    : QObject(parent)
    , m_repo(repo)
    , m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &YearClosureController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError,     this, &YearClosureController::onQueryError);
}

void YearClosureController::setIsLoading(bool v) {
    if (m_isLoading == v) return;
    m_isLoading = v;
    emit isLoadingChanged();
}

// ── loadStats ─────────────────────────────────────────────────────────────────

void YearClosureController::loadStats()
{
    setIsLoading(true);
    m_worker->submit("YearClosure.loadStats",
        [repo = m_repo]() -> QVariant
    {
        return repo->loadStats();
    });
}

// ── loadStudentProgressions ───────────────────────────────────────────────────

void YearClosureController::loadStudentProgressions()
{
    setIsLoading(true);
    m_worker->submit("YearClosure.loadStudentProgressions",
        [repo = m_repo]() -> QVariant
    {
        return repo->loadStudentProgressions();
    });
}

// ── loadArchivageStats ────────────────────────────────────────────────────────

void YearClosureController::loadArchivageStats()
{
    m_worker->submit("YearClosure.loadArchivageStats",
        [repo = m_repo]() -> QVariant
    {
        return repo->loadArchivageStats();
    });
}

// ── executeYearClosure ────────────────────────────────────────────────────────

void YearClosureController::executeYearClosure(const QString& newLabel,
                                               const QString& dateDebut,
                                               const QString& dateFin,
                                               const QVariantList& progressions)
{
    // Pre-validate on main thread: no 'En cours' remaining
    for (const QVariant& v : progressions) {
        const QVariantMap m = v.toMap();
        if (m.value("resultat").toString() == QLatin1String("En cours")) {
            emit closureError(tr("Tous les élèves doivent avoir un résultat avant de clôturer."));
            return;
        }
    }

    m_worker->submit("YearClosure.executeYearClosure",
        [repo = m_repo, newLabel, dateDebut, dateFin, progressions]() -> QVariant
    {
        auto res = repo->executeYearClosure(newLabel, dateDebut, dateFin, progressions);
        if (!res.isOk())
            return QVariantMap{{"error", res.errorMessage()}};
        return QVariantMap{{"success", true}, {"newLabel", newLabel}};
    });
}

// ── Query result handlers ─────────────────────────────────────────────────────

void YearClosureController::onQueryCompleted(const QString& queryId, const QVariant& result)
{
    if (queryId == QLatin1String("YearClosure.loadStats")) {
        setIsLoading(false);
        const auto map = result.toMap();
        if (map.value("empty").toBool()) {
            m_closureStats = {};
            emit closureStatsChanged();
            m_incompleteSessions = {};
            emit incompleteSessionsChanged();
            return;
        }
        m_closureStats = map.value("stats").toMap();
        emit closureStatsChanged();
        m_incompleteSessions = map.value("sessions").toList();
        emit incompleteSessionsChanged();
        return;
    }

    if (queryId == QLatin1String("YearClosure.loadStudentProgressions")) {
        setIsLoading(false);
        m_studentProgressions = result.toList();
        emit studentProgressionsChanged();
        return;
    }

    if (queryId == QLatin1String("YearClosure.loadArchivageStats")) {
        m_archivageStats = result.toMap();
        emit archivageStatsChanged();
        return;
    }

    if (queryId == QLatin1String("YearClosure.executeYearClosure")) {
        const auto map = result.toMap();
        if (map.contains("error"))
            emit closureError(map.value("error").toString());
        else
            emit closureSuccess(map.value("newLabel").toString());
        return;
    }
}

void YearClosureController::onQueryError(const QString& queryId, const QString& error)
{
    if (!queryId.startsWith(QLatin1String("YearClosure.")))
        return;

    qWarning() << "[YearClosureController] Query error:" << queryId << "-" << error;

    setIsLoading(false);

    if (queryId == QLatin1String("YearClosure.executeYearClosure"))
        emit closureError(error);
}
