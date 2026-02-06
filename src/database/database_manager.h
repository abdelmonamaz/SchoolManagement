#ifndef DATABASE_MANAGER_H
#define DATABASE_MANAGER_H

#include <QString>

class QSqlDatabase;

/**
 * @brief Static utility class responsible for SQLite database initialization and schema creation.
 *
 * DatabaseManager handles opening the SQLite connection, creating all required tables,
 * and seeding initial reference data. It is designed to be called from any thread
 * provided the correct connection name is used.
 */
class DatabaseManager
{
public:
    DatabaseManager() = delete;

    /**
     * @brief Opens (or reuses) a named SQLite connection.
     * @param dbPath   Filesystem path to the .sqlite file.
     * @param connectionName  Logical name for QSqlDatabase::addDatabase().
     * @return true if the connection was opened successfully.
     */
    static bool initialize(const QString& dbPath, const QString& connectionName);

    /**
     * @brief Creates the full schema on the given connection (idempotent).
     * @param connectionName  Must match a previously initialized connection.
     */
    static void createSchema(const QString& connectionName);

private:
    /** Creates every application table (IF NOT EXISTS). */
    static void createTables(QSqlDatabase& db);

    /** Inserts default reference rows (niveaux, salles, classes). */
    static void seedInitialData(QSqlDatabase& db);
};

#endif // DATABASE_MANAGER_H
