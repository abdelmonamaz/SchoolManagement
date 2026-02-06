#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FinanceService;

class FinanceController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList payments READ payments NOTIFY paymentsChanged)
    Q_PROPERTY(QVariantList projets READ projets NOTIFY projetsChanged)
    Q_PROPERTY(QVariantList donateurs READ donateurs NOTIFY donateursChanged)
    Q_PROPERTY(QVariantList dons READ dons NOTIFY donsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit FinanceController(FinanceService* service, QObject* parent = nullptr);

    QVariantList payments() const { return m_payments; }
    QVariantList projets() const { return m_projets; }
    QVariantList donateurs() const { return m_donateurs; }
    QVariantList dons() const { return m_dons; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    // Paiements
    Q_INVOKABLE void loadPaymentsByMonth(int month, int year);
    Q_INVOKABLE void loadPaymentsByStudent(int eleveId);
    Q_INVOKABLE void recordPayment(const QVariantMap& data);
    Q_INVOKABLE void deletePayment(int id);

    // Projets
    Q_INVOKABLE void loadProjets();
    Q_INVOKABLE void createProjet(const QVariantMap& data);
    Q_INVOKABLE void updateProjet(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteProjet(int id);

    // Donateurs & Dons
    Q_INVOKABLE void loadDonateurs();
    Q_INVOKABLE void createDonateur(const QVariantMap& data);
    Q_INVOKABLE void loadDonsByProjet(int projetId);
    Q_INVOKABLE void recordDon(const QVariantMap& data);

signals:
    void paymentsChanged();
    void projetsChanged();
    void donateursChanged();
    void donsChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private:
    void setLoading(bool v);

    FinanceService* m_service = nullptr;
    QVariantList m_payments;
    QVariantList m_projets;
    QVariantList m_donateurs;
    QVariantList m_dons;
    bool m_loading = false;
    QString m_errorMessage;
};
