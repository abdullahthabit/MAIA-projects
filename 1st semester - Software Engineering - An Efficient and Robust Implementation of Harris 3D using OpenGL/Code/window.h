// window.h

#ifndef WINDOW_H
#define WINDOW_H

#include <QWidget>
#include <QSlider>

namespace Ui {
class Window;
}

//instead of building an application with menus, status bar, etc.,
//the main window simply inherits from QWidget

class Window : public QWidget
{
    Q_OBJECT

public:
    explicit Window(QWidget *parent = 0);
    ~Window();
    Ui::Window *ui;

protected:
    //overload for keyboard handling to quit when ESC key is pressed
    void keyPressEvent(QKeyEvent *event);

private slots:

//private:
    //Ui::Window *ui;
};

#endif // WINDOW_H
