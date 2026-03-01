#include "controllers/staff_controller.h"
#include "services/staff_service.h"
#include "services/finance_service.h"
#include "database/database_worker.h"

#include <QSet>

static QVariantMap contratToMap(const Contrat& c) {
    QVariantMap m;
    m["contratId"] = c.id;
    m["poste"] = c.poste;
    m["specialite"] = c.specialite;
    m["modePaie"] = c.modePaie;
    m["valeurBase"] = c.valeurBase;
    m["joursTravail"] = c.joursTravail;
    m["dateDebut"] = c.dateDebut.toString("dd/MM/yyyy");
    m["dateFin"] = c.dateFin.isValid() ? c.dateFin.toString("dd/MM/yyyy") : "";
    m["dateDebutISO"] = c.dateDebut.toString(Qt::ISODate);
    m["dateFinISO"] = c.dateFin.isValid() ? c.dateFin.toString(Qt::ISODate) : "";
    return m;
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
        // Use month range to find contracts overlapping any part of the month
        auto result = staffSvc->getPersonnelForMonth(month, year);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        // Load all payments for this month
        auto paymentsResult = financeSvc->getAllPersonnelPaymentsForMonth(month, year);
        QMap<int, PaiementMensuelPersonnel> paymentsMap;
        if (paymentsResult.isOk()) {
            for (const auto& payment : paymentsResult.value())
                paymentsMap[payment.personnelId] = payment;
        }

        // Deduplicate by personnel ID (keep the most recent contract - first in list)
        QSet<int> seenPersonnel;
        QVariantList list;
        for (const auto& [person, contrat] : result.value()) {
            if (seenPersonnel.contains(person.id))
                continue;
            seenPersonnel.insert(person.id);

            QVariantMap map;
            // Personnel identity
            map["id"] = person.id;
            map["nom"] = person.nom;
            map["prenom"] = person.prenom;
            map["telephone"] = person.telephone;
            map["adresse"] = person.adresse;
            map["sexe"] = person.sexe;

            // Active contract data (most recent)
            map["contratId"] = contrat.id;
            map["poste"] = contrat.poste;
            map["specialite"] = contrat.specialite;
            map["modePaie"] = contrat.modePaie;
            map["valeurBase"] = contrat.valeurBase;
            map["dateDebut"] = contrat.dateDebut.toString("dd/MM/yyyy");
            map["dateFin"] = contrat.dateFin.isValid() ? contrat.dateFin.toString("dd/MM/yyyy") : "";
            map["dateDebutISO"] = contrat.dateDebut.toString(Qt::ISODate);
            map["dateFinISO"] = contrat.dateFin.isValid() ? contrat.dateFin.toString(Qt::ISODate) : "";

            map["joursTravail"] = contrat.joursTravail;

            // Hours/days calculation per payment mode
            if (contrat.modePaie == "Heure") {
                auto minResult = staffSvc->getTotalMinutesForMonth(person.id, month, year);
                int minutes = minResult.isOk() ? minResult.value() : 0;
                map["heuresTravailes"] = minutes / 60;
                map["minutesTravailees"] = minutes;
                map["joursTravailes"] = 0;
            } else if (contrat.modePaie == "Jour") {
                auto joursResult = staffSvc->getTotalJoursForMonth(person.id, month, year);
                map["joursTravailes"] = joursResult.isOk() ? joursResult.value() : 0;
                map["heuresTravailes"] = 0;
                map["minutesTravailees"] = 0;
            } else {
                map["heuresTravailes"] = 0;
                map["minutesTravailees"] = 0;
                map["joursTravailes"] = 0;
            }

            // Contract count for history badge
            auto countResult = staffSvc->countContrats(person.id);
            map["nbContrats"] = countResult.isOk() ? countResult.value() : 1;

            // Payment data
            if (paymentsMap.contains(person.id)) {
                map["sommeDue"] = paymentsMap[person.id].sommeDue;
                map["sommePaye"] = paymentsMap[person.id].sommePaye;
            } else {
                // Calculate estimated amount
                auto calcResult = staffSvc->calculateSommeDue(person.id, month, year);
                map["sommeDue"] = calcResult.isOk() ? calcResult.value() : 0.0;
                map["sommePaye"] = 0.0;
            }

            list.append(map);
        }
        return list;
    });
}

void StaffController::loadAllPersonnel() {
    setLoading(true);
    m_worker->submit("Staff.loadAllPersonnel",
                     [staffSvc = m_service]() -> QVariant {
        auto result = staffSvc->getAllPersonnel();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        QDate today = QDate::currentDate();
        QVariantList list;
        for (const auto& person : result.value()) {
            QVariantMap map;
            map["id"] = person.id;
            map["nom"] = person.nom;
            map["prenom"] = person.prenom;
            map["telephone"] = person.telephone;
            map["adresse"] = person.adresse;
            map["sexe"] = person.sexe;

            auto countResult = staffSvc->countContrats(person.id);
            map["nbContrats"] = countResult.isOk() ? countResult.value() : 0;

            // No payment/hours calculation for "show all" mode
            map["heuresTravailes"] = 0;
            map["minutesTravailees"] = 0;
            map["joursTravailes"] = 0;
            map["sommeDue"] = 0.0;
            map["sommePaye"] = 0.0;
            map["showAllMode"] = true;

            // Load the most recent contract (first in list, ordered by date_debut DESC)
            auto histResult = staffSvc->getContratHistorique(person.id);
            if (histResult.isOk() && !histResult.value().isEmpty()) {
                const auto& latestContrat = histResult.value().first();
                map["contratId"] = latestContrat.id;
                map["poste"] = latestContrat.poste;
                map["specialite"] = latestContrat.specialite;
                map["modePaie"] = latestContrat.modePaie;
                map["valeurBase"] = latestContrat.valeurBase;
                map["joursTravail"] = latestContrat.joursTravail;
                map["dateDebut"] = latestContrat.dateDebut.toString("dd/MM/yyyy");
                map["dateFin"] = latestContrat.dateFin.isValid() ? latestContrat.dateFin.toString("dd/MM/yyyy") : "";
                map["dateDebutISO"] = latestContrat.dateDebut.toString(Qt::ISODate);
                map["dateFinISO"] = latestContrat.dateFin.isValid() ? latestContrat.dateFin.toString(Qt::ISODate) : "";
            } else {
                map["contratId"] = 0;
                map["poste"] = "";
                map["specialite"] = "";
                map["modePaie"] = "";
                map["valeurBase"] = 0;
                map["joursTravail"] = 31;
                map["dateDebut"] = "";
                map["dateFin"] = "";
                map["dateDebutISO"] = "";
                map["dateFinISO"] = "";
            }

            list.append(map);
        }
        return list;
    });
}

void StaffController::createPersonnel(const QString& nom, const QString& telephone,
                                       const QString& sexe,
                                       const QString& poste, const QString& specialite,
                                       const QString& modePaie, double valeurBase,
                                       const QString& dateDebut, const QString& dateFin,
                                       int joursTravail) {
    m_worker->submit("Staff.createPersonnel",
        [svc = m_service, nom, telephone, sexe, poste, specialite, modePaie, valeurBase, dateDebut, dateFin, joursTravail]() -> QVariant {
        Personnel p;
        p.nom = nom.trimmed();
        p.prenom = "";
        p.telephone = telephone.trimmed();
        p.adresse = "";
        p.sexe = sexe.isEmpty() ? "M" : sexe;

        auto result = svc->createPersonnel(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        int personnelId = result.value();

        // Create initial contract
        Contrat c;
        c.personnelId = personnelId;
        c.poste = poste.isEmpty() ? "Enseignant" : poste;
        c.specialite = specialite.trimmed();
        c.modePaie = modePaie.isEmpty() ? "Heure" : modePaie;
        c.valeurBase = valeurBase;
        c.joursTravail = joursTravail > 0 ? joursTravail : 31;
        c.dateDebut = QDate::fromString(dateDebut, Qt::ISODate);
        if (!c.dateDebut.isValid())
            c.dateDebut = QDate::currentDate();
        if (!dateFin.isEmpty())
            c.dateFin = QDate::fromString(dateFin, Qt::ISODate);

        auto contratResult = svc->createContrat(c);
        if (!contratResult.isOk())
            return QVariantMap{{"error", contratResult.errorMessage()}};

        return QVariantMap{{"success", true}};
    });
}

void StaffController::updatePersonnel(int id, const QString& nom, const QString& telephone,
                                       const QString& sexe) {
    m_worker->submit("Staff.updatePersonnel",
        [svc = m_service, id, nom, telephone, sexe]() -> QVariant {
        Personnel p;
        p.id = id;
        p.nom = nom.trimmed();
        p.prenom = "";
        p.telephone = telephone.trimmed();
        p.adresse = "";
        p.sexe = sexe.isEmpty() ? "M" : sexe;

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

void StaffController::createContrat(int personnelId, const QString& poste, const QString& specialite,
                                     const QString& modePaie, double valeurBase,
                                     const QString& dateDebut, const QString& dateFin,
                                     int joursTravail) {
    m_worker->submit("Staff.createContrat",
        [svc = m_service, personnelId, poste, specialite, modePaie, valeurBase, dateDebut, dateFin, joursTravail]() -> QVariant {
        Contrat c;
        c.personnelId = personnelId;
        c.poste = poste.isEmpty() ? "Enseignant" : poste;
        c.specialite = specialite.trimmed();
        c.modePaie = modePaie.isEmpty() ? "Heure" : modePaie;
        c.valeurBase = valeurBase;
        c.joursTravail = joursTravail > 0 ? joursTravail : 31;
        c.dateDebut = QDate::fromString(dateDebut, Qt::ISODate);
        if (!c.dateDebut.isValid())
            c.dateDebut = QDate::currentDate();
        if (!dateFin.isEmpty())
            c.dateFin = QDate::fromString(dateFin, Qt::ISODate);

        auto result = svc->createContrat(c);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::updateContrat(int contratId, int personnelId, const QString& poste,
                                     const QString& specialite, const QString& modePaie,
                                     double valeurBase, const QString& dateDebut, const QString& dateFin,
                                     int joursTravail) {
    m_worker->submit("Staff.updateContrat",
        [svc = m_service, contratId, personnelId, poste, specialite, modePaie, valeurBase, dateDebut, dateFin, joursTravail]() -> QVariant {
        Contrat c;
        c.id = contratId;
        c.personnelId = personnelId;
        c.poste = poste;
        c.specialite = specialite;
        c.modePaie = modePaie;
        c.valeurBase = valeurBase;
        c.joursTravail = joursTravail > 0 ? joursTravail : 31;
        c.dateDebut = QDate::fromString(dateDebut, Qt::ISODate);
        if (!dateFin.isEmpty())
            c.dateFin = QDate::fromString(dateFin, Qt::ISODate);

        auto result = svc->updateContrat(c);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::deleteContrat(int contratId) {
    m_worker->submit("Staff.deleteContrat", [svc = m_service, contratId]() -> QVariant {
        auto result = svc->deleteContrat(contratId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StaffController::loadContratHistorique(int personnelId) {
    m_worker->submit("Staff.loadContratHistorique",
        [svc = m_service, personnelId]() -> QVariant {
        auto result = svc->getContratHistorique(personnelId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        QVariantList list;
        for (const auto& c : result.value())
            list.append(contratToMap(c));
        return list;
    });
}

void StaffController::loadPaymentData(int personnelId, int mois, int annee) {
    setLoading(true);
    m_worker->submit("Staff.loadPaymentData",
                     [staffSvc = m_service, financeSvc = m_financeService, personnelId, mois, annee]() -> QVariant {
        auto paymentResult = financeSvc->getPersonnelPayment(personnelId, mois, annee);
        if (!paymentResult.isOk())
            return QVariantMap{{"error", paymentResult.errorMessage()}};

        auto paymentOpt = paymentResult.value();
        if (!paymentOpt.has_value()) {
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
            {"datePaiement", p.datePaiement},
            {"justificatifPath", p.justificatifPath},
            {"isNew", false}
        };
    });
}

void StaffController::savePayment(int personnelId, int mois, int annee, double sommeDue, double sommePaye, const QString& datePaiement, const QString& justificatifPath) {
    m_worker->submit("Staff.savePayment", [financeSvc = m_financeService, personnelId, mois, annee, sommeDue, sommePaye, datePaiement, justificatifPath]() -> QVariant {
        PaiementMensuelPersonnel p;
        p.personnelId = personnelId;
        p.mois = mois;
        p.annee = annee;
        p.sommeDue = sommeDue;
        p.sommePaye = sommePaye;
        p.dateModification = QDateTime::currentDateTime();
        p.datePaiement = datePaiement;
        p.justificatifPath = justificatifPath;

        auto result = financeSvc->savePersonnelPayment(p);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};

        return QVariantMap{{"success", true}};
    });
}

void StaffController::recalculateSommeDue(int personnelId, int mois, int annee) {
    setLoading(true);
    m_worker->submit("Staff.recalculateSommeDue",
                     [staffSvc = m_service, personnelId, mois, annee]() -> QVariant {
        auto result = staffSvc->calculateSommeDue(personnelId, mois, annee);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"sommeDue", result.value()}};
    });
}

void StaffController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Staff.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Staff.loadPersonnel" || queryId == "Staff.loadAllPersonnel") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else {
            m_personnel = result.toList();
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
        else emit operationSucceeded("Personnel ajouté");
    }
    else if (queryId == "Staff.updatePersonnel") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Personnel mis à jour");
    }
    else if (queryId == "Staff.deletePersonnel") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Personnel supprimé");
    }
    else if (queryId == "Staff.createContrat") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Contrat créé");
    }
    else if (queryId == "Staff.updateContrat") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Contrat mis à jour");
    }
    else if (queryId == "Staff.deleteContrat") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Contrat supprimé");
    }
    else if (queryId == "Staff.loadContratHistorique") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit contratHistoriqueLoaded(result.toList());
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
