#include "generators/docx_generator.h"

#include <QFile>
#include <QDebug>
#include <QtZlib/zlib.h>

// ============================================================
// Minimal ZIP reader / writer (format PKZIP, little-endian)
// ============================================================
namespace Zip {

static quint16 u16(const uchar *p) {
    return quint16(p[0]) | (quint16(p[1]) << 8);
}
static quint32 u32(const uchar *p) {
    return quint32(p[0]) | (quint32(p[1]) << 8)
         | (quint32(p[2]) << 16) | (quint32(p[3]) << 24);
}
static void w16(uchar *p, quint16 v) { p[0] = v & 0xFF; p[1] = (v >> 8) & 0xFF; }
static void w32(uchar *p, quint32 v) {
    p[0] = v & 0xFF; p[1] = (v >> 8) & 0xFF;
    p[2] = (v >> 16) & 0xFF; p[3] = (v >> 24) & 0xFF;
}

struct Entry {
    QString    name;
    quint16    compression = 0; // 0 = stored, 8 = deflated
    quint32    crc         = 0;
    quint32    uncompSize  = 0;
    QByteArray compData;
    quint32    localOffset = 0; // filled during write
};

// Raw inflate (ZIP stores raw DEFLATE without zlib wrapper → windowBits = -15)
static QByteArray rawInflate(const QByteArray &src, quint32 destSize)
{
    QByteArray dst(int(destSize), '\0');
    z_stream z{};
    z.next_in   = reinterpret_cast<Bytef *>(const_cast<char *>(src.constData()));
    z.avail_in  = uInt(src.size());
    z.next_out  = reinterpret_cast<Bytef *>(dst.data());
    z.avail_out = uInt(dst.size());
    if (inflateInit2(&z, -15) != Z_OK) return {};
    int r = inflate(&z, Z_FINISH);
    inflateEnd(&z);
    return (r == Z_STREAM_END) ? dst : QByteArray{};
}

// Raw deflate (no zlib wrapper → windowBits = -15)
static QByteArray rawDeflate(const QByteArray &src)
{
    QByteArray dst(int(compressBound(uLong(src.size())) + 64), '\0');
    z_stream z{};
    z.next_in   = reinterpret_cast<Bytef *>(const_cast<char *>(src.constData()));
    z.avail_in  = uInt(src.size());
    z.next_out  = reinterpret_cast<Bytef *>(dst.data());
    z.avail_out = uInt(dst.size());
    if (deflateInit2(&z, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                     -15, 8, Z_DEFAULT_STRATEGY) != Z_OK)
        return {};
    int r = deflate(&z, Z_FINISH);
    deflateEnd(&z);
    if (r != Z_STREAM_END) return {};
    dst.resize(int(z.total_out));
    return dst;
}

// Parse all local-file entries from a ZIP archive
static QList<Entry> read(const QString &path, QString *err)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        if (err) *err = QStringLiteral("Impossible d'ouvrir : ") + path;
        return {};
    }
    const QByteArray raw = f.readAll();
    f.close();

    const auto *d  = reinterpret_cast<const uchar *>(raw.constData());
    const int   sz = raw.size();
    int pos = 0;
    QList<Entry> entries;

    while (pos + 30 <= sz) {
        const quint32 sig = u32(d + pos);
        if (sig == 0x02014b50u || sig == 0x06054b50u) break; // central dir / EOCD

        if (sig != 0x04034b50u) { ++pos; continue; } // skip non-local-header bytes

        const quint16 flags    = u16(d + pos +  6);
        const quint16 comp     = u16(d + pos +  8);
        const quint32 crc      = u32(d + pos + 14);
        const quint32 cmpSz    = u32(d + pos + 18);
        const quint32 uncmpSz  = u32(d + pos + 22);
        const quint16 nameLen  = u16(d + pos + 26);
        const quint16 extraLen = u16(d + pos + 28);

        const int dataStart = pos + 30 + nameLen + extraLen;
        if (dataStart + int(cmpSz) > sz) break;

        Entry e;
        e.name        = QString::fromUtf8(reinterpret_cast<const char *>(d + pos + 30), nameLen);
        e.compression = comp;
        e.crc         = crc;
        e.uncompSize  = uncmpSz;
        e.compData    = QByteArray(reinterpret_cast<const char *>(d + dataStart), int(cmpSz));

        entries.append(e);
        pos = dataStart + int(cmpSz);

        if (flags & 0x08) { // skip optional data descriptor
            if (pos + 4 <= sz && u32(d + pos) == 0x08074b50u) pos += 4;
            pos += 12;
        }
    }
    return entries;
}

// Get decompressed content of a named entry
static QByteArray getData(const QList<Entry> &entries, const QString &name)
{
    for (const Entry &e : entries) {
        if (e.name != name) continue;
        if (e.compression == 0) return e.compData;
        if (e.compression == 8) return rawInflate(e.compData, e.uncompSize);
    }
    return {};
}

// Write all entries to a new ZIP archive
static bool write(const QString &path, QList<Entry> &entries, QString *err)
{
    QByteArray buf;
    buf.reserve(1 << 20);

    // ── Local file records ──────────────────────────────────────────────
    for (Entry &e : entries) {
        e.localOffset = quint32(buf.size());
        const QByteArray name = e.name.toUtf8();
        uchar lh[30];
        w32(lh,      0x04034b50u);
        w16(lh +  4, 20);                       // version needed
        w16(lh +  6,  0);                       // flags
        w16(lh +  8, e.compression);
        w16(lh + 10,  0);  w16(lh + 12,  0);   // mod time / date
        w32(lh + 14, e.crc);
        w32(lh + 18, quint32(e.compData.size()));
        w32(lh + 22, e.uncompSize);
        w16(lh + 26, quint16(name.size()));
        w16(lh + 28,  0);                       // extra length
        buf.append(reinterpret_cast<const char *>(lh), 30);
        buf.append(name);
        buf.append(e.compData);
    }

    // ── Central directory ───────────────────────────────────────────────
    const quint32 cdOffset = quint32(buf.size());
    for (const Entry &e : entries) {
        const QByteArray name = e.name.toUtf8();
        uchar cd[46];
        w32(cd,      0x02014b50u);
        w16(cd +  4, 20);  w16(cd +  6, 20);   // version made by / needed
        w16(cd +  8,  0);                       // flags
        w16(cd + 10, e.compression);
        w16(cd + 12,  0);  w16(cd + 14,  0);   // mod time / date
        w32(cd + 16, e.crc);
        w32(cd + 20, quint32(e.compData.size()));
        w32(cd + 24, e.uncompSize);
        w16(cd + 28, quint16(name.size()));
        w16(cd + 30,  0);  w16(cd + 32,  0);   // extra / comment length
        w16(cd + 34,  0);  w16(cd + 36,  0);   // disk start / internal attrs
        w32(cd + 38,  0);                       // external attrs
        w32(cd + 42, e.localOffset);
        buf.append(reinterpret_cast<const char *>(cd), 46);
        buf.append(name);
    }

    // ── End of central directory record ────────────────────────────────
    const quint32 cdSize = quint32(buf.size()) - cdOffset;
    uchar eocd[22];
    w32(eocd,      0x06054b50u);
    w16(eocd +  4,  0);  w16(eocd +  6,  0);
    w16(eocd +  8, quint16(entries.size()));
    w16(eocd + 10, quint16(entries.size()));
    w32(eocd + 12, cdSize);
    w32(eocd + 16, cdOffset);
    w16(eocd + 20,  0);
    buf.append(reinterpret_cast<const char *>(eocd), 22);

    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (err) *err = QStringLiteral("Impossible de créer : ") + path;
        return false;
    }
    f.write(buf);
    return true;
}

} // namespace Zip

// ============================================================
// helpers
// ============================================================

static QString escape(const QString &s) { return s.toHtmlEscaped(); }

// Quand Word génère le XML, il peut fragmenter un placeholder entre plusieurs
// balises <w:r><w:t>. Par exemple, {{NOTE}} peut apparaître comme :
//   <w:t>{{</w:t></w:r><w:r><w:t>NOTE</w:t></w:r><w:r><w:t>}}</w:t>
// Cette fonction reconstruit les placeholders en supprimant les balises XML
// intercalées entre {{ et }}.
static QString fixSplitPlaceholders(const QString &xml)
{
    // ── Phase 1 : réunir {{ coupé entre deux <w:t> ───────────────────────
    // Word peut produire : <w:t>…{</w:t>…<w:t>{NOM}}</w:t>
    // On déplace le { solitaire dans le <w:t> suivant pour obtenir {{NOM}}.
    QString work = xml;
    {
        int i = 0;
        while (i < work.size()) {
            // Cherche un { juste avant </w:t>
            const int pos = work.indexOf(QStringLiteral("{</w:t>"), i);
            if (pos < 0) break;

            // Ne pas traiter {{ déjà correct (char précédent = '{')
            if (pos > 0 && work[pos - 1] == QLatin1Char('{')) { i = pos + 1; continue; }

            // Limiter la recherche au même paragraphe
            const int paraEnd = work.indexOf(QStringLiteral("</w:p>"), pos);

            // Trouver le prochain <w:t…> dans ce paragraphe
            int searchFrom = pos + 7; // après "{</w:t>"
            int gtPos = -1;
            while (searchFrom < work.size()) {
                const int wt = work.indexOf(QStringLiteral("<w:t"), searchFrom);
                if (wt < 0 || (paraEnd >= 0 && wt > paraEnd)) break;
                const QChar c = (wt + 4 < work.size()) ? work[wt + 4] : QChar();
                if (c == QLatin1Char('>') || c == QLatin1Char(' ')) {
                    const int gt = work.indexOf(QLatin1Char('>'), wt + 4);
                    if (gt >= 0) { gtPos = gt; break; }
                }
                searchFrom = wt + 1;
            }

            // Si le premier caractère du <w:t> suivant est '{' → c'est un {{ coupé
            if (gtPos >= 0 && gtPos + 1 < work.size()
                && work[gtPos + 1] == QLatin1Char('{')) {
                // Insérer d'abord (index > pos) puis supprimer
                work.insert(gtPos + 1, QLatin1Char('{'));
                work.remove(pos, 1);
                i = pos; // rescanner depuis ici
            } else {
                i = pos + 1;
            }
        }
    }

    // ── Phase 2 : reconstituer {{…}} coupé à l'intérieur ─────────────────
    // Ex : <w:t>{{NO</w:t>…<w:t>TE}}</w:t>  →  {{NOTE}}
    QString result;
    result.reserve(work.size());
    int i = 0;

    while (i < work.size()) {
        const int openPos = work.indexOf(QStringLiteral("{{"), i);
        if (openPos < 0) { result += work.mid(i); break; }

        result += work.mid(i, openPos - i);

        int j = openPos + 2;
        QString inner;
        bool closed = false;

        while (j < work.size()) {
            if (work[j] == QLatin1Char('<')) {
                const int end = work.indexOf(QLatin1Char('>'), j);
                if (end < 0) { j = work.size(); break; }
                j = end + 1;
            } else if (work[j] == QLatin1Char('}')
                       && j + 1 < work.size()
                       && work[j + 1] == QLatin1Char('}')) {
                result += QStringLiteral("{{") + inner.trimmed() + QStringLiteral("}}");
                j += 2;
                closed = true;
                break;
            } else {
                inner += work[j++];
            }
        }

        if (!closed) result += QStringLiteral("{{") + inner;
        i = j;
    }

    return result;
}

// Trouve le <w:tr>…</w:tr> (niveau le plus haut) contenant `needle`.
// Note : on utilise {{NOTE}} comme ancre car il est directement dans le <w:tc>
// extérieur, alors que {{MAT}} est dans un <w:tr> imbriqué.
static QString extractTr(const QString &xml, const QString &anchor, int *pos, int *len)
{
    const int ni = xml.indexOf(anchor);
    if (ni < 0) return {};

    // Cherche le <w:tr (espace ou >) qui précède immédiatement l'ancre
    int trStart = -1;
    for (int k = ni - 1; k >= 0; --k) {
        if (xml[k] != QLatin1Char('<')) continue;
        if (QStringView(xml).mid(k, 5) == QStringView(u"<w:tr")) {
            QChar c = (k + 5 < xml.size()) ? xml[k + 5] : QChar();
            if (c == QLatin1Char(' ') || c == QLatin1Char('>')) { trStart = k; break; }
        }
    }
    if (trStart < 0) return {};

    // Compte les imbrications pour trouver le </w:tr> correspondant
    int depth = 0;
    for (int i = trStart; i < xml.size(); ) {
        if (QStringView(xml).mid(i, 5) == QStringView(u"<w:tr")) {
            QChar c = (i + 5 < xml.size()) ? xml[i + 5] : QChar();
            if (c == QLatin1Char(' ') || c == QLatin1Char('>')) { ++depth; }
        }
        if (QStringView(xml).mid(i, 7) == QStringView(u"</w:tr>")) {
            if (--depth == 0) {
                *pos = trStart;
                *len = i + 7 - trStart;
                return xml.mid(trStart, *len);
            }
        }
        ++i;
    }
    return {};
}

// Extrait le <w:tr>…</w:tr> qui commence exactement à la position trStart.
static QString extractTrAt(const QString &xml, int trStart, int *len)
{
    int depth = 0;
    for (int i = trStart; i < xml.size(); ) {
        if (QStringView(xml).mid(i, 5) == QStringView(u"<w:tr")) {
            QChar c = (i + 5 < xml.size()) ? xml[i + 5] : QChar();
            if (c == QLatin1Char(' ') || c == QLatin1Char('>')) { ++depth; }
        }
        if (QStringView(xml).mid(i, 7) == QStringView(u"</w:tr>")) {
            if (--depth == 0) {
                *len = i + 7 - trStart;
                return xml.mid(trStart, *len);
            }
        }
        ++i;
    }
    return {};
}

// ============================================================
// DocxGenerator::expandMatiereRows
// ============================================================

bool DocxGenerator::expandMatiereRows(QString &xml,
                                       const QList<Docx::Matiere> &matieres,
                                       QString *error)
{
    // Séparer les matières en deux groupes
    QList<Docx::Matiere> singles, duals;
    for (const Docx::Matiere &m : matieres) {
        if (m.isDual) duals.append(m);
        else          singles.append(m);
    }

    // ── Ligne modèle examen unique (ancre : {{NOTE}}) ────────────────────
    {
        int pos = 0, len = 0;
        // {{NOTE}} seul (pas {{NOTE_1}}/{{NOTE_2}}/{{NOTE_MOY}})
        // extractTr trouve le premier {{NOTE}} ; s'il y a aussi {{NOTE_MOY}}
        // dans le même fichier c'est dans une autre ligne, donc indexOf("{{NOTE}}")
        // trouvera bien la ligne "examen unique" puisqu'on suppose que cette
        // ligne ne contient PAS {{NOTE_MOY}}.
        const QString rowTpl = extractTr(xml, QStringLiteral("{{NOTE}}"), &pos, &len);

        if (!singles.isEmpty()) {
            if (rowTpl.isEmpty() || !rowTpl.contains(QStringLiteral("{{MAT}}"))) {
                if (error) *error = QStringLiteral(
                    "Ligne modèle (examen unique) introuvable — "
                    "vérifiez que {{NOTE}} et {{MAT}} sont dans le même <w:tr>");
                return false;
            }
            QString expanded;
            expanded.reserve(rowTpl.size() * singles.size());
            for (const Docx::Matiere &m : singles) {
                QString row = rowTpl;
                row.replace(QStringLiteral("{{MAT}}"),      escape(m.mat));
                row.replace(QStringLiteral("{{NOTE}}"),     escape(m.note));
                row.replace(QStringLiteral("{{COEF}}"),     escape(m.coef));
                row.replace(QStringLiteral("{{N}}"),        escape(m.n));
                row.replace(QStringLiteral("{{NOTE_S2}}"),  escape(m.noteS2));
                expanded += row;
            }
            xml.replace(pos, len, expanded);
        } else if (!rowTpl.isEmpty()) {
            // Pas de matière à examen unique → supprimer la ligne modèle
            xml.replace(pos, len, QString());
        }
    }

    // ── Bloc modèle double examen (ancre : {{NOTE_MOY}}) ────────────────
    // Le template Word crée 2 <w:tr> consécutifs pour les cellules fusionnées :
    //   Ligne A : {{NOTE_MOY}}, {{NOTE_1}}, {{exam_1}}, {{MAT_2}}, {{COEF_2}}, {{N2}}
    //   Ligne B : {{NOTE_2}}, {{exam_2}}  (continuation de fusion verticale)
    {
        // Ligne A
        int posA = 0, lenA = 0;
        const QString rowA = extractTr(xml, QStringLiteral("{{NOTE_MOY}}"), &posA, &lenA);

        // Ligne B : <w:tr> qui suit immédiatement la ligne A
        int posB = posA + lenA;
        while (posB < xml.size() && xml[posB].isSpace()) ++posB;
        int lenB = 0;
        QString rowB;
        if (posB + 5 <= xml.size()) {
            QStringView sv = QStringView(xml).mid(posB, 5);
            QChar      c   = (posB + 5 < xml.size()) ? xml[posB + 5] : QChar();
            if (sv == QStringView(u"<w:tr")
                && (c == QLatin1Char(' ') || c == QLatin1Char('>'))) {
                rowB = extractTrAt(xml, posB, &lenB);
            }
        }

        // Région totale à remplacer dans le XML (A + éventuel espace + B)
        const int totalLen = rowB.isEmpty() ? lenA : (posB + lenB - posA);

        if (!duals.isEmpty()) {
            if (rowA.isEmpty() || !rowA.contains(QStringLiteral("{{MAT_2}}"))) {
                if (error) *error = QStringLiteral(
                    "Bloc modèle (double examen) introuvable — "
                    "vérifiez que {{NOTE_MOY}} et {{MAT_2}} sont présents");
                return false;
            }
            QString expanded;
            expanded.reserve((rowA.size() + rowB.size()) * duals.size());
            for (const Docx::Matiere &m : duals) {
                // Substitutions dans la ligne A
                QString ra = rowA;
                ra.replace(QStringLiteral("{{MAT_2}}"),      escape(m.mat));
                ra.replace(QStringLiteral("{{COEF_2}}"),     escape(m.coef));
                ra.replace(QStringLiteral("{{N2}}"),         escape(m.n));
                ra.replace(QStringLiteral("{{N}}"),          escape(m.n));
                ra.replace(QStringLiteral("{{NOTE_1}}"),     escape(m.note1));
                ra.replace(QStringLiteral("{{NOTE_MOY}}"),   escape(m.noteMoy));
                ra.replace(QStringLiteral("{{exam_1}}"),     escape(m.exam1));
                ra.replace(QStringLiteral("{{NOTE_1S2}}"),   escape(m.note1S2));
                ra.replace(QStringLiteral("{{NOTE_MOYS2}}"), escape(m.noteMoyS2));
                expanded += ra;

                // Substitutions dans la ligne B (si elle existe)
                if (!rowB.isEmpty()) {
                    QString rb = rowB;
                    rb.replace(QStringLiteral("{{NOTE_2}}"),  escape(m.note2));
                    rb.replace(QStringLiteral("{{exam_2}}"),  escape(m.exam2));
                    rb.replace(QStringLiteral("{{NOTE_2S2}}"), escape(m.note2S2));
                    expanded += rb;
                }
            }
            xml.replace(posA, totalLen, expanded);
        } else if (!rowA.isEmpty()) {
            xml.replace(posA, totalLen, QString());
        }
    }

    return true;
}

// ============================================================
// DocxGenerator::generate
// ============================================================

bool DocxGenerator::generate(const QString &templatePath,
                               const QString &outputPath,
                               const Docx::BulletinData &data,
                               QString *error)
{
    // 1. Lire le ZIP
    QString zipErr;
    QList<Zip::Entry> entries = Zip::read(templatePath, &zipErr);
    if (entries.isEmpty()) {
        if (error) *error = zipErr.isEmpty()
            ? QStringLiteral("Template vide ou illisible : ") + templatePath
            : zipErr;
        return false;
    }

    // 2. Extraire word/document.xml
    const QByteArray xmlBytes =
        Zip::getData(entries, QStringLiteral("word/document.xml"));
    if (xmlBytes.isEmpty()) {
        if (error) *error = QStringLiteral("word/document.xml absent ou vide");
        return false;
    }
    QString xml = QString::fromUtf8(xmlBytes);

    // 3a. Reconstituer les placeholders fragmentés par Word
    xml = fixSplitPlaceholders(xml);

    // 3b. Expansion du tableau des matières
    if (!expandMatiereRows(xml, data.matieres, error))
        return false;

    // 4. Remplacement des scalaires (déjà normalisés par fixSplitPlaceholders)
    xml.replace(QStringLiteral("{{NOM}}"),    escape(data.nom));
    xml.replace(QStringLiteral("{{PRENOM}}"), escape(data.prenom));
    xml.replace(QStringLiteral("{{NIVEAU}}"), escape(data.niveau));
    xml.replace(QStringLiteral("{{MOY}}"),    escape(data.moyenne));
    xml.replace(QStringLiteral("{{ORD}}"),    escape(data.ordre));
    xml.replace(QStringLiteral("{{NOTIF}}"),  escape(data.notif));
    xml.replace(QStringLiteral("{{PRES}}"),   escape(data.president));

    // Date : "DD/MM/YYYY" → 3 tokens séparés dans le XML
    const QStringList dp = data.date.split(QLatin1Char('/'));
    if (dp.size() == 3) {
        xml.replace(QStringLiteral("{{DD}}"),   escape(dp[0]));
        xml.replace(QStringLiteral("{{MM}}"),   escape(dp[1]));
        xml.replace(QStringLiteral("{{YYYY}}"), escape(dp[2]));
    } else {
        qWarning() << "Format de date invalide (attendu DD/MM/YYYY) :" << data.date;
        xml.replace(QStringLiteral("{{DD}}"),   escape(data.date));
        xml.replace(QStringLiteral("{{MM}}"),   QString());
        xml.replace(QStringLiteral("{{YYYY}}"), QString());
    }

    // Année scolaire : "YYYY1-YYYY2" → {{YYYY1}} {{YYYY2}}
    const QStringList ay = data.annee.split(QLatin1Char('-'));
    if (ay.size() == 2) {
        xml.replace(QStringLiteral("{{YYYY1}}"), escape(ay[0]));
        xml.replace(QStringLiteral("{{YYYY2}}"), escape(ay[1]));
    } else {
        xml.replace(QStringLiteral("{{YYYY1}}"), escape(data.annee));
        xml.replace(QStringLiteral("{{YYYY2}}"), QString());
    }

    // Scalaires S2 / annuels (sans effet si absents du template S1)
    xml.replace(QStringLiteral("{{MOY_S2}}"),  escape(data.moyS2));
    xml.replace(QStringLiteral("{{MOY_TOT}}"), escape(data.moyTot));

    // Genre : {{s}} → "ة" (féminin) ou "" (masculin).
    // On fusionne ة dans le <w:t> PRÉCÉDENT pour éviter qu'elle hérite du
    // tagage LTR du run qui contenait {{s}} (les accolades sont ASCII → Word
    // les marque souvent LTR, ce qui déconnecte ة du mot précédent).
    {
        int pos;
        while ((pos = xml.indexOf(QStringLiteral("{{s}}"))) >= 0) {
            // </w:t> le plus proche avant {{s}}, dans le même <w:p>
            const int pStart  = xml.lastIndexOf(QStringLiteral("<w:p"), pos);
            const int closeWt = xml.lastIndexOf(QStringLiteral("</w:t>"), pos);

            if (closeWt > pStart && closeWt < pos) {
                // Supprimer l'espace de fin éventuel du <w:t> précédent
                int ins = closeWt;
                while (ins > 0 && xml[ins - 1] == QLatin1Char(' ')) --ins;

                // Injecter ة (ou rien) juste avant </w:t>
                const QString inject = data.estFeminin
                    ? QStringLiteral("ة</w:t>")
                    : QStringLiteral("</w:t>");
                xml.replace(ins, closeWt + 6 - ins, inject);

                // Supprimer {{s}} (position a pu bouger après replace)
                const int s = xml.indexOf(QStringLiteral("{{s}}"), ins);
                if (s >= 0) xml.remove(s, 5);
            } else {
                // Aucun <w:t> précédent dans ce paragraphe — remplacement direct
                xml.replace(pos, 5,
                    data.estFeminin ? QStringLiteral("ة") : QString());
            }
        }
    }

    // 5. Recompresser word/document.xml
    const QByteArray newXml = xml.toUtf8();
    const quint32 newCrc =
        quint32(crc32(0, reinterpret_cast<const Bytef *>(newXml.constData()),
                      uInt(newXml.size())));
    const QByteArray newComp = Zip::rawDeflate(newXml);
    if (newComp.isEmpty()) {
        if (error) *error = QStringLiteral("Échec compression de word/document.xml");
        return false;
    }

    // 6. Remplacer l'entrée dans la liste
    bool found = false;
    for (Zip::Entry &e : entries) {
        if (e.name == QLatin1String("word/document.xml")) {
            e.compression = 8;
            e.crc         = newCrc;
            e.uncompSize  = quint32(newXml.size());
            e.compData    = newComp;
            found = true;
            break;
        }
    }
    if (!found) {
        if (error) *error = QStringLiteral("Entrée word/document.xml introuvable dans le ZIP");
        return false;
    }

    // 7. Écrire le nouveau ZIP
    QFile::remove(outputPath);
    return Zip::write(outputPath, entries, error);
}
