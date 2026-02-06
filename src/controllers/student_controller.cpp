#include "controllers/student_controller.h"
#include "services/student_service.h"

static QString typePublicToString(GS::TypePublic t) {
    return t == GS::TypePublic::Adulte ? QStringLiteral("Adulte") : QStringLiteral("Jeune");
}

static GS::TypePublic stringToTypePublic(const QString& s) {
    return s == QStringLiteral("Adulte") ? GS::TypePublic::Adulte : GS::TypePublic::Jeune;
}

static QVariantMap eleveToMap(const Eleve& e) {
    return {
        {"id", e.id}, {"nom", e.nom}, {"prenom", e.prenom},
        {"telephone", e.telephone}, {"adresse", e.adresse},
        {"categorie", typePublicToString(e.categorie)}, {"classeId", e.classeId}
    };
}

StudentController::StudentController(StudentService* service, QObject* parent)
    : QObject(parent), m_service(service) {}

void StudentController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void StudentController::setError(const QString& e) {
    m_errorMessage = e; emit errorMessageChanged();
}

void StudentController::loadStudents() {
    setLoading(true);
    auto result = m_service->getAllStudents();
    if (result.isOk()) {
        m_students.clear();
        for (const auto& e : result.value()) m_students.append(eleveToMap(e));
        emit studentsChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void StudentController::loadStudentsByClasse(int classeId) {
    setLoading(true);
    auto result = m_service->getStudentsByClasse(classeId);
    if (result.isOk()) {
        m_students.clear();
        for (const auto& e : result.value()) m_students.append(eleveToMap(e));
        emit studentsChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void StudentController::searchStudents(const QString& query) {
    setLoading(true);
    auto result = m_service->searchByName(query);
    if (result.isOk()) {
        m_students.clear();
        for (const auto& e : result.value()) m_students.append(eleveToMap(e));
        emit studentsChanged();
    } else {
        setError(result.errorMessage());
    }
    setLoading(false);
}

void StudentController::createStudent(const QVariantMap& data) {
    auto result = m_service->createStudent(
        data.value("nom").toString(),
        data.value("prenom").toString(),
        data.value("telephone").toString(),
        data.value("adresse").toString(),
        stringToTypePublic(data.value("categorie").toString()),
        data.value("classeId").toInt());
    if (result.isOk()) {
        emit operationSucceeded("Élève inscrit");
        loadStudents();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StudentController::updateStudent(int id, const QVariantMap& data) {
    Eleve e;
    e.id = id;
    e.nom = data.value("nom").toString();
    e.prenom = data.value("prenom").toString();
    e.telephone = data.value("telephone").toString();
    e.adresse = data.value("adresse").toString();
    e.categorie = stringToTypePublic(data.value("categorie").toString());
    e.classeId = data.value("classeId").toInt();
    auto result = m_service->updateStudent(e);
    if (result.isOk()) {
        emit operationSucceeded("Élève mis à jour");
        loadStudents();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StudentController::deleteStudent(int id) {
    auto result = m_service->deleteStudent(id);
    if (result.isOk()) {
        emit operationSucceeded("Élève supprimé");
        loadStudents();
    } else {
        emit operationFailed(result.errorMessage());
    }
}

void StudentController::selectStudent(int index) {
    if (index >= 0 && index < m_students.size()) {
        m_selectedStudent = m_students.at(index).toMap();
    } else {
        m_selectedStudent.clear();
    }
    emit selectedStudentChanged();
}
