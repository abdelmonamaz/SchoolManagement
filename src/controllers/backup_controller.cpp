#include "controllers/backup_controller.h"

#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>
#include <QUrl>

#include <QtZlib/zlib.h>

static const char* kAutoBackupPath     = "backup/autoBackupPath";
static const char* kAutoBackupEnabled  = "backup/autoBackupEnabled";
static const char* kAutoBackupInterval = "backup/autoBackupInterval";
static const char* kLastAutoBackup     = "backup/lastAutoBackupDate";
static const char* kPendingRestore     = "backup/pendingRestorePath";

// How often the timer fires to check if a backup is due (every hour)
static constexpr int kCheckIntervalMs = 60 * 60 * 1000;

// Helper: accept both a local path and a file:// URL
static QString toLocalPath(const QString& raw) {
    if (raw.startsWith(QStringLiteral("file:")))
        return QUrl(raw).toLocalFile();
    return raw;
}

// ── ZIP helpers ───────────────────────────────────────────────────────────────

// Write srcPath as a single-entry ZIP archive at zipPath.
// entryName = filename stored inside the ZIP (e.g. "gestion_scolaire.db")
static bool writeZipFile(const QString& zipPath,
                         const QString& srcPath,
                         const QString& entryName)
{
    QFile src(srcPath);
    if (!src.open(QIODevice::ReadOnly)) return false;
    const QByteArray raw = src.readAll();
    src.close();

    const uLong rawLen = static_cast<uLong>(raw.size());
    const uLong crcVal = crc32(0L, reinterpret_cast<const Bytef*>(raw.constData()), rawLen);

    // Raw DEFLATE (no zlib wrapper) — ZIP compression method 8
    z_stream zs{};
    deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
    QByteArray compressed(static_cast<int>(deflateBound(&zs, rawLen)), '\0');
    zs.avail_in  = rawLen;
    zs.next_in   = reinterpret_cast<Bytef*>(const_cast<char*>(raw.constData()));
    zs.avail_out = static_cast<uInt>(compressed.size());
    zs.next_out  = reinterpret_cast<Bytef*>(compressed.data());
    const int ret = deflate(&zs, Z_FINISH);
    deflateEnd(&zs);
    if (ret != Z_STREAM_END) return false;
    compressed.resize(static_cast<int>(zs.total_out));

    const QByteArray nameBytes = entryName.toUtf8();
    const quint16    nameLen   = static_cast<quint16>(nameBytes.size());

    // DOS time / date
    const QDateTime now = QDateTime::currentDateTime();
    const quint16 dosTime = static_cast<quint16>(
        (now.time().hour() << 11) | (now.time().minute() << 5) | (now.time().second() / 2));
    const quint16 dosDate = static_cast<quint16>(
        ((now.date().year() - 1980) << 9) | (now.date().month() << 5) | now.date().day());

    // Local file header
    QByteArray localHdr;
    {
        QDataStream ds(&localHdr, QIODevice::WriteOnly);
        ds.setByteOrder(QDataStream::LittleEndian);
        ds << quint32(0x04034b50) << quint16(20) << quint16(0) << quint16(8)
           << dosTime << dosDate
           << quint32(crcVal) << quint32(compressed.size()) << quint32(rawLen)
           << nameLen << quint16(0);
    }
    localHdr.append(nameBytes);

    const quint32 centralDirOffset = static_cast<quint32>(localHdr.size() + compressed.size());

    // Central directory entry
    QByteArray centralEntry;
    {
        QDataStream ds(&centralEntry, QIODevice::WriteOnly);
        ds.setByteOrder(QDataStream::LittleEndian);
        ds << quint32(0x02014b50) << quint16(20) << quint16(20) << quint16(0) << quint16(8)
           << dosTime << dosDate
           << quint32(crcVal) << quint32(compressed.size()) << quint32(rawLen)
           << nameLen << quint16(0) << quint16(0) << quint16(0) << quint16(0)
           << quint32(0)    // external file attributes
           << quint32(0);   // relative offset of local header
    }
    centralEntry.append(nameBytes);

    // End of central directory
    QByteArray eocd;
    {
        QDataStream ds(&eocd, QIODevice::WriteOnly);
        ds.setByteOrder(QDataStream::LittleEndian);
        ds << quint32(0x06054b50) << quint16(0) << quint16(0)
           << quint16(1) << quint16(1)
           << quint32(centralEntry.size()) << centralDirOffset
           << quint16(0);
    }

    QFile out(zipPath);
    if (!out.open(QIODevice::WriteOnly)) return false;
    out.write(localHdr);
    out.write(compressed);
    out.write(centralEntry);
    out.write(eocd);
    out.close();
    return true;
}

// Extract the first entry from a ZIP file and return the raw bytes.
// Supports method 0 (stored) and method 8 (deflated).
static QByteArray readFirstZipEntry(const QString& zipPath)
{
    QFile f(zipPath);
    if (!f.open(QIODevice::ReadOnly)) return {};
    const QByteArray data = f.readAll();
    f.close();

    if (data.size() < 30) return {};

    QDataStream ds(data);
    ds.setByteOrder(QDataStream::LittleEndian);

    quint32 sig;
    ds >> sig;
    if (sig != 0x04034b50) return {};   // not a ZIP local file header

    quint16 versionNeeded, flags, method, modTime, modDate;
    quint32 crc, compSize, uncompSize;
    quint16 nameLen, extraLen;
    ds >> versionNeeded >> flags >> method >> modTime >> modDate
       >> crc >> compSize >> uncompSize >> nameLen >> extraLen;

    const int headerSize = 30 + nameLen + extraLen;
    if (data.size() < headerSize + static_cast<int>(compSize)) return {};

    const char* compData = data.constData() + headerSize;

    if (method == 0) {
        return QByteArray(compData, static_cast<int>(compSize));
    }
    if (method == 8) {
        QByteArray out(static_cast<int>(uncompSize), '\0');
        z_stream zs{};
        inflateInit2(&zs, -15);     // raw inflate
        zs.avail_in  = compSize;
        zs.next_in   = reinterpret_cast<Bytef*>(const_cast<char*>(compData));
        zs.avail_out = uncompSize;
        zs.next_out  = reinterpret_cast<Bytef*>(out.data());
        const int ret = inflate(&zs, Z_FINISH);
        inflateEnd(&zs);
        if (ret != Z_STREAM_END) return {};
        return out;
    }
    return {};
}

// ── Constructor ───────────────────────────────────────────────────────────────

BackupController::BackupController(const QString& dbPath, QObject* parent)
    : QObject(parent), m_dbPath(dbPath)
{
    QSettings s;
    m_autoBackupPath     = s.value(kAutoBackupPath,     "").toString();
    m_autoBackupEnabled  = s.value(kAutoBackupEnabled,  false).toBool();
    m_autoBackupInterval = s.value(kAutoBackupInterval, 1).toInt();
    m_lastAutoBackupDate = s.value(kLastAutoBackup,     "").toString();

    connect(&m_timer, &QTimer::timeout, this, &BackupController::onTimerTick);
    rescheduleTimer();

    // Check immediately at startup in case the app was closed for a long time
    if (m_autoBackupEnabled) onTimerTick();
}

// ── Properties ───────────────────────────────────────────────────────────────

QString BackupController::autoBackupPath() const { return m_autoBackupPath; }
void BackupController::setAutoBackupPath(const QString& path) {
    QString local = toLocalPath(path);
    if (m_autoBackupPath == local) return;
    m_autoBackupPath = local;
    QSettings().setValue(kAutoBackupPath, local);
    emit autoBackupPathChanged();
}

bool BackupController::autoBackupEnabled() const { return m_autoBackupEnabled; }
void BackupController::setAutoBackupEnabled(bool enabled) {
    if (m_autoBackupEnabled == enabled) return;
    m_autoBackupEnabled = enabled;
    QSettings().setValue(kAutoBackupEnabled, enabled);
    emit autoBackupEnabledChanged();
    rescheduleTimer();
    if (enabled) onTimerTick();
}

int BackupController::autoBackupInterval() const { return m_autoBackupInterval; }
void BackupController::setAutoBackupInterval(int days) {
    if (days < 1) days = 1;
    if (m_autoBackupInterval == days) return;
    m_autoBackupInterval = days;
    QSettings().setValue(kAutoBackupInterval, days);
    emit autoBackupIntervalChanged();
    if (m_autoBackupEnabled) onTimerTick();
}

QString BackupController::lastAutoBackupDate() const { return m_lastAutoBackupDate; }

// ── Timer logic ───────────────────────────────────────────────────────────────

void BackupController::rescheduleTimer() {
    if (m_autoBackupEnabled) {
        m_timer.start(kCheckIntervalMs);
    } else {
        m_timer.stop();
    }
}

void BackupController::onTimerTick() {
    if (!m_autoBackupEnabled || m_autoBackupPath.isEmpty()) return;

    QDate today = QDate::currentDate();
    QDate lastBackup = m_lastAutoBackupDate.isEmpty()
                       ? QDate()
                       : QDate::fromString(m_lastAutoBackupDate, Qt::ISODate);

    bool due = !lastBackup.isValid()
               || lastBackup.daysTo(today) >= m_autoBackupInterval;
    if (!due) return;

    doAutoBackup();
}

bool BackupController::doAutoBackup() {
    if (m_autoBackupPath.isEmpty() || m_dbPath.isEmpty()) return false;

    // Filename: gestion_scolaire_YYYY-MM-DD.zip
    const QString dateStr   = QDate::currentDate().toString("yyyy-MM-dd");
    const QString fileName  = QString("gestion_scolaire_%1.zip").arg(dateStr);
    const QString dest      = QDir(m_autoBackupPath).filePath(fileName);
    const QString entryName = QString("gestion_scolaire_%1.db").arg(dateStr);

    QFile existing(dest);
    if (existing.exists()) existing.remove();

    if (!writeZipFile(dest, m_dbPath, entryName)) {
        emit backupError(tr("Sauvegarde automatique impossible : %1").arg(dest));
        return false;
    }

    m_lastAutoBackupDate = dateStr;
    QSettings().setValue(kLastAutoBackup, dateStr);
    emit lastAutoBackupDateChanged();
    emit backupSuccess(dest);
    return true;
}

// ── Manual backup ─────────────────────────────────────────────────────────────

bool BackupController::copyDatabaseTo(const QString& destPath) {
    QString local = toLocalPath(destPath);
    if (m_dbPath.isEmpty() || local.isEmpty()) {
        emit backupError(tr("Chemin de destination invalide."));
        return false;
    }

    // Ensure .zip extension
    if (!local.endsWith(".zip", Qt::CaseInsensitive))
        local += ".zip";

    QFile existing(local);
    if (existing.exists()) existing.remove();

    const QString entryName = QFileInfo(local).baseName() + ".db";
    if (!writeZipFile(local, m_dbPath, entryName)) {
        emit backupError(tr("Impossible de créer la sauvegarde : %1").arg(local));
        return false;
    }
    emit backupSuccess(local);
    return true;
}

// ── Restore ───────────────────────────────────────────────────────────────────

bool BackupController::loadDatabase(const QString& srcPath) {
    const QString local = toLocalPath(srcPath);
    if (local.isEmpty()) {
        emit restoreError(tr("Aucun fichier sélectionné."));
        return false;
    }
    if (!QFile::exists(local)) {
        emit restoreError(tr("Le fichier sélectionné n'existe pas : %1").arg(local));
        return false;
    }

    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString staging = dataDir + "/pending_restore.db";
    QFile::remove(staging);

    if (local.endsWith(".zip", Qt::CaseInsensitive)) {
        const QByteArray dbData = readFirstZipEntry(local);
        if (dbData.isEmpty()) {
            emit restoreError(tr("Impossible d'extraire la base de données depuis : %1").arg(local));
            return false;
        }
        QFile out(staging);
        if (!out.open(QIODevice::WriteOnly) || out.write(dbData) != dbData.size()) {
            emit restoreError(tr("Impossible de préparer la restauration depuis : %1").arg(local));
            return false;
        }
        out.close();
    } else {
        // Legacy: plain .db file
        if (!QFile::copy(local, staging)) {
            emit restoreError(tr("Impossible de préparer la restauration depuis : %1").arg(local));
            return false;
        }
    }

    QSettings().setValue(kPendingRestore, staging);
    emit restoreReady();
    return true;
}

// ── Startup helper ────────────────────────────────────────────────────────────

void BackupController_applyPendingRestore(const QString& dbPath) {
    QSettings s;
    const QString pending = s.value(kPendingRestore, "").toString();
    if (pending.isEmpty() || !QFile::exists(pending)) return;

    s.remove(kPendingRestore);
    QFile::remove(dbPath);
    QFile::copy(pending, dbPath);
    QFile::remove(pending);
}
