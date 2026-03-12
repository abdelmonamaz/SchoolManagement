#pragma once

#include <QObject>
#include <QQmlApplicationEngine>
#include <memory>

class DatabaseWorker;

class SchoolingService;
class StudentService;
class StaffService;
class AttendanceService;
class GradesService;
class FinanceService;
class DashboardService;

class SchoolingController;
class StudentController;
class StaffController;
class AttendanceController;
class ExamsController;
class GradesController;
class FinanceController;
class DashboardController;
class SetupController;
class BackupController;
class YearClosureController;

class ISalleRepository;
class INiveauRepository;
class IClasseRepository;
class IMatiereRepository;
class IMatiereExamenRepository;
class ITypeExamenRepository;
class IEquipementRepository;
class IPersonnelRepository;
class IContratRepository;
class IEleveRepository;
class ISeanceRepository;
class IParticipationRepository;
class IPaiementRepository;
class IProjetRepository;
class IDonateurRepository;
class IDonRepository;
class IPaiementPersonnelRepository;
class ITarifMensualiteRepository;
class IDepenseRepository;
class IFinanceBalanceRepository;
class IAssociationRepository;
class ISetupSchoolYearRepository;
class IYearClosureRepository;

class AppController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString dbInitError READ dbInitError NOTIFY dbInitErrorChanged)

public:
    explicit AppController(QQmlApplicationEngine& engine, QObject* parent = nullptr);
    ~AppController() override;

    QString dbInitError() const { return m_dbInitError; }
    QString getLanguage() const;

signals:
    void dbInitErrorChanged();

private:
    void setupDatabase();
    void createRepositories();
    void createServices();
    void createControllers();
    void registerWithQml(QQmlApplicationEngine& engine);

    // Database
    QString m_dbPath;
    QString m_dbInitError;
    std::unique_ptr<DatabaseWorker> m_dbWorker;

    // Repositories (owned, created on main thread for now)
    std::unique_ptr<ISalleRepository> m_salleRepo;
    std::unique_ptr<INiveauRepository> m_niveauRepo;
    std::unique_ptr<IClasseRepository> m_classeRepo;
    std::unique_ptr<IMatiereRepository> m_matiereRepo;
    std::unique_ptr<IMatiereExamenRepository> m_matiereExamenRepo;
    std::unique_ptr<ITypeExamenRepository> m_typeExamenRepo;
    std::unique_ptr<IEquipementRepository> m_equipementRepo;
    std::unique_ptr<IPersonnelRepository> m_profRepo;
    std::unique_ptr<IContratRepository> m_contratRepo;
    std::unique_ptr<IEleveRepository> m_eleveRepo;
    std::unique_ptr<ISeanceRepository> m_seanceRepo;
    std::unique_ptr<IParticipationRepository> m_participationRepo;
    std::unique_ptr<IPaiementRepository> m_paiementRepo;
    std::unique_ptr<IProjetRepository> m_projetRepo;
    std::unique_ptr<IDonateurRepository> m_donateurRepo;
    std::unique_ptr<IDonRepository> m_donRepo;
    std::unique_ptr<IPaiementPersonnelRepository> m_paiementPersonnelRepo;
    std::unique_ptr<ITarifMensualiteRepository>    m_tarifRepo;
    std::unique_ptr<IDepenseRepository>            m_depenseRepo;
    std::unique_ptr<IFinanceBalanceRepository>     m_balanceRepo;
    std::unique_ptr<IAssociationRepository>        m_assocRepo;
    std::unique_ptr<ISetupSchoolYearRepository>    m_setupSchoolYearRepo;
    std::unique_ptr<IYearClosureRepository>        m_yearClosureRepo;

    // Services (owned)
    std::unique_ptr<SchoolingService> m_schoolingService;
    std::unique_ptr<StudentService> m_studentService;
    std::unique_ptr<StaffService> m_staffService;
    std::unique_ptr<AttendanceService> m_attendanceService;
    std::unique_ptr<GradesService> m_gradesService;
    std::unique_ptr<FinanceService> m_financeService;
    std::unique_ptr<DashboardService> m_dashboardService;

    // Controllers (owned)
    std::unique_ptr<BackupController> m_backupController;
    std::unique_ptr<SetupController> m_setupController;
    std::unique_ptr<YearClosureController> m_yearClosureController;
    std::unique_ptr<SchoolingController> m_schoolingController;
    std::unique_ptr<StudentController> m_studentController;
    std::unique_ptr<StaffController> m_staffController;
    std::unique_ptr<AttendanceController> m_attendanceController;
    std::unique_ptr<ExamsController> m_examsController;
    std::unique_ptr<GradesController> m_gradesController;
    std::unique_ptr<FinanceController> m_financeController;
    std::unique_ptr<DashboardController> m_dashboardController;
};
