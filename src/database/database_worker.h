#ifndef DATABASE_WORKER_H
#define DATABASE_WORKER_H

#include <QObject>
#include <QThread>
#include <QVariant>
#include <functional>

class DatabaseWorker : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseWorker(const QString& dbPath, QObject* parent = nullptr);
    ~DatabaseWorker() override;

    void start();
    void stop();
    QString connectionName() const;

    /**
     * @brief Submit a query from ANY thread. The lambda runs on the worker thread.
     *
     * Call this from the main/GUI thread. The queryFunc will be marshalled
     * to the worker thread via a queued signal/slot connection.
     * Results come back via queryCompleted / queryError signals.
     */
    void submit(const QString& queryId, std::function<QVariant()> queryFunc);

signals:
    void ready();
    void initError(const QString& message);
    void queryCompleted(const QString& queryId, const QVariant& result);
    void queryError(const QString& queryId, const QString& error);

    // Internal signal for cross-thread dispatch
    void enqueueQuery(const QString& queryId, std::function<QVariant()> queryFunc);

private slots:
    void onThreadStarted();
    void executeAsync(const QString& queryId, std::function<QVariant()> queryFunc);

private:
    QThread m_thread;
    QString m_dbPath;
    QString m_connectionName;
    bool    m_initialized = false;
};

#endif // DATABASE_WORKER_H
