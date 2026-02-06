#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QFont>

#include "app/app_controller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("Ez-Zaytouna");
    app.setApplicationName("Gestion Scolaire");
    app.setApplicationVersion("2.0");

    // Set default font
    QFont defaultFont("Inter", 13);
    defaultFont.setHintingPreference(QFont::PreferFullHinting);
    app.setFont(defaultFont);

    // Use Basic style for clean look
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

    // Add import paths for our QML modules
    engine.addImportPath("qrc:/qt/qml/");

    // Bootstrap the entire C++ backend
    AppController appController(engine);

    const QUrl url(QStringLiteral("qrc:/qt/qml/GestionScolaire/qml/main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
