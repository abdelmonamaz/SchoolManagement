#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class StudentService;
class DatabaseWorker;

class StudentController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList students READ students NOTIFY studentsChanged)
    Q_PROPERTY(QVariantMap selectedStudent READ selectedStudent NOTIFY selectedStudentChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit StudentController(StudentService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList students() const { return m_students; }
    QVariantMap selectedStudent() const { return m_selectedStudent; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadStudents();
    Q_INVOKABLE void loadStudentsByClasse(int classeId);
    Q_INVOKABLE void searchStudents(const QString& query);
    Q_INVOKABLE void createStudent(const QVariantMap& data);
    Q_INVOKABLE void updateStudent(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteStudent(int id);
    Q_INVOKABLE void selectStudent(int index);
    Q_INVOKABLE void unassignStudentsFromClasse(int classeId);
    Q_INVOKABLE void removeStudentFromClasse(int studentId);

signals:
    void studentsChanged();
    void selectedStudentChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);
    void setError(const QString& e);

    StudentService* m_service = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_students;
    QVariantMap m_selectedStudent;
    bool m_loading = false;
    QString m_errorMessage;
};
