#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFont>
#include <QQuickWindow>
#include <QTimer>
#include <QTranslator>

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
    app.setApplicationVersion(QStringLiteral(APP_VERSION_STR));

    // Set default font
    QFont defaultFont("Inter", 13);
    defaultFont.setHintingPreference(QFont::PreferFullHinting);
    app.setFont(defaultFont);

    // Use Basic style for clean look
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

    // Add import paths for our QML modules
    engine.addImportPath("qrc:/qt/qml/");

    // Expose version string to QML
    engine.rootContext()->setContextProperty(
        QStringLiteral("appVersion"),
        QStringLiteral(APP_VERSION_STR));

    // Bootstrap the entire C++ backend
    AppController appController(engine);

    // ── Translation Setup ──
    QTranslator translator;
    QString lang = appController.getLanguage();
    
    qDebug() << "[Main] Langue récupérée depuis la base de données :" << lang;

    if (lang == "arabe") {
        qDebug() << "[Main] Tentative de chargement du fichier de traduction ar_AE.qm...";
        if (translator.load(":/i18n/ar_AE.qm") ||
            translator.load(":/qt/qml/GestionScolaire/i18n/ar_AE.qm") ||
            translator.load(":/GestionScolaire/i18n/ar_AE.qm") ||
            translator.load("ar_AE", ":/i18n/")) {
            app.installTranslator(&translator);
            qInfo() << "[Main] Traduction arabe chargée et installée avec succès.";
        } else {
            qWarning() << "[Main] ERREUR : Impossible de trouver ou charger le fichier ar_AE.qm !";
        }
    } else {
        qDebug() << "[Main] Pas de traduction chargée (langue actuelle :" << lang << ")";
    }

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



