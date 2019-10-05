// myglwidget.cpp

#include "myglwidget.h"
#include "window.h"
#include "ui_window.h"

extern Ui::Window * ui_new;
MyGLWidget::MyGLWidget(QWidget *parent)
    : QGLWidget(QGLFormat(QGL::SampleBuffers), parent)
{
    xRot = 0;
    yRot = 0;
    zRot = 0;
    xPos = 0.0;
    yPos = 0.0;

    zoomValue = 1.0;
    RObjColor = 1;
    GObjColor = 0;
    BObjColor = 0;

    RBackColor = 0;
    GBackColor = 0;
    BBackColor = 0;

    RPointColor = 0;
    GPointColor = 0;
    BPointColor = 1;

    RRingColor = 0;
    GRingColor = 1;
    BRingColor = 1;
    PointSize = 10.0;


    read_number_of_faces = 0;
    read_number_of_vertices = 0;
    size_result = 0;
    size_result_n =0;

    harris_parameter = 0.04;
    fraction  = 0.01;
    radius_param = 2;
    selection_type= "fraction";
    size_result_n =0;
    n_type = "ring";    //ring //adaptive

    read_globalVerMinNorm = 0;
    read_globalVerMaxNorm = 0;

    MeshLines_checked = 0;

    read_parameters_flag = 1;
    Shading_Type = 0;
}

MyGLWidget::~MyGLWidget()
{
}

//minimumSizeHint and sizeHint functions are needed when resizing the window
QSize MyGLWidget::minimumSizeHint() const
{
    return QSize(50, 50);
}

QSize MyGLWidget::sizeHint() const
{
    return QSize(400, 400);
}

// from the source code available at https://www.bogotobogo.com/
// the angle is increase or decreased every 16 pixels move, to allow for more convenient rotation
// this is why we see this hard-coded 16 value here and there
// a trackball approach using quaternion would be more elegant...

static void qNormalizeAngle(int &angle)
{
    // urgl, it kind of hurts, but it works ;)
    while (angle < 0)
        angle += 360 * 16;
    while (angle > 360*16)
        angle -= 360 * 16;
}

//implementation of the 3 slots to catch rotation values from sliders and update the openglwidget
void MyGLWidget::setXRotation(int angle)
{
    //we assert the rotation value makes sense
    qNormalizeAngle(angle);

    if (angle != xRot) {//if rotation has changed
        xRot = angle; // update value
        emit xRotationChanged(angle); // emit a signal that carries the angular value
        updateGL(); // draw the scene
    }
}

// same goes for the Y and Z axis
void MyGLWidget::setYRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != yRot) {
        yRot = angle;
        emit yRotationChanged(angle);
        updateGL();
    }
}

void MyGLWidget::setZRotation(int angle)
{
    qNormalizeAngle(angle);
    if (angle != zRot) {
        zRot = angle;
        emit zRotationChanged(angle);
        updateGL();
    }
}

void MyGLWidget::loadOFFFile()
{
    filename = QFileDialog::getOpenFileName(this, tr("Open File"),"C://", "All files (*.*);;Text File (*.off)");
    QFile file(filename);
    if(!file.open(QFile::ReadOnly|QFile::Text)){
        if(!filename.isEmpty())
            QMessageBox::critical(0,"Error","Cannot open the file.");
    }
    else{
        MyOffFile off_file;
        off_file.readOffFile(filename.toUtf8().constData());

        //Delete the Harris point matrices
        for (int i = 0; i < size_result; i++){
            delete[] result[i];
            delete[] result_norm[i];
        }
        size_result = 0;

        //Delete the Rings matrices
        for (int i = 0; i < size_result_n; i++)
            delete[] result_n[i];
        size_result_n =0;
        //To reset tranlation loacation
        xPos = 0;
        yPos = 0;
        glTranslatef(xPos, yPos, -10.0);

        //To reset zoom loacation
        zoomValue = 1.0;
        glScalef(zoomValue, zoomValue, zoomValue);

        //To reset rotation loacation
        glLoadIdentity();

        xRot = 0;
        yRot = 0;
        zRot = 0;

        emit xRotationChanged(0);
        emit yRotationChanged(0);
        emit zRotationChanged(0);
        glRotatef(xRot / 16.0, 1.0, 0.0, 0.0);
        glRotatef(yRot / 16.0, 0.0, 1.0, 0.0);
        glRotatef(zRot / 16.0, 0.0, 0.0, 1.0);

        read_Faces_Buffer = off_file.get_Faces_Buffer();
        read_Vertices_Buffer = off_file.get_Vertices_Buffer();
        read_number_of_faces = off_file.get_number_of_faces();
        read_number_of_vertices = off_file.get_number_of_vertices();
        read_normalized_Vertices_Buffer = off_file.get_normalized_Vertices_Buffer();
        read_Vertices_Normal_Vectors_Buffer = off_file.get_Vertices_Normal_Vectors_Buffer();
        read_globalVerMinNorm = off_file.get_globalVerMinNorm();
        read_globalVerMaxNorm = off_file.get_globalVerMaxNorm();
        read_globalVerMin = off_file.get_globalVerMin();
        read_globalVerMax = off_file.get_globalVerMax();
        read_Faces_Normal_Vectors_Buffer = off_file.get_Faces_Normal_Vectors_Buffer();

        resizeGL(ui_new->myGLWidget->width(),ui_new->myGLWidget->height());
        ui_new->HarrisVerticeslistWidget->clear();
        updateGL();
    }
}

void MyGLWidget::calculateHarrisPoints()
{
    read_parameters_flag = 1;
    if(read_number_of_vertices == 0){
        QMessageBox::warning(0,"Error","You must load a mesh file fristly.");
        read_parameters_flag = 0;
    }
    else{
        if(fraction < 0){
            QMessageBox::warning(0,"Error","Diagonal fraction must be a positive number.");
            read_parameters_flag = 0;
        }
        if(harris_parameter<0){
            QMessageBox::warning(0,"Error","Harris parameter must be a positive number.");
            read_parameters_flag = 0;
        }
        if((radius_param<1)&&(n_type.compare("ring")==0)){
            QMessageBox::warning(0,"Error","Number of rings must be greater than 0.");
            read_parameters_flag = 0;
        }
        if(((radius_param<0)||(radius_param>1))&&(n_type.compare("adaptive")==0)){
            QMessageBox::warning(0,"Error","Adaptive parameter must be between 0 and 1.");
            read_parameters_flag = 0;
        }
        if(read_parameters_flag == 1){
            QString parameters;
            if(n_type.compare("ring")==0){
                parameters = QString("Interest points selection: %1\n"
                                     "Neighborhood type: %2\n"
                                     "Diagonal fraction: %3\n"
                                     "Harris parameter: %4\n"
                                     "Number of rings: %5\n"
                                     ).arg(QString::fromStdString(selection_type)).arg(QString::fromStdString(n_type)).arg(fraction).arg(harris_parameter).arg(radius_param);
            }
            else if(n_type.compare("adaptive")==0){
                parameters = QString("Interest points selection: %1\n"
                                     "Neighborhood type: %2\n"
                                     "Diagonal fraction: %3\n"
                                     "Harris parameter: %4\n"
                                     "Adaptive parameter: %5\n"
                                     ).arg(QString::fromStdString(selection_type)).arg(QString::fromStdString(n_type)).arg(fraction).arg(harris_parameter).arg(radius_param);
            }
            QMessageBox::information(this,"Detection parameters",parameters);
            for (int i = 0; i < size_result; i++){
                delete[] result[i];
                delete[] result_norm[i];
            }

            //Clear rings
            for (int i = 0; i < size_result_n; i++){
                delete[] result_n[i];
            }
            size_result_n = 0;
                // if selection_type == "ring" , radius_param = no_of_rings (1 to __)  else if selection_type=="adaptive", radius_param = adaptive_range (0 to 1)
            ret = cal_interest_points(result, size_result, filename.toUtf8().constData(),harris_parameter,fraction,radius_param,selection_type,n_type);
            ui_new->HarrisVerticeslistWidget->clear();
            QString list_item_str;
            for (int i = 0; i < size_result; i++)
            {
                list_item_str = QString("%1: %2, %3, %4").arg(i).arg(result[i][0]).arg(result[i][1]).arg(result[i][2]);
                ui_new->HarrisVerticeslistWidget->addItem(list_item_str);
            }
            list_item_str = QString("Clear all rings");

            ui_new->HarrisVerticeslistWidget->addItem(list_item_str);

            result_norm = new double*[size_result];
            for(int i=0;i<size_result;i++){
                result_norm[i] = new double[3];
            }
            for (int i = 0; i < size_result; i++)
            {
                result_norm[i][0] = result[i][0]/(read_globalVerMax-read_globalVerMin);
                result_norm[i][1] = result[i][1]/(read_globalVerMax-read_globalVerMin);
                result_norm[i][2] = result[i][2]/(read_globalVerMax-read_globalVerMin);
            }
            updateGL();
        }
    }

}

void MyGLWidget::changeObjRColor(int R_obj)
{

    if ((R_obj/100.0) != RObjColor) {
        RObjColor = R_obj/100.0;
        updateGL();
    }
}

void MyGLWidget::changeObjGColor(int G_obj)
{
    if ((G_obj/100.0) != GObjColor) {
        GObjColor = G_obj/100.0;
        updateGL();
    }
}

void MyGLWidget::changeObjBColor(int B_obj)
{
    if ((B_obj/100.0) != BObjColor) {
        BObjColor = B_obj/100.0;
        updateGL();
    }

}

void MyGLWidget::changePointRColor(int R_point)
{
    if ((R_point/100.0) != RPointColor) {
        RPointColor = R_point/100.0;
        updateGL();
    }

}

void MyGLWidget::changePointGColor(int G_point)
{
    if ((G_point/100.0) != GPointColor) {
        GPointColor = G_point/100.0;
        updateGL();
    }
}

void MyGLWidget::changePointBColor(int B_point)
{
    if ((B_point/100.0) != BPointColor) {
        BPointColor = B_point/100.0;
        updateGL();
    }
}

void MyGLWidget::changePointSize(int S_point)
{
    if ((S_point/5.0) != PointSize) {
        PointSize = S_point/5.0;
        updateGL();
    }
}

void MyGLWidget::changeBackRColor(int R_back)
{
    if ((R_back/100.0) != RBackColor) {
        RBackColor = R_back/100.0;
        updateGL();
    }

}

void MyGLWidget::changeBackGColor(int G_back)
{
    if ((G_back/100.0) != GBackColor) {
        GBackColor = G_back/100.0;
        updateGL();
    }
}

void MyGLWidget::changeBackBColor(int B_back)
{
    if ((B_back/100.0) != BBackColor) {
        BBackColor = B_back/100.0;
        updateGL();
    }

}

void MyGLWidget::changeRingRColor(int R_ring)
{
    if ((R_ring/100.0) != RRingColor) {
        RRingColor = R_ring/100.0;
        updateGL();
    }
}

void MyGLWidget::changeRingGColor(int G_ring)
{
    if ((G_ring/100.0) != GRingColor) {
        GRingColor = G_ring/100.0;
        updateGL();
    }
}

void MyGLWidget::changeRingBColor(int B_ring)
{
    if ((B_ring/100.0) != BRingColor) {
        BRingColor = B_ring/100.0;
        updateGL();
    }
}

void MyGLWidget::getDFlineEditValue(QString DF_val)
{
    fraction  = DF_val.toDouble();
}

void MyGLWidget::getRNlineEditValue(QString RN_val)
{
    //radius_param = RN_val.toDouble();
    radius_param = RN_val.toInt();
}

void MyGLWidget::getHPlineEditValue(QString HP_val)
{
    harris_parameter = HP_val.toDouble();
}

void MyGLWidget::getAPlineEditValue(QString AP_val)
{
    radius_param = AP_val.toDouble();
}

void MyGLWidget::getIPScomboBoxValue(int IPS_val)
{
    if(IPS_val == 0)
        selection_type= "fraction";
    else if(IPS_val == 1)
        selection_type= "clustering";
}

void MyGLWidget::getNTcomboBoxValue(int NT_val)
{
    if(NT_val == 0){
        ui_new->RNlabel->setEnabled(true);
        ui_new->RNlineEdit->setEnabled(true);
        ui_new->SPlabel->setEnabled(false);
        ui_new->SPlineEdit->setEnabled(false);
        radius_param = ui_new->RNlineEdit->text().toInt();
        n_type= "ring";
    }
    else if(NT_val == 1){
        ui_new->RNlabel->setEnabled(false);
        ui_new->RNlineEdit->setEnabled(false);
        ui_new->SPlabel->setEnabled(true);
        ui_new->SPlineEdit->setEnabled(true);
        radius_param = ui_new->SPlineEdit->text().toDouble();
        n_type= "adaptive";
    }
}

void MyGLWidget::getHVlistWidgetValue(QModelIndex HV_Val)
{
    for (int i =0; i < size_result_n ; i++)
    {
        delete[] result_n[i];
    }
    delete [] result_n;
    delete[] face;
    if(HV_Val.row()==(size_result))
        size_result_n =0;
    else
        int ret2 = get_faces(result_n,face, size_result_n, filename.toUtf8().constData(),radius_param, result[HV_Val.row()][0], result[HV_Val.row()][1] , result[HV_Val.row()][2],n_type);
    updateGL();

}

//If mesh line checkbox checked or not
void MyGLWidget::MLchecked(bool ML_chk)
{
    MeshLines_checked = ML_chk;
    updateGL();

}

void MyGLWidget::SFchecked()
{
    Shading_Type = 0;
    updateGL();
}

void MyGLWidget::SGchecked()
{
    Shading_Type = 1;
    updateGL();
}

void MyGLWidget::initializeGL()
{
        //init background color
        glClearColor(RBackColor,GBackColor,BBackColor, 1.0f);

        //enable depth test
        glEnable(GL_DEPTH_TEST);

        //enable face culling, see https://learnopengl.com/Advanced-OpenGL/Face-culling
        glEnable(GL_CULL_FACE);

        //enable smooth (linear color interpolation)
        glShadeModel(GL_SMOOTH);

        glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_TRUE);

        //we now set the light position
        GLfloat light_ambient[] = {0.2, 0.2, 0.2, 1.0};
        GLfloat light_diffuse[] = {0.8, 0.8, 0.8, 1.0};
        //GLfloat light_diffuse[] = {0.0, 0.0, 0.0, 0.0};
        GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
        glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
        glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
        glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
        static GLfloat lightPosition[4] = { 0, 0, 2, 1.0 };
        glLightfv(GL_LIGHT0, GL_POSITION, lightPosition);
        //we need at least 1 light to see something
        glEnable(GL_LIGHTING);
        //light0 is the default one
        glEnable(GL_LIGHT0);

        GLfloat qaBlack[] = {0.0, 0.0, 0.0, 1.0};
        GLfloat qaRed[] = {1.0, 0.0, 0.0, 1.0};
        GLfloat qaGreen[] = {0.0, 1.0, 0.0, 1.0};
        GLfloat qa_lightGrey[] = {0.75, 0.75, 0.75, 1.0};
        GLfloat qaGrey[] = {0.5, 0.5, 0.5, 1.0};
        GLfloat qa_darkGrey[] = {0.25, 0.25, 0.25, 1.0};
        GLfloat qaWhite[] = {1.0, 1.0, 1.0, 1.0};
        GLfloat low_sh[] = {64.0};
        glMaterialfv(GL_FRONT, GL_AMBIENT, qaBlack);
        glMaterialfv(GL_FRONT, GL_DIFFUSE, qaBlack);
        glMaterialfv(GL_FRONT, GL_SPECULAR, qa_lightGrey);
        glMaterialfv(GL_FRONT, GL_SHININESS, low_sh);
        glEnable(GL_COLOR_MATERIAL);

        glEnable(GL_NORMALIZE);
}

//paintGL is called whenever the GLwidget needs to be drawn.
//it first inits the transforms then calls the draw() member function
void MyGLWidget::paintGL()
{

    glClearColor(RBackColor,GBackColor,BBackColor, 1.0f);
    glEnable(GL_DEPTH_TEST);

    //glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
    //first, clear everything
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    //reset any transform
    glLoadIdentity();

    //translate to see the object. Comment that ligne to see the changes
    glTranslatef(xPos, yPos, -10.0);

    glScalef(zoomValue, zoomValue, zoomValue);

    //apply rotations along x, y, then z axis


    glRotatef(xRot / 16.0, 1.0, 0.0, 0.0);
    glRotatef(yRot / 16.0, 0.0, 1.0, 0.0);
    glRotatef(zRot / 16.0, 0.0, 0.0, 1.0);
    draw();
}

//resizeGL is used when the GLwidget is resized
void MyGLWidget::resizeGL(int width, int height)
{

    //first, we need to adjust the viewport,
    //see https://www.khronos.org/registry/OpenGL-Refpages/es2.0/xhtml/glViewport.xml

        int side = qMin(width, height);
        glViewport((width - side) / 2, (height - side) / 2, side, side);

    //glMatrixMode is used to activate the world in which some transforms will be applied
    //https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/glMatrixMode.xml

    glMatrixMode(GL_PROJECTION); //basically, we are working in the rendered image, in pixels
    glLoadIdentity();

    //Hmmm, QT might use various opengl emulators, so glOrtho might be replaced by glOrthof
    #ifdef QT_OPENGL_ES_1
        glOrthof(read_globalVerMinNorm, read_globalVerMaxNorm, read_globalVerMinNorm, read_globalVerMaxNorm, 1.0, 15.0);
    #else
        glOrtho(read_globalVerMinNorm, read_globalVerMaxNorm, read_globalVerMinNorm, read_globalVerMaxNorm, 1.0, 15.0);
    #endif

    glMatrixMode(GL_MODELVIEW);
}

void MyGLWidget::mousePressEvent(QMouseEvent *event)
{
    switch( event->buttons() ) {
    case Qt::LeftButton:
        lastPos = event->pos();
        break;
    }
}

void MyGLWidget::mouseMoveEvent(QMouseEvent *event)
{
    int dx = event->x() - lastPos.x();
    int dy = event->y() - lastPos.y();
    if (event->buttons() & Qt::LeftButton) {
        xPos = xPos + double(dx)/750;
        yPos = yPos - double(dy)/750;
        updateGL();

    } else if (event->buttons() & Qt::RightButton) {
        setXRotation(xRot + 8 * dy);
        setYRotation(yRot + 8 * dx);
    }
    lastPos = event->pos();

}

void MyGLWidget::wheelEvent(QWheelEvent *event)
{

    QPoint numDegrees = event->angleDelta() / 8;
    if (!numDegrees.isNull()) {
        if(numDegrees.y()>0)
            zoomValue = zoomValue + 0.05;
        else
            zoomValue = zoomValue - 0.05;
        updateGL();
    }
}

void MyGLWidget::draw()
{
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);


    if(Shading_Type == 0){
        glColor3f(RRingColor,GRingColor,BRingColor);
        for(int i=0;i<size_result_n;i++){
            vect1[0] = read_normalized_Vertices_Buffer[result_n[i][1]][0] - read_normalized_Vertices_Buffer[result_n[i][0]][0];
            vect1[1] = read_normalized_Vertices_Buffer[result_n[i][1]][1] - read_normalized_Vertices_Buffer[result_n[i][0]][1];
            vect1[2] = read_normalized_Vertices_Buffer[result_n[i][1]][2] - read_normalized_Vertices_Buffer[result_n[i][0]][2];

            vect2[0] = read_normalized_Vertices_Buffer[result_n[i][2]][0] - read_normalized_Vertices_Buffer[result_n[i][0]][0];
            vect2[1] = read_normalized_Vertices_Buffer[result_n[i][2]][1] - read_normalized_Vertices_Buffer[result_n[i][0]][1];
            vect2[2] = read_normalized_Vertices_Buffer[result_n[i][2]][2] - read_normalized_Vertices_Buffer[result_n[i][0]][2];

            norm_vect[0] = vect1[1]*vect2[2] - vect1[2]*vect2[1];
            norm_vect[1] = vect1[2]*vect2[0] - vect1[0]*vect2[2];
            norm_vect[2] = vect1[0]*vect2[1] - vect1[1]*vect2[0];

           glNormal3f(norm_vect[0],norm_vect[1],norm_vect[2]);
            glBegin(GL_TRIANGLES);
                glVertex3f(read_normalized_Vertices_Buffer[result_n[i][0]][0],read_normalized_Vertices_Buffer[result_n[i][0]][1],read_normalized_Vertices_Buffer[result_n[i][0]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[result_n[i][1]][0],read_normalized_Vertices_Buffer[result_n[i][1]][1],read_normalized_Vertices_Buffer[result_n[i][1]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[result_n[i][2]][0],read_normalized_Vertices_Buffer[result_n[i][2]][1],read_normalized_Vertices_Buffer[result_n[i][2]][2]);
            glEnd();
        }

        glColor3f(RObjColor,GObjColor,BObjColor);
        for(int i=0;i<read_number_of_faces;i++){
            glNormal3f(read_Faces_Normal_Vectors_Buffer[i][0],read_Faces_Normal_Vectors_Buffer[i][1],read_Faces_Normal_Vectors_Buffer[i][2]);
            glBegin(GL_TRIANGLES);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][2]);
            glEnd();
        }
    }
    else if(Shading_Type == 1){

        for(int i=0;i<read_number_of_faces;i++){
            glColor3f(RRingColor,GRingColor,BRingColor);
            for(int i=0;i<size_result_n;i++){
                glBegin(GL_TRIANGLES);
                    glNormal3f(read_Vertices_Normal_Vectors_Buffer[result_n[i][0]][0],read_Vertices_Normal_Vectors_Buffer[result_n[i][0]][1],read_Vertices_Normal_Vectors_Buffer[result_n[i][0]][2]);
                    glVertex3f(read_normalized_Vertices_Buffer[result_n[i][0]][0],read_normalized_Vertices_Buffer[result_n[i][0]][1],read_normalized_Vertices_Buffer[result_n[i][0]][2]);
                    glNormal3f(read_Vertices_Normal_Vectors_Buffer[result_n[i][1]][0],read_Vertices_Normal_Vectors_Buffer[result_n[i][1]][1],read_Vertices_Normal_Vectors_Buffer[result_n[i][1]][2]);
                    glVertex3f(read_normalized_Vertices_Buffer[result_n[i][1]][0],read_normalized_Vertices_Buffer[result_n[i][1]][1],read_normalized_Vertices_Buffer[result_n[i][1]][2]);
                    glNormal3f(read_Vertices_Normal_Vectors_Buffer[result_n[i][2]][0],read_Vertices_Normal_Vectors_Buffer[result_n[i][2]][1],read_Vertices_Normal_Vectors_Buffer[result_n[i][2]][2]);
                    glVertex3f(read_normalized_Vertices_Buffer[result_n[i][2]][0],read_normalized_Vertices_Buffer[result_n[i][2]][1],read_normalized_Vertices_Buffer[result_n[i][2]][2]);
                glEnd();
            }
            glColor3f(RObjColor,GObjColor,BObjColor);
            glBegin(GL_TRIANGLES);
                glNormal3f(read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][0]][0],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][0]][1],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][0]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][2]);
                glNormal3f(read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][1]][0],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][1]][1],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][1]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][2]);
                glNormal3f(read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][2]][0],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][2]][1],read_Vertices_Normal_Vectors_Buffer[read_Faces_Buffer[i][2]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][2]);
            glEnd();
        }
    }

    if(MeshLines_checked){
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        glColor3f(0.0f, 0.0f, 0.0f);
        for(int i=0;i<read_number_of_faces;i++){

            glBegin(GL_TRIANGLES);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][0]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][1]][2]);
                glVertex3f(read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][0],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][1],read_normalized_Vertices_Buffer[read_Faces_Buffer[i][2]][2]);
            glEnd();
        }
    }

    glPointSize(PointSize); //Set the Point size
    glColor3f(RPointColor, GPointColor, BPointColor); //Set the Point color
    for (int i = 0; i < size_result; i++)
    {
        glBegin (GL_POINTS);
            glVertex3f (result_norm[i][0], result_norm[i][1], result_norm[i][2]);
        glEnd ();
    }
}
