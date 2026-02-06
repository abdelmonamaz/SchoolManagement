#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class AttendanceService;

class AttendanceController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList seances READ seances NOTIFY seancesChanged)
    Q_PROPERTY(QVariantList participations READ participations NOTIFY participationsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit AttendanceController(AttendanceService* service, QObject* parent = nullptr);

    QVariantList seances() const { return m_seances; }
    QVariantList participations() const { return m_participations; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadSeancesByDateRange(const QString& from, const QString& to);
    Q_INVOKABLE void loadSeancesByClasse(int classeId);
    Q_INVOKABLE void createSeance(const QVariantMap& data);
    Q_INVOKABLE void updateSeance(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteSeance(int id);

    Q_INVOKABLE void loadParticipations(int seanceId);
    Q_INVOKABLE void recordParticipation(const QVariantMap& data);
    Q_INVOKABLE void updateParticipation(int id, const QVariantMap& data);

signals:
    void seancesChanged();
    void participationsChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private:
    void setLoading(bool v);

    AttendanceService* m_service = nullptr;
    QVariantList m_seances;
    QVariantList m_participations;
    bool m_loading = false;
    QString m_errorMessage;
};
