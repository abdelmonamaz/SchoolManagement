#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class GradesService;
class DatabaseWorker;

class GradesController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList grades READ grades NOTIFY gradesChanged)
    Q_PROPERTY(double classAverage READ classAverage NOTIFY classAverageChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit GradesController(GradesService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList grades() const { return m_grades; }
    double classAverage() const { return m_classAverage; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadGradesBySeance(int seanceId);
    Q_INVOKABLE void loadGradesByStudent(int eleveId);
    Q_INVOKABLE void saveGrade(int participationId, double note);
    Q_INVOKABLE void saveGrades(const QVariantList& grades);
    Q_INVOKABLE void loadClassAverage(int seanceId);

signals:
    void gradesChanged();
    void classAverageChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);

    GradesService* m_service = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_grades;
    double m_classAverage = 0.0;
    bool m_loading = false;
    QString m_errorMessage;
};
