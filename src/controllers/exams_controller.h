#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class AttendanceService;
class DatabaseWorker;

class ExamsController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList exams READ exams NOTIFY examsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit ExamsController(AttendanceService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList exams() const { return m_exams; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadExamsByMonth(int month, int year);
    Q_INVOKABLE void createExam(const QVariantMap& data);
    Q_INVOKABLE void updateExam(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteExam(int id);

signals:
    void examsChanged();
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
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_exams;
    bool m_loading = false;
    QString m_errorMessage;
};
