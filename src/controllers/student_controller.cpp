#include "controllers/student_controller.h"
#include "services/student_service.h"
#include "database/database_worker.h"

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
        {"dateNaissance", e.dateNaissance},
        {"categorie", typePublicToString(e.categorie)}, {"classeId", e.classeId}
    };
}

StudentController::StudentController(StudentService* service, DatabaseWorker* worker, QObject* parent)
    : QObject(parent), m_service(service), m_worker(worker)
{
    connect(m_worker, &DatabaseWorker::queryCompleted, this, &StudentController::onQueryCompleted);
    connect(m_worker, &DatabaseWorker::queryError, this, &StudentController::onQueryError);
}

void StudentController::setLoading(bool v) {
    if (m_loading != v) { m_loading = v; emit loadingChanged(); }
}

void StudentController::setError(const QString& e) {
    m_errorMessage = e; emit errorMessageChanged();
}

void StudentController::loadStudents() {
    setLoading(true);
    m_worker->submit("Student.loadStudents", [svc = m_service]() -> QVariant {
        auto result = svc->getAllStudents();
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& e : result.value()) list.append(eleveToMap(e));
        return list;
    });
}

void StudentController::loadStudentsByClasse(int classeId) {
    setLoading(true);
    m_worker->submit("Student.loadStudentsByClasse", [svc = m_service, classeId]() -> QVariant {
        auto result = svc->getStudentsByClasse(classeId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& e : result.value()) list.append(eleveToMap(e));
        return list;
    });
}

void StudentController::searchStudents(const QString& query) {
    setLoading(true);
    m_worker->submit("Student.searchStudents", [svc = m_service, query]() -> QVariant {
        auto result = svc->searchByName(query);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        QVariantList list;
        for (const auto& e : result.value()) list.append(eleveToMap(e));
        return list;
    });
}

void StudentController::createStudent(const QVariantMap& data) {
    m_worker->submit("Student.createStudent", [svc = m_service, data]() -> QVariant {
        auto result = svc->createStudent(
            data.value("nom").toString(),
            data.value("prenom").toString(),
            data.value("telephone").toString(),
            data.value("adresse").toString(),
            data.value("dateNaissance").toString(),
            stringToTypePublic(data.value("categorie").toString()),
            data.value("classeId").toInt());
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StudentController::updateStudent(int id, const QVariantMap& data) {
    m_worker->submit("Student.updateStudent", [svc = m_service, id, data]() -> QVariant {
        Eleve e;
        e.id = id;
        e.nom = data.value("nom").toString();
        e.prenom = data.value("prenom").toString();
        e.telephone = data.value("telephone").toString();
        e.adresse = data.value("adresse").toString();
        e.dateNaissance = data.value("dateNaissance").toString();
        e.categorie = stringToTypePublic(data.value("categorie").toString());
        e.classeId = data.value("classeId").toInt();
        auto result = svc->updateStudent(e);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StudentController::deleteStudent(int id) {
    m_worker->submit("Student.deleteStudent", [svc = m_service, id]() -> QVariant {
        auto result = svc->deleteStudent(id);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StudentController::selectStudent(int index) {
    if (index >= 0 && index < m_students.size()) {
        m_selectedStudent = m_students.at(index).toMap();
    } else {
        m_selectedStudent.clear();
    }
    emit selectedStudentChanged();
}

void StudentController::onQueryCompleted(const QString& queryId, const QVariant& result) {
    if (!queryId.startsWith("Student.")) return;

    auto map = result.toMap();
    bool isError = map.contains("error");

    if (queryId == "Student.loadStudents" || queryId == "Student.loadStudentsByClasse" || queryId == "Student.searchStudents") {
        if (isError) setError(map["error"].toString());
        else { m_students = result.toList(); emit studentsChanged(); }
        setLoading(false);
    }
    else if (queryId == "Student.createStudent") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Élève inscrit"); loadStudents(); }
    }
    else if (queryId == "Student.updateStudent") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Élève mis à jour"); loadStudents(); }
    }
    else if (queryId == "Student.deleteStudent") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Élève supprimé"); loadStudents(); }
    }
    else if (queryId == "Student.unassignFromClasse") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Élèves retirés de la classe"); loadStudents(); }
    }
    else if (queryId == "Student.removeFromClasse") {
        if (isError) emit operationFailed(map["error"].toString());
        else { emit operationSucceeded("Élève retiré de la classe"); loadStudents(); }
    }
}

void StudentController::unassignStudentsFromClasse(int classeId) {
    m_worker->submit("Student.unassignFromClasse", [svc = m_service, classeId]() -> QVariant {
        auto result = svc->unassignStudentsFromClasse(classeId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StudentController::removeStudentFromClasse(int studentId) {
    m_worker->submit("Student.removeFromClasse", [svc = m_service, studentId]() -> QVariant {
        auto result = svc->removeStudentFromClasse(studentId);
        if (!result.isOk())
            return QVariantMap{{"error", result.errorMessage()}};
        return QVariantMap{{"success", true}};
    });
}

void StudentController::onQueryError(const QString& queryId, const QString& error) {
    if (!queryId.startsWith("Student.")) return;

    if (queryId.startsWith("Student.load") || queryId.startsWith("Student.search")) {
        setError(error);
        setLoading(false);
    } else {
        emit operationFailed(error);
    }
}
