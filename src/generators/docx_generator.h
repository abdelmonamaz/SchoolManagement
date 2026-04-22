#pragma once

#include <QString>
#include <QList>

namespace Docx {

struct Matiere {
    QString mat;        // nom de la matière  → {{MAT}} / {{MAT_2}}
    QString coef;       // coefficient        → {{COEF}} / {{COEF_2}}
    QString n;          // numéro de ligne    → {{N}}

    // S1 — examen unique (isDual = false)
    QString note;       // → {{NOTE}}

    // S1 — double examen (isDual = true)
    bool    isDual  = false;
    QString exam1;      // → {{exam_1}}
    QString exam2;      // → {{exam_2}}
    QString note1;      // → {{NOTE_1}}
    QString note2;      // → {{NOTE_2}}
    QString noteMoy;    // → {{NOTE_MOY}}

    // S2 — examen unique
    QString noteS2;     // → {{NOTE_S2}}

    // S2 — double examen
    QString note1S2;    // → {{NOTE_1S2}}
    QString note2S2;    // → {{NOTE_2S2}}
    QString noteMoyS2;  // → {{NOTE_MOYS2}}
};

struct BulletinData {
    QString nom;       // {{NOM}}
    QString prenom;    // {{PRENOM}}
    QString niveau;    // {{NIVEAU}}
    QString moyenne;   // {{MOY}}   — moyenne S1
    QString ordre;     // {{ORD}}
    QString notif;     // {{NOTIF}}
    QString president; // {{PRES}}
    QString date;      // "DD/MM/YYYY" → {{DD}} {{MM}} {{YYYY}}
    QString annee;     // "YYYY1-YYYY2" → {{YYYY1}} {{YYYY2}}
    bool    estFeminin = false; // {{s}} → "ة" si féminin, "" sinon

    // S2 / annuel (ignorés si absents du template)
    QString moyS2;     // {{MOY_S2}}
    QString moyTot;    // {{MOY_TOT}}

    QList<Matiere> matieres;
};

} // namespace Docx

class DocxGenerator {
public:
    bool generate(const QString &templatePath,
                  const QString &outputPath,
                  const Docx::BulletinData &data,
                  QString *error = nullptr);

private:
    bool expandMatiereRows(QString &xml, const QList<Docx::Matiere> &matieres, QString *error);
};
