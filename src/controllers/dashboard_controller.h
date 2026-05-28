#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class DashboardService;
class SchoolingService;
class StaffService;
class StudentService;
class DatabaseWorker;
class QTimer;

class DashboardController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int totalStudents READ totalStudents NOTIFY dataChanged)
    Q_PROPERTY(int activeCourses READ activeCourses NOTIFY dataChanged)
    Q_PROPERTY(double averageAttendance READ averageAttendance NOTIFY dataChanged)
    Q_PROPERTY(double schoolAverage READ schoolAverage NOTIFY dataChanged)
    Q_PROPERTY(QVariantList liveSessions READ liveSessions NOTIFY dataChanged)
    Q_PROPERTY(QVariantList recentGrades READ recentGrades NOTIFY dataChanged)
    Q_PROPERTY(QVariantList upcomingExams READ upcomingExams NOTIFY dataChanged)
    Q_PROPERTY(QVariantList levelPerformanceData READ levelPerformanceData NOTIFY dataChanged)
    Q_PROPERTY(QVariantList absencesByMonth READ absencesByMonth NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit DashboardController(DashboardService* service,
                                 SchoolingService* schoolingService,
                                 StaffService* staffService,
                                 StudentService* studentService,
                                 DatabaseWorker* worker,
                                 QObject* parent = nullptr);

    int totalStudents() const { return m_totalStudents; }
    int activeCourses() const { return m_activeCourses; }
    double averageAttendance() const { return m_averageAttendance; }
    double schoolAverage() const { return m_schoolAverage; }
    QVariantList liveSessions() const { return m_liveSessions; }
    QVariantList recentGrades() const { return m_recentGrades; }
    QVariantList upcomingExams() const { return m_upcomingExams; }
    QVariantList levelPerformanceData() const { return m_levelPerformanceData; }
    QVariantList absencesByMonth() const { return m_absencesByMonth; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadDashboard();

signals:
    void dataChanged();
    void loadingChanged();
    void errorMessageChanged();

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);

    DashboardService* m_service = nullptr;
    SchoolingService* m_schoolingService = nullptr;
    StaffService* m_staffService = nullptr;
    StudentService* m_studentService = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QTimer* m_refreshTimer = nullptr;

    int m_totalStudents = 0;
    int m_activeCourses = 0;
    double m_averageAttendance = 0.0;
    double m_schoolAverage = 0.0;
    QVariantList m_liveSessions;
    QVariantList m_recentGrades;
    QVariantList m_upcomingExams;
    QVariantList m_levelPerformanceData;
    QVariantList m_absencesByMonth;
    bool m_loading = false;
    QString m_errorMessage;
};
