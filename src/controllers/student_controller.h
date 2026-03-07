#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class StudentService;
class DatabaseWorker;

class StudentController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList students READ students NOTIFY studentsChanged)
    Q_PROPERTY(QVariantList unassignedStudents READ unassignedStudents NOTIFY unassignedStudentsChanged)
    Q_PROPERTY(QVariantMap selectedStudent READ selectedStudent NOTIFY selectedStudentChanged)
    Q_PROPERTY(QVariantList selectedStudentEnrollments READ selectedStudentEnrollments NOTIFY selectedStudentEnrollmentsChanged)
    Q_PROPERTY(QVariantList enrollmentsByYear READ enrollmentsByYear NOTIFY enrollmentsByYearChanged)
    Q_PROPERTY(QVariantList schoolYears READ schoolYears NOTIFY schoolYearsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit StudentController(StudentService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList students() const { return m_students; }
    QVariantList unassignedStudents() const { return m_unassignedStudents; }
    QVariantMap selectedStudent() const { return m_selectedStudent; }
    QVariantList selectedStudentEnrollments() const { return m_selectedStudentEnrollments; }
    QVariantList enrollmentsByYear() const { return m_enrollmentsByYear; }
    QVariantList schoolYears() const { return m_schoolYears; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadStudents();
    Q_INVOKABLE void loadStudentsByClasse(int classeId);
    Q_INVOKABLE void loadStudentsBySchoolYear(int month, int year);
    Q_INVOKABLE void loadUnassignedStudents(int niveauId, const QString& sexe, const QString& categorie);
    Q_INVOKABLE void searchStudents(const QString& query);
    Q_INVOKABLE void createStudent(const QVariantMap& data);
    Q_INVOKABLE void updateStudent(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteStudent(int id);
    Q_INVOKABLE void selectStudent(int index);
    Q_INVOKABLE void unassignStudentsFromClasse(int classeId);
    Q_INVOKABLE void removeStudentFromClasse(int studentId);
    Q_INVOKABLE void assignStudentToClasse(int studentId, int classeId);
    Q_INVOKABLE void assignMultipleStudentsToClasse(const QVariantList& studentIds, int classeId);

    // Enrollments
    Q_INVOKABLE void loadEnrollments(int studentId);
    Q_INVOKABLE void loadEnrollmentsByYear(const QString& anneeScolaire);
    Q_INVOKABLE void loadSchoolYears();
    Q_INVOKABLE void enrollStudent(const QVariantMap& data);
    Q_INVOKABLE void updateEnrollment(int enrollmentId, const QVariantMap& data);
    Q_INVOKABLE void deleteEnrollment(int enrollmentId);

signals:
    void studentsChanged();
    void unassignedStudentsChanged();
    void selectedStudentChanged();
    void selectedStudentEnrollmentsChanged();
    void enrollmentsByYearChanged();
    void schoolYearsChanged();
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
    QVariantList m_unassignedStudents;
    QVariantMap m_selectedStudent;
    QVariantList m_selectedStudentEnrollments;
    QVariantList m_enrollmentsByYear;
    QVariantList m_schoolYears;
    bool m_loading = false;
    QString m_errorMessage;
};
