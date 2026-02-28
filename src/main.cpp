#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QFont>
#include <QQuickWindow>
#include <QTimer>

#include "app/app_controller.h"

int main(int argc, char *argv[])
{
    // ── Workaround QTBUG-141128 (Qt 6.9.x / Windows) ──────────────────────────
    // QWindowsWindow::requestUpdate() programme des lambdas vsync via timer.
    // Après veille, plusieurs lambdas s'accumulent et le 2ème tire après que
    // hasPendingUpdateRequest a été remis à zéro par le 1er → assertion fatale.
    // Le render loop "basic" évite ce scheduling asynchrone entièrement.
    // Doit être défini AVANT la création de QGuiApplication.
    qputenv("QSG_RENDER_LOOP", "basic");

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

    // Fix: après un cycle veille/réveil Windows, le render loop Qt peut avoir
    // des update requests en attente dans un état incohérent (assertion
    // "hasPendingUpdateRequest" dans qplatformwindow.cpp).
    // On force un update propre sur toutes les fenêtres QQuick au réveil.
    QObject::connect(&app, &QGuiApplication::applicationStateChanged,
        [&engine](Qt::ApplicationState state) {
            if (state == Qt::ApplicationActive) {
                QTimer::singleShot(150, [&engine]() {
                    for (QObject* obj : engine.rootObjects()) {
                        if (auto* w = qobject_cast<QQuickWindow*>(obj))
                            w->update();
                    }
                });
            }
        });

    return app.exec();
}
