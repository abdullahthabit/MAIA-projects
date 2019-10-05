// window.cpp

#include <QtWidgets>
#include "window.h"
#include "ui_window.h"

#include "myglwidget.h"

Ui::Window * ui_new;

Window::Window(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::Window)
{
    ui->setupUi(this);

    // manual slot/signal connection example.
    // http://doc.qt.io/archives/qt-4.8/signalsandslots.html

    connect(
                ui->myGLWidget,                 // sender object
                SIGNAL(xRotationChanged(int)),  // sent signal carrying an int
                ui->rotXSlider,                 // receiver
                SLOT(setValue(int)));           // slot function executed


    //same applies for the other 2 sliders
        connect(ui->myGLWidget, SIGNAL(yRotationChanged(int)), ui->rotYSlider, SLOT(setValue(int)));
        connect(ui->myGLWidget, SIGNAL(zRotationChanged(int)), ui->rotZSlider, SLOT(setValue(int)));
        ui_new = ui;
}

Window::~Window()
{
    delete ui;
}

//overload of the keyPressEvent function for the window, as seen in first QT Labs
void Window::keyPressEvent(QKeyEvent *e)
{
    if (e->key() == Qt::Key_Escape)
        close();
    else
        QWidget::keyPressEvent(e);
}
