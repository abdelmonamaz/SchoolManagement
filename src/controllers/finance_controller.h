#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FinanceService;
class DatabaseWorker;

class FinanceController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList payments READ payments NOTIFY paymentsChanged)
    Q_PROPERTY(QVariantList projets READ projets NOTIFY projetsChanged)
    Q_PROPERTY(QVariantList donateurs READ donateurs NOTIFY donateursChanged)
    Q_PROPERTY(QVariantList dons READ dons NOTIFY donsChanged)
    Q_PROPERTY(QVariantList tarifs READ tarifs NOTIFY tarifsChanged)
    Q_PROPERTY(QVariantList depenses READ depenses NOTIFY depensesChanged)
    Q_PROPERTY(QVariantList personnelPaymentsForJournal READ personnelPaymentsForJournal NOTIFY personnelPaymentsForJournalChanged)
    Q_PROPERTY(QVariantMap annualBalance READ annualBalance NOTIFY annualBalanceChanged)
    Q_PROPERTY(QVariantMap totalBalance  READ totalBalance  NOTIFY totalBalanceChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit FinanceController(FinanceService* service, DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList payments() const { return m_payments; }
    QVariantList projets() const { return m_projets; }
    QVariantList donateurs() const { return m_donateurs; }
    QVariantList dons() const { return m_dons; }
    QVariantList tarifs() const { return m_tarifs; }
    QVariantList depenses() const { return m_depenses; }
    QVariantList personnelPaymentsForJournal() const { return m_personnelPaymentsForJournal; }
    QVariantMap  annualBalance() const { return m_annualBalance; }
    QVariantMap  totalBalance()  const { return m_totalBalance; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

    // Paiements
    Q_INVOKABLE void loadPaymentsByMonth(int month, int year);
    Q_INVOKABLE void loadPaymentsByStudent(int eleveId);
    Q_INVOKABLE void recordPayment(const QVariantMap& data);
    Q_INVOKABLE void overwritePayment(const QVariantMap& data);
    Q_INVOKABLE void updatePayment(int id, const QVariantMap& data);
    Q_INVOKABLE void deletePayment(int id);

    // Projets
    Q_INVOKABLE void loadProjets();
    Q_INVOKABLE void createProjet(const QVariantMap& data);
    Q_INVOKABLE void updateProjet(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteProjet(int id);

    // Donateurs & Dons
    Q_INVOKABLE void loadDonateurs();
    Q_INVOKABLE void createDonateur(const QVariantMap& data);
    Q_INVOKABLE void loadAllDons();
    Q_INVOKABLE void loadDonsByProjet(int projetId);
    Q_INVOKABLE void recordDon(const QVariantMap& data);
    Q_INVOKABLE void updateDon(int id, const QVariantMap& data);

    // Dépenses
    Q_INVOKABLE void loadDepensesByMonth(int month, int year);
    Q_INVOKABLE void createDepense(const QVariantMap& data);
    Q_INVOKABLE void updateDepense(int id, const QVariantMap& data);
    Q_INVOKABLE void deleteDepense(int id);

    // Donateurs — mise à jour + export
    Q_INVOKABLE void updateDonateur(int id, const QVariantMap& data);
    Q_INVOKABLE void exportDonateursCSV(const QString& filePath);

    // Tarifs
    Q_INVOKABLE void loadTarifs(int month, int year);

    // Personnel payments (for journal)
    Q_INVOKABLE void loadPersonnelPaymentsForJournal(int month, int year);

    // Bilan financier
    Q_INVOKABLE void loadAnnualBalance(int year);
    Q_INVOKABLE void loadTotalBalance();

signals:
    void paymentsChanged();
    void projetsChanged();
    void donateursChanged();
    void donsChanged();
    void depensesChanged();
    void tarifsChanged();
    void personnelPaymentsForJournalChanged();
    void annualBalanceChanged();
    void totalBalanceChanged();
    void loadingChanged();
    void errorMessageChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);

    FinanceService* m_service = nullptr;
    DatabaseWorker* m_worker  = nullptr;
    QVariantList m_payments;
    QVariantList m_projets;
    QVariantList m_donateurs;
    QVariantList m_dons;
    QVariantList m_depenses;
    QVariantList m_tarifs;
    QVariantList m_personnelPaymentsForJournal;
    QVariantMap  m_annualBalance;
    QVariantMap  m_totalBalance;
    bool    m_loading      = false;
    QString m_errorMessage;
};
