#include "database/database_worker.h"
#include "database/database_manager.h"

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>
#include <QDebug>

// ---------------------------------------------------------------------------
// Construction / Destruction
// ---------------------------------------------------------------------------

DatabaseWorker::DatabaseWorker(const QString& dbPath, QObject* parent)
    : QObject(parent)
    , m_dbPath(dbPath)
    , m_connectionName(
          QStringLiteral("gs_worker_")
          + QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    qRegisterMetaType<std::function<QVariant()>>("std::function<QVariant()>");

    connect(this, &DatabaseWorker::enqueueQuery,
            this, &DatabaseWorker::executeAsync, Qt::QueuedConnection);
}

DatabaseWorker::~DatabaseWorker()
{
    stop();
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

void DatabaseWorker::start()
{
    if (m_thread.isRunning())
        return;

    // Move this QObject to the worker thread so that slots run there.
    this->moveToThread(&m_thread);

    connect(&m_thread, &QThread::started,
            this,      &DatabaseWorker::onThreadStarted);

    m_thread.start();
}

void DatabaseWorker::stop()
{
    if (!m_thread.isRunning())
        return;

    m_thread.quit();
    m_thread.wait();

    // Remove the connection outside of any scope that holds a QSqlDatabase.
    if (QSqlDatabase::contains(m_connectionName)) {
        QSqlDatabase::removeDatabase(m_connectionName);
        qInfo() << "[DatabaseWorker] Connection removed –" << m_connectionName;
    }

    m_initialized = false;
}

QString DatabaseWorker::connectionName() const
{
    return m_connectionName;
}

void DatabaseWorker::submit(const QString& queryId,
                            std::function<QVariant()> queryFunc)
{
    emit enqueueQuery(queryId, std::move(queryFunc));
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

void DatabaseWorker::onThreadStarted()
{
    if (m_initialized)
        return;

    const bool ok = DatabaseManager::initialize(m_dbPath, m_connectionName);
    if (!ok) {
        qCritical() << "[DatabaseWorker] Initialization failed for"
                     << m_connectionName;
        emit initError(QStringLiteral("Impossible d'ouvrir la base de données.\nVérifiez que le fichier n'est pas verrouillé par une autre application.\n\nChemin : ") + m_dbPath);
        emit ready(); // unblock any waiting event loop
        return;
    }

    DatabaseManager::createSchema(m_connectionName);

    m_initialized = true;
    qInfo() << "[DatabaseWorker] Ready –" << m_connectionName;
    emit ready();
}

void DatabaseWorker::executeAsync(const QString& queryId,
                                   std::function<QVariant()> queryFunc)
{
    if (!m_initialized) {
        emit queryError(queryId,
                        QStringLiteral("Worker not initialized"));
        return;
    }

    try {
        QVariant result = queryFunc();
        emit queryCompleted(queryId, result);
    } catch (const std::exception& ex) {
        qWarning() << "[DatabaseWorker] Query" << queryId
                    << "failed:" << ex.what();
        emit queryError(queryId, QString::fromUtf8(ex.what()));
    } catch (...) {
        qWarning() << "[DatabaseWorker] Query" << queryId
                    << "failed with unknown exception";
        emit queryError(queryId,
                        QStringLiteral("Unknown error during query execution"));
    }
}
