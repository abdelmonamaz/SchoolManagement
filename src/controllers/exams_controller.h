#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class AttendanceService;
class SchoolingService;
class StaffService;
class DatabaseWorker;

class ExamsController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList exams READ exams NOTIFY examsChanged)
    Q_PROPERTY(QVariantList weekSessions READ weekSessions NOTIFY weekSessionsChanged)
    Q_PROPERTY(QVariantMap  courseCountInfo READ courseCountInfo NOTIFY courseCountInfoChanged)
    Q_PROPERTY(QVariantList scheduledExamTitles READ scheduledExamTitles NOTIFY scheduledExamTitlesChanged)
    Q_PROPERTY(QVariantList examSeances READ examSeances NOTIFY examSeancesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit ExamsController(AttendanceService* service,
                             SchoolingService* schoolingService,
                             StaffService* staffService,
                             DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList exams() const { return m_exams; }
    QVariantList weekSessions() const { return m_weekSessions; }
    QVariantMap  courseCountInfo() const { return m_courseCountInfo; }
    QVariantList scheduledExamTitles() const { return m_scheduledExamTitles; }
    QVariantList examSeances() const { return m_examSeances; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    // Calendar view: all exams/events for a month
    Q_INVOKABLE void loadExamsByMonth(int month, int year);
    // Calendar view: all sessions (cours+exams+events) for a month
    Q_INVOKABLE void loadAllSessionsByMonth(int month, int year);
    // Planning view: all sessions for a given ISO week
    Q_INVOKABLE void loadSessionsByWeek(int week, int year);

    Q_INVOKABLE void createExam(const QVariantMap& data);
    Q_INVOKABLE void createCourseWithRecurrence(const QVariantMap& data, const QString& recurrence);
    Q_INVOKABLE void updateExam(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteExam(int id);

    // Helpers for planning intelligence
    Q_INVOKABLE void loadCourseCountForMatiereClasse(int matiereId, int classeId);
    Q_INVOKABLE void loadScheduledExamTitles(int matiereId, int classeId);

    // Grades page: all exam seances for a given classe+matière (current school year)
    Q_INVOKABLE void loadExamSeancesByClasseMatiere(int classeId, int matiereId);

signals:
    void examsChanged();
    void weekSessionsChanged();
    void courseCountInfoChanged();
    void scheduledExamTitlesChanged();
    void examSeancesChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);

    AttendanceService* m_service = nullptr;
    SchoolingService* m_schoolingService = nullptr;
    StaffService* m_staffService = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_exams;
    QVariantList m_weekSessions;
    QVariantMap  m_courseCountInfo;
    QVariantList m_scheduledExamTitles;
    QVariantList m_examSeances;
    bool m_loading = false;
    QString m_errorMessage;
};
