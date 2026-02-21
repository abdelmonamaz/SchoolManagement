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

class ISalleRepository;
class INiveauRepository;
class IClasseRepository;
class IMatiereRepository;
class IEquipementRepository;
class IPersonnelRepository;
class IEleveRepository;
class ISeanceRepository;
class IParticipationRepository;
class IPaiementRepository;
class IProjetRepository;
class IDonateurRepository;
class IDonRepository;
class IPaiementPersonnelRepository;

class AppController : public QObject {
    Q_OBJECT

public:
    explicit AppController(QQmlApplicationEngine& engine, QObject* parent = nullptr);
    ~AppController() override;

private:
    void setupDatabase();
    void createRepositories();
    void createServices();
    void createControllers();
    void registerWithQml(QQmlApplicationEngine& engine);

    // Database
    std::unique_ptr<DatabaseWorker> m_dbWorker;

    // Repositories (owned, created on main thread for now)
    std::unique_ptr<ISalleRepository> m_salleRepo;
    std::unique_ptr<INiveauRepository> m_niveauRepo;
    std::unique_ptr<IClasseRepository> m_classeRepo;
    std::unique_ptr<IMatiereRepository> m_matiereRepo;
    std::unique_ptr<IEquipementRepository> m_equipementRepo;
    std::unique_ptr<IPersonnelRepository> m_profRepo;
    std::unique_ptr<IEleveRepository> m_eleveRepo;
    std::unique_ptr<ISeanceRepository> m_seanceRepo;
    std::unique_ptr<IParticipationRepository> m_participationRepo;
    std::unique_ptr<IPaiementRepository> m_paiementRepo;
    std::unique_ptr<IProjetRepository> m_projetRepo;
    std::unique_ptr<IDonateurRepository> m_donateurRepo;
    std::unique_ptr<IDonRepository> m_donRepo;
    std::unique_ptr<IPaiementPersonnelRepository> m_paiementPersonnelRepo;

    // Services (owned)
    std::unique_ptr<SchoolingService> m_schoolingService;
    std::unique_ptr<StudentService> m_studentService;
    std::unique_ptr<StaffService> m_staffService;
    std::unique_ptr<AttendanceService> m_attendanceService;
    std::unique_ptr<GradesService> m_gradesService;
    std::unique_ptr<FinanceService> m_financeService;
    std::unique_ptr<DashboardService> m_dashboardService;

    // Controllers (owned)
    std::unique_ptr<SchoolingController> m_schoolingController;
    std::unique_ptr<StudentController> m_studentController;
    std::unique_ptr<StaffController> m_staffController;
    std::unique_ptr<AttendanceController> m_attendanceController;
    std::unique_ptr<ExamsController> m_examsController;
    std::unique_ptr<GradesController> m_gradesController;
    std::unique_ptr<FinanceController> m_financeController;
    std::unique_ptr<DashboardController> m_dashboardController;
};
