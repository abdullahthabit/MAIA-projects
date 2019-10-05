// myglwidget.h

#ifndef MYGLWIDGET_H
#define MYGLWIDGET_H

#include <QGLWidget>
#include <QWheelEvent>
#include <QtOpenGL>
#include <QtDebug>
#include <string.h>
#include <qfile.h>

#include "myofffile.h"
#include "harris.h"

// WE are going to create our OpenglComponent, by first inheriting from a QGLWidget (thanks to qt!)
// http://doc.qt.io/archives/qt-4.8/qglwidget.html
// then we add a couple of very useful functions

class MyGLWidget : public QGLWidget
{
    Q_OBJECT
public:
    explicit MyGLWidget(QWidget *parent = 0);
    ~MyGLWidget();
signals:

public slots:

protected:
    // opengl functions
    void initializeGL();
    void paintGL();
    void resizeGL(int width, int height);

    //functions to handle widget stretching
    QSize minimumSizeHint() const;
    QSize sizeHint() const;

    //overloads to handle mouse events
    void mousePressEvent(QMouseEvent *event);
    void mouseMoveEvent(QMouseEvent *event);
    void wheelEvent(QWheelEvent *event);

public slots:
    // slots for xyz-rotation slider
    void setXRotation(int angle);
    void setYRotation(int angle);
    void setZRotation(int angle);
    void loadOFFFile();
    void calculateHarrisPoints();
    void changeObjRColor(int R_obj);
    void changeObjGColor(int G_obj);
    void changeObjBColor(int B_obj);
    void changePointRColor(int R_point);
    void changePointGColor(int G_point);
    void changePointBColor(int B_point);
    void changePointSize(int S_point);
    void changeBackRColor(int R_back);
    void changeBackGColor(int G_back);
    void changeBackBColor(int B_back);
    void changeRingRColor(int R_ring);
    void changeRingGColor(int G_ring);
    void changeRingBColor(int B_ring);
    void getDFlineEditValue(QString DF_val);
    void getRNlineEditValue(QString RN_val);
    void getHPlineEditValue(QString HP_val);
    void getAPlineEditValue(QString AP_val);
    void getIPScomboBoxValue(int IPS_val);
    void getNTcomboBoxValue(int NT_val);
    void getHVlistWidgetValue(QModelIndex HV_Val);
    void MLchecked(bool ML_chk);
    void SFchecked();
    void SGchecked();

signals:
    // signaling rotation from mouse movement
    void xRotationChanged(int angle);
    void yRotationChanged(int angle);
    void zRotationChanged(int angle);

private:
    void draw(); // openGL code to draw a pyramid in this example

    int xRot;
    int yRot;
    int zRot;
    float xPos,yPos;
    float zoomValue;
    float ** read_Vertices_Buffer;
    float ** read_normalized_Vertices_Buffer;
    int ** read_Faces_Buffer;
    float** read_Faces_Normal_Vectors_Buffer;
    float** read_Vertices_Normal_Vectors_Buffer;
    int read_number_of_vertices;
    int read_number_of_faces;
    float vect1[3],vect2[3],norm_vect[3];
    float RObjColor,GObjColor,BObjColor,RPointColor,GPointColor,BPointColor,RBackColor,GBackColor,BBackColor,PointSize,RRingColor,GRingColor,BRingColor;

    // Parameters to be edited
    double harris_parameter;
    double fraction;
    double radius_param;
    QString filename;
    string selection_type;
    double ** result;
    double ** result_norm;
    int size_result;

    int ** result_n;
    int size_result_n;
    int * face;
    int ret;
    string n_type;
    int read_parameters_flag;

    //GLfloat xVerMin,xVerMax,yVerMin,yVerMax,zVerMin,zVerMax,globalVerMin,globalVerMax,globalVerMinNorm,globalVerMaxNorm;
    GLfloat read_globalVerMin,read_globalVerMax,read_globalVerMinNorm,read_globalVerMaxNorm;
    QPoint lastPos; // last cursor location
    bool MeshLines_checked;
    int Shading_Type;
};

#endif // MYGLWIDGET_H

