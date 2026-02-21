#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class StaffService;
class FinanceService;
class DatabaseWorker;

class StaffController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList personnel READ personnel NOTIFY personnelChanged)
    Q_PROPERTY(QVariantList enseignants READ enseignants NOTIFY enseignantsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int currentMonth READ currentMonth WRITE setCurrentMonth NOTIFY currentMonthChanged)
    Q_PROPERTY(int currentYear READ currentYear WRITE setCurrentYear NOTIFY currentYearChanged)

public:
    explicit StaffController(StaffService* service, FinanceService* financeService,
                             DatabaseWorker* worker, QObject* parent = nullptr);

    QVariantList personnel() const { return m_personnel; }
    QVariantList enseignants() const { return m_enseignants; }
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    int currentMonth() const { return m_currentMonth; }
    int currentYear() const { return m_currentYear; }

    void setCurrentMonth(int month);
    void setCurrentYear(int year);

    Q_INVOKABLE void loadPersonnel();
    Q_INVOKABLE void createPersonnel(const QString& nom, const QString& telephone,
                                      const QString& poste, const QString& specialite,
                                      const QString& modePaie, double valeurBase,
                                      const QString& statut);
    Q_INVOKABLE void updatePersonnel(int id, const QString& nom, const QString& telephone,
                                      const QString& poste, const QString& specialite,
                                      const QString& modePaie, double valeurBase,
                                      const QString& statut);
    Q_INVOKABLE void deletePersonnel(int id);
    Q_INVOKABLE void updateTarif(int profId, double nouveauPrix);
    Q_INVOKABLE double getMonthlySalary(int hours, double rate);

    // Paiements personnel
    Q_INVOKABLE void loadPaymentData(int personnelId, int mois, int annee);
    Q_INVOKABLE void savePayment(int personnelId, int mois, int annee,
                                 double sommeDue, double sommePaye);
    Q_INVOKABLE void recalculateSommeDue(int personnelId, int mois, int annee);

signals:
    void personnelChanged();
    void enseignantsChanged();
    void loadingChanged();
    void errorMessageChanged();
    void currentMonthChanged();
    void currentYearChanged();
    void operationSucceeded(const QString& message);
    void operationFailed(const QString& error);
    void paymentDataLoaded(const QVariantMap& data);

private slots:
    void onQueryCompleted(const QString& queryId, const QVariant& result);
    void onQueryError(const QString& queryId, const QString& error);

private:
    void setLoading(bool v);

    StaffService* m_service = nullptr;
    FinanceService* m_financeService = nullptr;
    DatabaseWorker* m_worker = nullptr;
    QVariantList m_personnel;
    QVariantList m_enseignants;
    bool m_loading = false;
    QString m_errorMessage;
    int m_currentMonth = 1;
    int m_currentYear = 2026;
};
