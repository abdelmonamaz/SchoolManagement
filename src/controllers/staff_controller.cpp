#include "controllers/staff_controller.h"
#include "services/staff_service.h"
#include "services/finance_service.h"
#include "database/database_worker.h"

static QString statutProfToString(GS::StatutProf s) {
    return s == GS::StatutProf::EnConge ? QStringLiteral("En congé") : QStringLiteral("Actif");
}

static GS::StatutProf stringToStatutProf(const QString& s) {
    return s == QStringLiteral("En congé") ? GS::StatutProf::EnConge : GS::StatutProf::Actif;
}

static QVariantMap personnelToMap(const Personnel& p) {
    return {
        {"id", p.id}, {"nom", p.nom}, {"prenom", p.prenom},
        {"telephone", p.telephone}, {"adresse", p.adresse},
        {"poste", p.poste}, {"specialite", p.specialite},
        {"modePaie", p.modePaie}, {"valeurBase", p.valeurBase},
        {"heuresTravailes", p.heuresTravailes},
        {"statut", statutProfToString(p.statut)}, {"prixHeureActuel", p.prixHeureActuel}
    };
}

StaffController::StaffController(StaffService* service, FinanceService* financeService,
                                 DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_financeService(financeService), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &StaffController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &StaffController::onQueryError);
}

void StaffController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void StaffController::setCurrentMonth(int month) {
    if (m_currentMonth != month) {
        m_currentMonth = month;
        emit currentMonthChanged();
    }
}

void StaffController::setCurrentYear(int year) {
    if (m_currentYear != year) {
        m_currentYear = year;
        emit currentYearChanged();
    }
}

void StaffController::loadPersonnel() {
    setLoading(true);
    m_worker->submit("Staff.loadPersonnel",
                     [staffSvc = m_service, financeSvc = m_financeService,
                      month = m_currentMonth, year = m_currentYear]() -> QVariant {
        auto result = staffSvc->getAllPersonnel();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        // Charger tous les paiements du mois actuel
        auto paymentsResult = financeSvc->getAllPersonnelPaymentsForMonth(month, year);
        QMap<int, PaiementMensuelPersonnel> paymentsMap;

        if (paymentsResult.isOk()) {
            for (const auto& payment : paymentsResult.value()) {
                paymentsMap[payment.personnelId] = payment;
            }
        }

        QVariantList list;
        for (const auto& p : result.value()) {
            auto map = personnelToMap(p);

            if (paymentsMap.contains(p.id)) {
                map["sommeDue"] = paymentsMap[p.id].sommeDue;
                map["sommePaye"] = paymentsMap[p.id].sommePaye;
            } else {
                double estimated = 0.0;
                if (p.modePaie == "Heure") {
                    estimated = p.heuresTravailes * p.valeurBase;
                } else {
                    estimated = p.valeurBase;
                }
                map["sommeDue"] = estimated;
                map["sommePaye"] = 0.0;
            }

            list.append(map);
        }
        return list;
    });
}

void StaffController::createPersonnel(const QString& nom, const QString& telephone,
                                       const QString& poste, const QString& specialite,
                                       const QString& modePaie, double valeurBase,
                                       const QString& statut) {
    m_worker->submit("Staff.createPersonnel", [svc = m_service, nom, telephone, poste, specialite,
                                                 modePaie, valeurBase, statut]() -> QVariant {
        Personnel p;
        p.nom = nom.trimmed();
        p.prenom = "";  // Pas de prénom dans le formulaire
        p.telephone = telephone.trimmed();
        p.adresse = "";  // Pas d'adresse dans le formulaire
        p.poste = poste.isEmpty() ? "Enseignant" : poste;
        p.specialite = specialite.trimmed();
        p.modePaie = modePaie.isEmpty() ? "Heure" : modePaie;
        p.valeurBase = valeurBase;
        p.heuresTravailes = 0;
        p.statut = stringToStatutProf(statut);

        auto result = svc->createPersonnel(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::updatePersonnel(int id, const QString& nom, const QString& telephone,
                                       const QString& poste, const QString& specialite,
                                       const QString& modePaie, double valeurBase,
                                       const QString& statut) {
    m_worker->submit("Staff.updatePersonnel", [svc = m_service, id, nom, telephone, poste, specialite,
                                                 modePaie, valeurBase, statut]() -> QVariant {
        Personnel p;
        p.id = id;
        p.nom = nom.trimmed();
        p.prenom = "";  // Pas de prénom dans le formulaire
        p.telephone = telephone.trimmed();
        p.adresse = "";  // Pas d'adresse dans le formulaire
        p.poste = poste.isEmpty() ? "Enseignant" : poste;
        p.specialite = specialite.trimmed();
        p.modePaie = modePaie.isEmpty() ? "Heure" : modePaie;
        p.valeurBase = valeurBase;
        p.heuresTravailes = 0;
        p.statut = stringToStatutProf(statut);

        auto result = svc->updatePersonnel(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::deletePersonnel(int id) {
    m_worker->submit("Staff.deletePersonnel", [svc = m_service, id]() -> QVariant {
        auto result = svc->deletePersonnel(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::updateTarif(int profId, double nouveauPrix) {
    m_worker->submit("Staff.updateTarif", [svc = m_service, profId, nouveauPrix]() -> QVariant {
        auto result = svc->updateTarif(profId, nouveauPrix);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

double StaffController::getMonthlySalary(int hours, double rate) {
    Personnel p;
    p.prixHeureActuel = rate;
    return m_service->calculateMonthlySalary(p, hours);
}

void StaffController::loadPaymentData(int personnelId, int mois, int annee) {
    setLoading(true);
    m_worker->submit("Staff.loadPaymentData",
                     [staffSvc = m_service, financeSvc = m_financeService, personnelId, mois, annee]() -> QVariant {
        // Try to load existing payment
        auto paymentResult = financeSvc->getPersonnelPayment(personnelId, mois, annee);
        if (!paymentResult.isOk()) {
            return QVariantMap{{"error", paymentResult.errorMessage()}};
        }

        auto paymentOpt = paymentResult.value();
        if (!paymentOpt.has_value()) {
            // No existing payment: calculate estimated sommeDue
            auto calcResult = staffSvc->calculateSommeDue(personnelId, mois, annee);
            double estimated = calcResult.isOk() ? calcResult.value() : 0.0;
            return QVariantMap{
                {"personnelId", personnelId},
                {"mois", mois},
                {"annee", annee},
                {"sommeDue", estimated},
                {"sommePaye", 0.0},
                {"isNew", true}
            };
        }

        const auto& p = paymentOpt.value();
        return QVariantMap{
            {"id", p.id},
            {"personnelId", p.personnelId},
            {"mois", p.mois},
            {"annee", p.annee},
            {"sommeDue", p.sommeDue},
            {"sommePaye", p.sommePaye},
            {"isNew", false}
        };
    });
}

void StaffController::savePayment(int personnelId, int mois, int annee,
                                  double sommeDue, double sommePaye) {
    setLoading(true);
    m_worker->submit("Staff.savePayment",
                     [financeSvc = m_financeService, personnelId, mois, annee, sommeDue, sommePaye]() -> QVariant {
        PaiementMensuelPersonnel p;
        p.personnelId = personnelId;
        p.mois = mois;
        p.annee = annee;
        p.sommeDue = sommeDue;
        p.sommePaye = sommePaye;
        p.dateModification = QDateTime::currentDateTime();

        auto result = financeSvc->savePersonnelPayment(p);
        if (!result.isOk()) {
            return QVariantMap{{"error", result.errorMessage()}};
        }
        return QVariantMap{{"success", true}};
    });
}

void StaffController::recalculateSommeDue(int personnelId, int mois, int annee) {
    setLoading(true);
    m_worker->submit("Staff.recalculateSommeDue",
                     [staffSvc = m_service, personnelId, mois, annee]() -> QVariant {
        auto result = staffSvc->calculateSommeDue(personnelId, mois, annee);
        if (!result.isOk()) {
            return QVariantMap{{"error", result.errorMessage()}};
        }
        return QVariantMap{{"sommeDue", result.value()}};
    });
}

void StaffController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Staff.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Staff.loadPersonnel") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else {
            m_personnel = result.toList();
            // Filter enseignants
            m_enseignants.clear();
            for (const auto& item : m_personnel) {
                auto m = item.toMap();
                if (m.value("poste").toString() == QStringLiteral("Enseignant"))
                    m_enseignants.append(item);
            }
            emit personnelChanged();
            emit enseignantsChanged();
        }
        setLoading(false);
    }
    else if (queryId == "Staff.createPersonnel") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Personnel ajouté"); loadPersonnel(); }
    }
    else if (queryId == "Staff.updatePersonnel") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Personnel mis à jour"); loadPersonnel(); }
    }
    else if (queryId == "Staff.deletePersonnel") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Personnel supprimé"); loadPersonnel(); }
    }
    else if (queryId == "Staff.updateTarif") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Tarif mis à jour"); loadPersonnel(); }
    }
    else if (queryId == "Staff.loadPaymentData") {
        setLoading(false);
        if (isError) emit operationFailed(map["error"].toString());
        else emit paymentDataLoaded(map);
    }
    else if (queryId == "Staff.savePayment") {
        setLoading(false);
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Paiement enregistré");
    }
    else if (queryId == "Staff.recalculateSommeDue") {
        setLoading(false);
        if (isError) emit operationFailed(map["error"].toString());
        else emit paymentDataLoaded(map);
    }
}

void StaffController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Staff.")) return;

    if (queryId == "Staff.loadPersonnel") {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
