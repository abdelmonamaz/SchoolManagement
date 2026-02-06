#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class StaffService;

class StaffController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList professeurs READ professeurs NOTIFY professeursChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit StaffController(StaffService* service, QObject* parent = nullptr);

    QVariantList professeurs() const { return m_professeurs; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    Q_INVOKABLE void loadProfesseurs();
    Q_INVOKABLE void createProfesseur(const QVariantMap& data);
    Q_INVOKABLE void updateProfesseur(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteProfesseur(int id);
    Q_INVOKABLE void updateTarif(int profId, double nouveauPrix);
    Q_INVOKABLE double getMonthlySalary(int hours, double rate);

signals:
    void professeursChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private:
    void setLoading(bool v);

    StaffService* m_service = nullptr;
    QVariantList m_professeurs;
    bool m_loading = false;
    QString m_errorMessage;
};
