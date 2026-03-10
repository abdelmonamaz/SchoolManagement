#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

class BackupController : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString autoBackupPath     READ autoBackupPath     WRITE setAutoBackupPath     NOTIFY autoBackupPathChanged)
    Q_PROPERTY(bool    autoBackupEnabled  READ autoBackupEnabled  WRITE setAutoBackupEnabled  NOTIFY autoBackupEnabledChanged)
    Q_PROPERTY(int     autoBackupInterval READ autoBackupInterval WRITE setAutoBackupInterval NOTIFY autoBackupIntervalChanged)
    Q_PROPERTY(QString lastAutoBackupDate READ lastAutoBackupDate                             NOTIFY lastAutoBackupDateChanged)

public:
    explicit BackupController(const QString& dbPath, QObject* parent = nullptr);

    QString autoBackupPath() const;
    void    setAutoBackupPath(const QString& path);

    bool autoBackupEnabled() const;
    void setAutoBackupEnabled(bool enabled);

    // Interval in days: 1 = daily, 7 = weekly, 30 = monthly
    int  autoBackupInterval() const;
    void setAutoBackupInterval(int days);

    QString lastAutoBackupDate() const;

    // Immediate backup: copies the DB to a user-chosen path (URL or local path accepted).
    // Result is reported asynchronously via backupSuccess / backupError signals.
    Q_INVOKABLE void copyDatabaseTo(const QString& destPath);

    // Restore: stages the selected DB file and marks it as pending (applied on next startup).
    // Result is reported asynchronously via restoreReady / restoreError signals.
    Q_INVOKABLE void loadDatabase(const QString& srcPath);

signals:
    void autoBackupPathChanged();
    void autoBackupEnabledChanged();
    void autoBackupIntervalChanged();
    void lastAutoBackupDateChanged();

    void backupSuccess(const QString& path);
    void backupError(const QString& message);

    // Emitted after the restore file is staged — the app must restart to apply it
    void restoreReady();
    void restoreError(const QString& message);

private slots:
    void onTimerTick();

private:
    void doAutoBackup();  // runs file I/O in a background thread
    void rescheduleTimer();

    QString m_dbPath;
    QString m_autoBackupPath;
    bool    m_autoBackupEnabled  = false;
    int     m_autoBackupInterval = 1;   // days
    QString m_lastAutoBackupDate;       // ISO date YYYY-MM-DD

    QTimer  m_timer;
};

// Apply any pending DB restore staged by a previous BackupController::loadDatabase() call.
// Must be called BEFORE any QSqlDatabase connection is opened.
void BackupController_applyPendingRestore(const QString& dbPath);
