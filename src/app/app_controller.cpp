#include "app/app_controller.h"

#include <QQmlContext>
#include <QStandardPaths>
#include <QDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QCoreApplication>
#include <QGuiApplication>

#include "database/database_worker.h"

#include <QEventLoop>

// Repositories
#include "repositories/sqlite/sqlite_salle_repository.h"
#include "repositories/sqlite/sqlite_niveau_repository.h"
#include "repositories/sqlite/sqlite_equipement_repository.h"
#include "repositories/sqlite/sqlite_personnel_repository.h"
#include "repositories/sqlite/sqlite_contrat_repository.h"
#include "repositories/sqlite/sqlite_eleve_repository.h"
#include "repositories/sqlite/sqlite_seance_repository.h"
#include "repositories/sqlite/sqlite_paiement_repository.h"
#include "repositories/sqlite/sqlite_finance_repository.h"
#include "repositories/sqlite/sqlite_setup_repository.h"
#include "repositories/sqlite/sqlite_year_closure_repository.h"
#include "repositories/sqlite/sqlite_paiement_personnel_repository.h"

// Services
#include "services/schooling_service.h"
#include "services/student_service.h"
#include "services/staff_service.h"
#include "services/attendance_service.h"
#include "services/grades_service.h"
#include "services/finance_service.h"
#include "services/dashboard_service.h"

// Controllers
#include "controllers/backup_controller.h"
#include "controllers/setup_controller.h"
#include "controllers/year_closure_controller.h"
#include "controllers/schooling_controller.h"
#include "controllers/student_controller.h"
#include "controllers/staff_controller.h"
#include "controllers/attendance_controller.h"
#include "controllers/exams_controller.h"
#include "controllers/grades_controller.h"
#include "controllers/finance_controller.h"
#include "controllers/dashboard_controller.h"

AppController::AppController(QQmlApplicationEngine& engine, QObject* parent)
    : QObject(parent)
    , m_engine(&engine)
{
    setupDatabase();
    createRepositories();
    createServices();
    createControllers();
    registerWithQml(engine);
    applyLanguage(getLanguage());
}

AppController::~AppController() {
    if (m_dbWorker) {
        m_dbWorker->stop();
    }
}

QString AppController::getLanguage() const {
    QString lang = "français";
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QString dbPath = dataDir + "/gestion_scolaire.db";

    if (QFile::exists(dbPath)) {
        // Create a distinct connection name for the main thread
        QString connName = QStringLiteral("MainThread_Init_Lang");
        {
            auto db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
            db.setDatabaseName(dbPath);
            if (db.open()) {
                QSqlQuery q(db);
                if (q.exec(QStringLiteral("SELECT langue FROM association_config LIMIT 1")) && q.next()) {
                    lang = q.value(0).toString();
                }
                db.close();
            }
        }
        QSqlDatabase::removeDatabase(connName);
    }
    return lang;
}

void AppController::applyLanguage(const QString& lang) {
    if (m_translator) {
        QCoreApplication::removeTranslator(m_translator);
        delete m_translator;
        m_translator = nullptr;
    }

    if (lang == "arabe") {
        m_translator = new QTranslator(this);
        const bool loaded =
            m_translator->load(QStringLiteral(":/i18n/ar_AE.qm")) ||
            m_translator->load(QStringLiteral(":/qt/qml/GestionScolaire/i18n/ar_AE.qm")) ||
            m_translator->load(QStringLiteral(":/GestionScolaire/i18n/ar_AE.qm")) ||
            m_translator->load(QStringLiteral("ar_AE"), QStringLiteral(":/i18n/"));
        if (loaded) {
            QCoreApplication::installTranslator(m_translator);
            qInfo() << "[AppController] Traduction arabe chargée.";
        } else {
            qWarning() << "[AppController] Impossible de charger ar_AE.qm";
            delete m_translator;
            m_translator = nullptr;
        }
    }

    if (auto* guiApp = qobject_cast<QGuiApplication*>(QCoreApplication::instance()))
        guiApp->setLayoutDirection(lang == "arabe" ? Qt::RightToLeft : Qt::LeftToRight);

    if (m_engine)
        m_engine->retranslate();
}

void AppController::setupDatabase() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    m_dbPath = dataDir + "/gestion_scolaire.db";

    // Apply any pending DB restore staged by BackupController::loadDatabase()
    // Must be done BEFORE any QSqlDatabase connection is opened.
    BackupController_applyPendingRestore(m_dbPath);

    m_dbWorker = std::make_unique<DatabaseWorker>(m_dbPath);

    // Capture any init error so QML can display it
    connect(m_dbWorker.get(), &DatabaseWorker::initError, this, [this](const QString& msg) {
        m_dbInitError = msg;
        emit dbInitErrorChanged();
    });

    // Wait synchronously for the worker thread to initialise the DB
    QEventLoop loop;
    connect(m_dbWorker.get(), &DatabaseWorker::ready, &loop, &QEventLoop::quit);
    m_dbWorker->start();
    loop.exec();
}

void AppController::createRepositories() {
    const auto conn = m_dbWorker->connectionName();

    m_salleRepo = std::make_unique<SqliteSalleRepository>(conn);
    m_niveauRepo = std::make_unique<SqliteNiveauRepository>(conn);
    m_classeRepo = std::make_unique<SqliteClasseRepository>(conn);
    m_matiereRepo = std::make_unique<SqliteMatiereRepository>(conn);
    m_matiereExamenRepo = std::make_unique<SqliteMatiereExamenRepository>(conn);
    m_typeExamenRepo = std::make_unique<SqliteTypeExamenRepository>(conn);
    m_equipementRepo = std::make_unique<SqliteEquipementRepository>(conn);
    m_profRepo = std::make_unique<SqlitePersonnelRepository>(conn);
    m_contratRepo = std::make_unique<SqliteContratRepository>(conn);
    m_eleveRepo = std::make_unique<SqliteEleveRepository>(conn);
    m_seanceRepo = std::make_unique<SqliteSeanceRepository>(conn);
    m_participationRepo = std::make_unique<SqliteParticipationRepository>(conn);
    m_paiementRepo = std::make_unique<SqlitePaiementRepository>(conn);
    m_projetRepo = std::make_unique<SqliteProjetRepository>(conn);
    m_donateurRepo = std::make_unique<SqliteDonateurRepository>(conn);
    m_donRepo = std::make_unique<SqliteDonRepository>(conn);
    m_paiementPersonnelRepo = std::make_unique<SqlitePaiementPersonnelRepository>(conn);
    m_tarifRepo = std::make_unique<SqliteTarifMensualiteRepository>(conn);
    m_depenseRepo = std::make_unique<SqliteDepenseRepository>(conn);
    m_balanceRepo         = std::make_unique<SqliteFinanceBalanceRepository>(conn);
    m_assocRepo           = std::make_unique<SqliteAssociationRepository>(conn);
    m_setupSchoolYearRepo = std::make_unique<SqliteSetupSchoolYearRepository>(conn);
    m_yearClosureRepo     = std::make_unique<SqliteYearClosureRepository>(conn);
}

void AppController::createServices() {
    m_schoolingService = std::make_unique<SchoolingService>(
        m_niveauRepo.get(), m_classeRepo.get(), m_matiereRepo.get(), m_matiereExamenRepo.get(),
        m_typeExamenRepo.get(), m_salleRepo.get(), m_equipementRepo.get());

    m_studentService = std::make_unique<StudentService>(
        m_eleveRepo.get(), m_classeRepo.get());

    m_staffService = std::make_unique<StaffService>(
        m_profRepo.get(), m_contratRepo.get(), m_seanceRepo.get());

    m_attendanceService = std::make_unique<AttendanceService>(
        m_seanceRepo.get(), m_participationRepo.get(), m_eleveRepo.get());

    m_gradesService = std::make_unique<GradesService>(
        m_participationRepo.get(), m_seanceRepo.get());

    m_financeService = std::make_unique<FinanceService>(
        m_paiementRepo.get(), m_projetRepo.get(), m_donateurRepo.get(), m_donRepo.get(),
        m_paiementPersonnelRepo.get(), m_tarifRepo.get(), m_depenseRepo.get(),
        m_balanceRepo.get());

    m_dashboardService = std::make_unique<DashboardService>(
        m_eleveRepo.get(), m_seanceRepo.get(), m_participationRepo.get(), m_matiereRepo.get());
}

void AppController::createControllers() {
    auto* w = m_dbWorker.get();
    m_backupController      = std::make_unique<BackupController>(m_dbPath, this);
    m_setupController       = std::make_unique<SetupController>(
        m_niveauRepo.get(), m_assocRepo.get(), m_setupSchoolYearRepo.get(), m_dbWorker.get(), this);
    m_yearClosureController = std::make_unique<YearClosureController>(
        m_yearClosureRepo.get(), m_dbWorker.get(), this);
    m_schoolingController = std::make_unique<SchoolingController>(m_schoolingService.get(), w, this);
    m_studentController = std::make_unique<StudentController>(m_studentService.get(), w, this);
    m_staffController = std::make_unique<StaffController>(m_staffService.get(), m_financeService.get(), w, this);
    m_attendanceController = std::make_unique<AttendanceController>(m_attendanceService.get(), w, this);
    m_examsController = std::make_unique<ExamsController>(m_attendanceService.get(),
                                                         m_schoolingService.get(), m_staffService.get(), w, this);
    m_gradesController = std::make_unique<GradesController>(m_gradesService.get(), w, this);
    m_financeController = std::make_unique<FinanceController>(m_financeService.get(), w, this);
    m_dashboardController = std::make_unique<DashboardController>(
        m_dashboardService.get(), m_schoolingService.get(),
        m_staffService.get(), m_studentService.get(), w, this);
}

void AppController::registerWithQml(QQmlApplicationEngine& engine) {
    auto* ctx = engine.rootContext();
    ctx->setContextProperty("appController",         this);
    ctx->setContextProperty("backupController",      m_backupController.get());
    ctx->setContextProperty("setupController",       m_setupController.get());
    ctx->setContextProperty("yearClosureController", m_yearClosureController.get());
    ctx->setContextProperty("schoolingController", m_schoolingController.get());
    ctx->setContextProperty("studentController", m_studentController.get());
    ctx->setContextProperty("staffController", m_staffController.get());
    ctx->setContextProperty("attendanceController", m_attendanceController.get());
    ctx->setContextProperty("examsController", m_examsController.get());
    ctx->setContextProperty("gradesController", m_gradesController.get());
    ctx->setContextProperty("financeController", m_financeController.get());
    ctx->setContextProperty("dashboardController", m_dashboardController.get());
}
