#include "controllers/grades_controller.h"
#include "services/grades_service.h"
#include "database/database_worker.h"

#include <algorithm>
#include <QDate>
#include <QFile>
#include <QRegularExpression>
#include <QStringConverter>
#include <QTextStream>
#include <QStandardPaths>
#include <QTextDocument>
#include <QPdfWriter>
#include <QPageLayout>
#include <QPageSize>

static QString typePresenceToString(GS::TypePresence t) {
    switch (t) {
        case GS::TypePresence::Present: return QStringLiteral("Présent");
        case GS::TypePresence::Absent: return QStringLiteral("Absent");
        case GS::TypePresence::Retard: return QStringLiteral("Retard");
    }
    return QStringLiteral("Présent");
}

static QVariantMap participationToMap(const Participation& p) {
    return {
        {"id", p.id}, {"seanceId", p.seanceId}, {"eleveId", p.eleveId},
        {"statut", typePresenceToString(p.statut)},
        {"note", p.note < 0 ? QVariant() : QVariant(p.note)},
        {"estInvite", p.estInvite}
    };
}

// ── HTML bulletin builder ────────────────────────────────────────────────────
static QString appreciation(double note) {
    if (note >= 18.0) return QStringLiteral("Excellent");
    if (note >= 15.0) return QStringLiteral("Très Bien");
    if (note >= 12.0) return QStringLiteral("Bien");
    if (note >= 10.0) return QStringLiteral("Assez Bien");
    if (note >=  7.0) return QStringLiteral("Passable");
    return QStringLiteral("Insuffisant");
}

static QString apprBg(double note) {
    if (note >= 15.0) return QStringLiteral("#d4edda");
    if (note >= 10.0) return QStringLiteral("#fff3cd");
    return QStringLiteral("#f8d7da");
}

static QString apprFg(double note) {
    if (note >= 15.0) return QStringLiteral("#155724");
    if (note >= 10.0) return QStringLiteral("#856404");
    return QStringLiteral("#721c24");
}

// kept for compatibility but no longer used
static QString apprColor(double note) {
    return apprBg(note) + QStringLiteral(";color:") + apprFg(note);
}

static QString buildBulletinHtml(const QVariantMap& data,
                                  const QString& studentName,
                                  const QString& studentMatricule,
                                  const QString& niveauNom,
                                  const QString& classeNom,
                                  const QString& anneeScolaire)
{
    const QString green   = QStringLiteral("#2E7D52");
    const QString amber   = QStringLiteral("#F59E0B");
    const QString rowAlt  = QStringLiteral("#F8FFFE");
    const QString infoBox = QStringLiteral("#F8F9FA");

    QStringList html;
    html << QStringLiteral(
        "<html><head><meta charset=\"UTF-8\"><style>"
        "body{font-family:Arial,Helvetica,sans-serif;font-size:10pt;color:#1a1a2e;margin:0;padding:0;}"
        "table{width:100%;border-collapse:collapse;}"
        "th{background:#2E7D52;color:white;font-size:8pt;padding:6px 8px;text-align:left;font-weight:bold;}"
        "th.center{text-align:center;}"
        "td{padding:6px 8px;font-size:10pt;border-bottom:1px solid #F0F0F0;vertical-align:middle;}"
        "td.center{text-align:center;}"
        "td.bold{font-weight:bold;}"
        ".label{font-size:7pt;color:#999;font-weight:bold;}"
        ".value{font-size:12pt;font-weight:bold;}"
        ".gen-row td{background:#F0FFF4;border-top:2px solid #2E7D52;font-weight:bold;}"
        ".alt{background:#F8FFFE;}"
        "</style></head><body>"
    );

    // ── En-tête école ────────────────────────────────────────────────────────
    const QString assocNom  = data.value("associationNom",
                                         QStringLiteral("Ez-Zaytouna")).toString();
    const QString assocAddr = data.value("associationAdresse", QString()).toString();

    html << QStringLiteral(
        "<table style=\"border-bottom:2px solid #2E7D52;margin-bottom:8px;\"><tr>"
        "<td style=\"padding:4px 0;\">"
        "<span style=\"font-size:20pt;font-weight:bold;color:#2E7D52;\">%1</span><br>"
        "<span style=\"font-size:8pt;color:#888;font-weight:bold;\">INSTITUT D'ENSEIGNEMENT ISLAMIQUE</span><br>"
        "<span style=\"font-size:8pt;color:#AAA;\">%2</span>"
        "</td>"
        "<td align=\"right\" width=\"130\" style=\"padding:4px 0;\">"
        "<table cellspacing=\"0\" cellpadding=\"4\" width=\"120\""
        " style=\"border:2px solid #F59E0B;\"><tr><td align=\"center\">"
        "<div style=\"font-size:7pt;color:#F59E0B;font-weight:bold;\">ANNÉE SCOLAIRE</div>"
        "<div style=\"font-size:13pt;font-weight:bold;color:#F59E0B;\">%3</div>"
        "</td></tr></table>"
        "</td></tr></table>"
    ).arg(assocNom.toHtmlEscaped(),
          assocAddr.isEmpty() ? QString() : assocAddr.toHtmlEscaped(),
          anneeScolaire.toHtmlEscaped());

    // ── Titre ────────────────────────────────────────────────────────────────
    html << QStringLiteral(
        "<div style=\"background:#2E7D52;color:white;font-size:14pt;font-weight:bold;"
        "text-align:center;padding:7px 0;margin-bottom:8px;\">BULLETIN SCOLAIRE</div>"
    );

    // ── Info élève ───────────────────────────────────────────────────────────
    html << QStringLiteral(
        "<table style=\"background:#F8F9FA;border:1px solid #E0E0E0;margin-bottom:10px;\"><tr>"
        "<td width=\"50%\"><div class=\"label\">NOM DE L'ÉLÈVE</div>"
        "<div class=\"value\">%1</div></td>"
        "<td><div class=\"label\">MATRICULE</div>"
        "<div class=\"value\">%2</div></td>"
        "</tr><tr>"
        "<td><div class=\"label\">NIVEAU</div>"
        "<div class=\"value\">%3</div></td>"
        "<td><div class=\"label\">CLASSE</div>"
        "<div class=\"value\">%4</div></td>"
        "</tr></table>"
    ).arg(studentName.toHtmlEscaped(),
          studentMatricule.toHtmlEscaped(),
          niveauNom.toHtmlEscaped(),
          classeNom.toHtmlEscaped());

    // ── Section RÉSULTATS ────────────────────────────────────────────────────
    html << QStringLiteral(
        "<div style=\"font-size:10pt;font-weight:bold;margin-bottom:5px;"
        "padding-left:8px;border-left:3px solid #2E7D52;\">RÉSULTATS ACADÉMIQUES</div>"
    );

    // ── Collect unique épreuve titles ────────────────────────────────────────
    QVariantList matieres = data["matieres"].toList();
    QStringList allTitres;
    for (const auto& matV : matieres) {
        for (const auto& epV : matV.toMap()["epreuves"].toList()) {
            QString t = epV.toMap()["titre"].toString();
            if (!allTitres.contains(t)) allTitres << t;
        }
    }

    // ── Tableau des notes ────────────────────────────────────────────────────
    html << QStringLiteral("<table>");
    html << QStringLiteral("<tr><th>MATIÈRE</th>");
    for (const QString& t : allTitres)
        html << QStringLiteral("<th class=\"center\">%1</th>").arg(t.toHtmlEscaped().toUpper());
    html << QStringLiteral("<th class=\"center\">MOYENNE</th>"
                           "<th class=\"center\">APPRÉCIATION</th>"
                           "<th class=\"center\">PRÉSENCE</th></tr>");

    double totalSum = 0.0; int totalCount = 0;
    bool altRow = false;
    for (const auto& matV : matieres) {
        auto mat = matV.toMap();
        QMap<QString,double> noteByTitre;
        for (const auto& epV : mat["epreuves"].toList()) {
            auto ep = epV.toMap();
            if (ep["hasNote"].toBool())
                noteByTitre[ep["titre"].toString()] = ep["note"].toDouble();
        }
        double moyenne = mat["moyenne"].isNull() ? -1.0 : mat["moyenne"].toDouble();
        if (moyenne >= 0.0) { totalSum += moyenne; ++totalCount; }

        int pCount = mat["presenceCount"].toInt();
        int pTotal = mat["totalSeances"].toInt();

        QString matNom = QStringLiteral("Matière #%1").arg(mat["matiereId"].toInt());
        // (remplacé par exportBulletinPdf avec le vrai nom)

        QString rowStyle = altRow
            ? QStringLiteral(" style=\"background:#F8FFFE;\"")
            : QStringLiteral("");
        altRow = !altRow;

        html << QStringLiteral("<tr%1><td class=\"bold\">%2</td>").arg(rowStyle, matNom.toHtmlEscaped());
        for (const QString& t : allTitres) {
            if (noteByTitre.contains(t))
                html << QStringLiteral("<td class=\"center bold\">%1/20</td>")
                               .arg(QString::number(noteByTitre[t], 'f', 1));
            else
                html << QStringLiteral("<td class=\"center\" style=\"color:#CCC;\">—</td>");
        }
        if (moyenne >= 0.0) {
            html << QStringLiteral(
                "<td class=\"center\" style=\"color:#2E7D52;font-size:12pt;font-weight:bold;\">%1/20</td>"
                "<td class=\"center\"><span style=\"background:%2;color:%3;padding:2px 7px;"
                "font-size:8pt;font-weight:bold;\">%4</span></td>"
            ).arg(QString::number(moyenne, 'f', 2),
                  apprBg(moyenne),
                  apprFg(moyenne),
                  appreciation(moyenne));
        } else {
            html << QStringLiteral("<td class=\"center\" style=\"color:#CCC;\">—</td><td></td>");
        }
        html << QStringLiteral("<td class=\"center\" style=\"font-size:9pt;\">%1/%2</td>")
                        .arg(pCount).arg(pTotal);
        html << QStringLiteral("</tr>");
    }

    // ── Moyenne générale ─────────────────────────────────────────────────────
    double moyGen = totalCount > 0 ? totalSum / totalCount : -1.0;
    int epCount = allTitres.size();
    int presTotal  = data["presenceTotale"].toInt();
    int seancesTotal = data["seancesTotales"].toInt();

    html << QStringLiteral("<tr class=\"gen-row\">"
                           "<td colspan=\"%1\" style=\"border-left:none;\">MOYENNE GÉNÉRALE</td>")
                          .arg(1 + epCount);
    if (moyGen >= 0.0)
        html << QStringLiteral("<td class=\"center\" style=\"font-size:13pt;color:#2E7D52;\">%1/20</td>")
                         .arg(QString::number(moyGen, 'f', 2));
    else
        html << QStringLiteral("<td>—</td>");
    html << QStringLiteral("<td></td>");
    html << QStringLiteral("<td class=\"center\" style=\"font-size:9pt;font-weight:bold;\">%1/%2</td>")
                    .arg(presTotal).arg(seancesTotal);
    html << QStringLiteral("</tr></table>");

    // ── Espace avant signatures (pousse le bloc vers le bas de page) ─────────
    // A4 content ≈ 774pt. Fixed content ≈ 310pt. Per matière ≈ 22pt. Sigs+footer ≈ 80pt.
    // spacer = max(10, 384 - nMat * 22) pt
    {
        int nMat = matieres.size();
        int spacerPt = std::max(10, 384 - nMat * 22);
        html << QStringLiteral("<div style=\"height:%1pt;\"></div>").arg(spacerPt);
    }

    // ── Signatures ───────────────────────────────────────────────────────────
    html << QStringLiteral(
        "<table style=\"margin-top:0;\"><tr>"
        "<td width=\"35%\" align=\"center\" style=\"border:none;\">"
        "<div style=\"border-top:1px solid #CCC;padding-top:4px;height:36px;\"></div>"
        "<div style=\"font-size:8pt;font-weight:bold;color:#999;\">ENSEIGNANT</div>"
        "</td>"
        "<td width=\"30%\" style=\"border:none;\"></td>"
        "<td width=\"35%\" align=\"center\" style=\"border:none;\">"
        "<div style=\"border-top:1px solid #CCC;padding-top:4px;height:36px;\"></div>"
        "<div style=\"font-size:8pt;font-weight:bold;color:#999;\">DIRECTEUR</div>"
        "</td></tr></table>"
    );

    // ── Footer ───────────────────────────────────────────────────────────────
    html << QStringLiteral(
        "<div style=\"text-align:center;font-size:8pt;color:#AAA;"
        "margin-top:16px;border-top:1px solid #EEE;padding-top:8px;\">"
        "%1<br>"
        "Document g&eacute;n&eacute;r&eacute; le %2</div>"
    ).arg(assocNom.toHtmlEscaped(),
          QDate::currentDate().toString("dd/MM/yyyy"));

    html << QStringLiteral("</body></html>");
    return html.join(QString());
}

// ── Controller ───────────────────────────────────────────────────────────────
GradesController::GradesController(GradesService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &GradesController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &GradesController::onQueryError);
}

void GradesController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void GradesController::loadGradesBySeance(int seanceId) {
    setLoading(true);
    m_worker->submit("Grades.loadGradesBySeance", [svc = m_service, seanceId]() -> QVariant {
        auto result = svc->getGradesBySeance(seanceId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(participationToMap(p));
        return list;
    });
}

void GradesController::loadGradesByStudent(int eleveId) {
    setLoading(true);
    m_worker->submit("Grades.loadGradesByStudent", [svc = m_service, eleveId]() -> QVariant {
        auto result = svc->getGradesByStudent(eleveId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& p : result.value()) list.append(participationToMap(p));
        return list;
    });
}

void GradesController::saveGrade(int participationId, double note) {
    m_worker->submit("Grades.saveGrade", [svc = m_service, participationId, note]() -> QVariant {
        auto result = svc->saveGrade(participationId, note);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void GradesController::saveGrades(const QVariantList& grades) {
    m_worker->submit("Grades.saveGrades", [svc = m_service, grades]() -> QVariant {
        QList<QPair<int, double>> gradesList;
        for (const auto& g : grades) {
            auto map = g.toMap();
            gradesList.append({map.value("participationId").toInt(), map.value("note").toDouble()});
        }
        auto result = svc->saveGrades(gradesList);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void GradesController::loadClassAverage(int seanceId) {
    m_worker->submit("Grades.loadClassAverage", [svc = m_service, seanceId]() -> QVariant {
        auto result = svc->calculateAverage(seanceId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"average", result.value()}};
    });
}

void GradesController::loadBulletinData(int eleveId, int classeId, int anneeId) {
    m_worker->submit("Grades.loadBulletinData", [svc = m_service, eleveId, classeId, anneeId]() -> QVariant {
        auto result = svc->buildBulletinData(eleveId, classeId, anneeId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return result.value();
    });
}

QString GradesController::exportBulletinPdf(const QVariantMap& bulletinData,
                                             const QString& studentName,
                                             const QString& studentMatricule,
                                             const QString& niveauNom,
                                             const QString& classeNom,
                                             const QString& anneeScolaire,
                                             const QString& targetPath)
{
    // Build HTML with placeholder matière names → replace after building
    QString html = buildBulletinHtml(bulletinData, studentName, studentMatricule,
                                     niveauNom, classeNom, anneeScolaire);

    // Replace "Matière #N" placeholders with real names passed via bulletinData
    QVariantList matieres = bulletinData["matieres"].toList();
    for (const auto& matV : matieres) {
        auto mat = matV.toMap();
        int id = mat["matiereId"].toInt();
        QString nom = mat.value("nom", QStringLiteral("Matière #%1").arg(id)).toString();
        html.replace(QStringLiteral("Matière #%1").arg(id), nom.toHtmlEscaped());
    }

    // Output path
    QString filePath;
    if (!targetPath.isEmpty()) {
        filePath = targetPath;
    } else {
        QString docsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        // Sanitize year: replace / with - (e.g. "2024/2025" → "2024-2025")
        QString safeYear = anneeScolaire;
        safeYear.replace('/', '-').replace('\\', '-');
        safeYear.remove(QRegularExpression(QStringLiteral("[^\\w\\s.-]")));
        safeYear = safeYear.simplified().replace(' ', '_');
        // Sanitize name: keep only ASCII word chars (non-ASCII like Arabic becomes empty → use ID)
        QString safeName = studentName;
        safeName.remove(QRegularExpression(QStringLiteral("[^\\w\\s-]")));
        safeName = safeName.simplified().replace(' ', '_');
        // Build filename: bulletin_[year]_[name or matricule].pdf
        QString safeMatricule = studentMatricule;
        safeMatricule.remove(QRegularExpression(QStringLiteral("[^\\w.-]")));
        QString namePart = safeName.isEmpty() ? safeMatricule : safeName;
        if (namePart.isEmpty()) namePart = QStringLiteral("eleve");
        filePath = QStringLiteral("%1/bulletin_%2_%3.pdf").arg(docsPath, safeYear, namePart);
    }

    QPdfWriter writer(filePath);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setPageMargins(QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter);
    writer.setResolution(96);

    // Use the paint rectangle in points (1pt = 1/72 inch) — QTextDocument coordinates
    QRectF paintRect = writer.pageLayout().paintRect(QPageLayout::Point);

    QTextDocument doc;
    doc.setHtml(html);
    doc.setPageSize(paintRect.size());
    doc.print(&writer);

    return filePath;
}

QString GradesController::exportBulletinCsv(const QVariantMap& bulletinData,
                                             const QString& studentName,
                                             const QString& niveauNom,
                                             const QString& classeNom,
                                             const QString& anneeScolaire,
                                             const QString& targetPath)
{
    // Collect all unique exam titles
    QVariantList matieres = bulletinData["matieres"].toList();
    QStringList titres;
    for (const auto& matV : matieres) {
        auto mat = matV.toMap();
        for (const auto& epV : mat["epreuves"].toList()) {
            QString titre = epV.toMap().value("titre").toString();
            if (!titre.isEmpty() && !titres.contains(titre))
                titres.append(titre);
        }
    }

    // Build CSV
    QStringList lines;
    // Header row
    QStringList header;
    header << "Élève" << "Année" << "Niveau" << "Classe" << "Matière";
    for (const auto& t : titres) header << t;
    header << "Moyenne" << "Présences" << "Séances totales";
    lines.append(header.join(";"));

    double moyGenSum = 0.0; int moyGenCount = 0;
    for (const auto& matV : matieres) {
        auto mat = matV.toMap();
        QString matNom = mat.value("nom", QStringLiteral("Matière #%1").arg(mat["matiereId"].toInt())).toString();

        // Build note map by titre
        QMap<QString, double> noteMap;
        for (const auto& epV : mat["epreuves"].toList()) {
            auto ep = epV.toMap();
            if (ep.value("hasNote").toBool())
                noteMap[ep["titre"].toString()] = ep["note"].toDouble();
        }

        double moy = mat.contains("moyenne") && !mat["moyenne"].isNull() ? mat["moyenne"].toDouble() : -1.0;
        int pres  = mat.value("presenceCount", 0).toInt();
        int total = mat.value("totalSeances", 0).toInt();

        QStringList row;
        row << studentName << anneeScolaire << niveauNom << classeNom << matNom;
        for (const auto& t : titres)
            row << (noteMap.contains(t) ? QString::number(noteMap[t], 'f', 1) : "");
        row << (moy >= 0 ? QString::number(moy, 'f', 2) : "");
        row << QString::number(pres) << QString::number(total);
        lines.append(row.join(";"));

        if (moy >= 0) { moyGenSum += moy; moyGenCount++; }
    }

    // Summary row
    if (moyGenCount > 0) {
        int totalPres = bulletinData.value("presenceTotale", 0).toInt();
        int totalSean = bulletinData.value("seancesTotales", 0).toInt();
        QStringList sumRow;
        sumRow << studentName << anneeScolaire << niveauNom << classeNom << "MOYENNE GÉNÉRALE";
        for (int i = 0; i < titres.size(); i++) sumRow << "";
        sumRow << QString::number(moyGenSum / moyGenCount, 'f', 2);
        sumRow << QString::number(totalPres) << QString::number(totalSean);
        lines.append(sumRow.join(";"));
    }

    // Write file
    QString filePath;
    if (!targetPath.isEmpty()) {
        filePath = targetPath;
    } else {
        QString docsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        QString safeYear = anneeScolaire;
        safeYear.replace('/', '-').replace('\\', '-');
        safeYear.remove(QRegularExpression(QStringLiteral("[^\\w\\s.-]")));
        safeYear = safeYear.simplified().replace(' ', '_');
        QString safeName = studentName;
        safeName.remove(QRegularExpression(QStringLiteral("[^\\w\\s-]")));
        safeName = safeName.simplified().replace(' ', '_');
        if (safeName.isEmpty()) safeName = QStringLiteral("eleve");
        filePath = QStringLiteral("%1/bulletin_%2_%3.csv").arg(docsPath, safeYear, safeName);
    }

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return QString();
    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << lines.join("\n");
    file.close();
    return filePath;
}

void GradesController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Grades.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Grades.loadGradesBySeance" || queryId == "Grades.loadGradesByStudent") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_grades = result.toList(); emit gradesChanged(); }
        setLoading(false);
    }
    else if (queryId == "Grades.saveGrade") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Note enregistrée");
    }
    else if (queryId == "Grades.saveGrades") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit operationSucceeded("Notes enregistrées");
    }
    else if (queryId == "Grades.loadClassAverage") {
        if (isError) { m_errorMessage = map["error"].toString(); emit errorMessageChanged(); }
        else { m_classAverage = map["average"].toDouble(); emit classAverageChanged(); }
    }
    else if (queryId == "Grades.loadBulletinData") {
        if (isError) emit operationFailed(map["error"].toString());
        else emit bulletinDataLoaded(result.toMap());
    }
}

void GradesController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Grades.")) return;

    if (queryId.startsWith("Grades.load")) {
        m_errorMessage = error; emit errorMessageChanged();
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
