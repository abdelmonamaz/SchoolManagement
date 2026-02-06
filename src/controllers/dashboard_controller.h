#pragma once

#include <QObject>
#include <QVariantList>

class DashboardService;

class DashboardController : public QObject {
    Q_OBJECT
    Q_PROPERTY(int totalStudents READ totalStudents NOTIFY dataChanged)
    Q_PROPERTY(int activeCourses READ activeCourses NOTIFY dataChanged)
    Q_PROPERTY(double averageAttendance READ averageAttendance NOTIFY dataChanged)
    Q_PROPERTY(double schoolAverage READ schoolAverage NOTIFY dataChanged)
    Q_PROPERTY(QVariantList liveSessions READ liveSessions NOTIFY dataChanged)
    Q_PROPERTY(QVariantList recentGrades READ recentGrades NOTIFY dataChanged)
    Q_PROPERTY(QVariantList upcomingExams READ upcomingExams NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit DashboardController(DashboardService* service, QObject* parent = nullptr);

    int totalStudents() const { return m_totalStudents; }
    int activeCourses() const { return m_activeCourses; }
    double averageAttendance() const { return m_averageAttendance; }
    double schoolAverage() const { return m_schoolAverage; }
    QVariantList liveSessions() const { return m_liveSessions; }
    QVariantList recentGrades() const { return m_recentGrades; }
    QVariantList upcomingExams() const { return m_upcomingExams; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadDashboard();

signals:
    void dataChanged();
    void loadingChanged();
    void errorMessageChanged();

private:
    void setLoading(bool v);

    DashboardService* m_service = nullptr;
    int m_totalStudents = 0;
    int m_activeCourses = 0;
    double m_averageAttendance = 0.0;
    double m_schoolAverage = 0.0;
    QVariantList m_liveSessions;
    QVariantList m_recentGrades;
    QVariantList m_upcomingExams;
    bool m_loading = false;
    QString m_errorMessage;
};
