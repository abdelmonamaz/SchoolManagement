#ifndef DATABASE_WORKER_H
#define DATABASE_WORKER_H

#include <QObject>
#include <QThread>
#include <QVariant>
#include <functional>

/**
 * @brief Threaded worker that owns a dedicated SQLite connection.
 *
 * DatabaseWorker lives on its own QThread so that all database I/O stays
 * off the GUI thread.  Call start() once; when the schema is ready the
 * ready() signal is emitted.  After that, submit work via executeAsync().
 */
class DatabaseWorker : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseWorker(const QString& dbPath, QObject* parent = nullptr);
    ~DatabaseWorker() override;

    /** Moves this object to its internal thread and starts it. */
    void start();

    /** Gracefully stops the internal thread and removes the DB connection. */
    void stop();

    /** Returns the unique connection name used by this worker. */
    QString connectionName() const;

public slots:
    /**
     * @brief Runs @p queryFunc on the worker thread.
     * @param queryId   Caller-defined identifier echoed back in the result signal.
     * @param queryFunc Lambda that performs the actual query and returns a QVariant.
     *
     * On success emits queryCompleted(); on exception emits queryError().
     */
    void executeAsync(const QString& queryId, std::function<QVariant()> queryFunc);

signals:
    /** Emitted once the connection is open and the schema is in place. */
    void ready();

    /** Emitted when executeAsync() finishes successfully. */
    void queryCompleted(const QString& queryId, const QVariant& result);

    /** Emitted when executeAsync() catches an error. */
    void queryError(const QString& queryId, const QString& error);

private slots:
    /** Called automatically when the internal thread starts. */
    void onThreadStarted();

private:
    QThread m_thread;
    QString m_dbPath;
    QString m_connectionName;
    bool    m_initialized = false;
};

#endif // DATABASE_WORKER_H
