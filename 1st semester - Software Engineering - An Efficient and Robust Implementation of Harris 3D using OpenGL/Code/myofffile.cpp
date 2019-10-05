#include "myofffile.h"
#include <QtWidgets>
#include <QtDebug>
#include <fstream>
#include <QMessageBox>

MyOffFile::MyOffFile()
{
    number_of_vertices = 0;
    number_of_faces = 0;
}

void MyOffFile::readOffFile(string filename)
{
    string line;
    ifstream objFile(filename);
    for (int i =0; i < number_of_vertices ; i++){
        delete[] Vertices_Buffer[i];
        delete[] normalized_Vertices_Buffer[i];
        delete[] Vertices_Normal_Vectors_Buffer[i];
        }
    for (int i =0; i < number_of_faces ; i++){
            delete[] Faces_Buffer[i];
            delete[] Faces_Normal_Vectors_Buffer[i];
        }
        getline (objFile,line);
        if (line.find("OFF") == string::npos){
            QMessageBox::critical(0,"Error","This is not an OFF file as it does not contain OFF in the first line.");
        }
        else{
            getline (objFile,line);
            sscanf(line.c_str(),"%d %d %d",&number_of_vertices,&number_of_faces,&number_of_edges);
            if ((number_of_vertices == 0)||(number_of_faces == 0)){
                QMessageBox::critical(0,"Error","Cannot read the number of vertices and number of faces.");
            }
            else{
                Vertices_Buffer = new float*[number_of_vertices];
                for(int i=0;i<number_of_vertices;i++){
                    Vertices_Buffer[i] = new float[3];
                }
                Faces_Buffer = new int*[number_of_faces];
                for(int i=0;i<number_of_faces;i++){
                    Faces_Buffer[i] = new int[3];
                }


                for(int i=0;i<number_of_vertices;i++){
                    getline (objFile,line);
                    if(line.empty())
                        i--;
                    else
                        sscanf(line.c_str(),"%f %f %f",&Vertices_Buffer[i][0],&Vertices_Buffer[i][1],&Vertices_Buffer[i][2]);
                }
                for(int i=0;i<number_of_faces;i++){
                    getline (objFile,line);
                    if(line.empty())
                        i--;
                    else{
                        sscanf(line.c_str(),"%d %d %d %d",&POINTS_PER_VERTEX,&Faces_Buffer[i][0],&Faces_Buffer[i][1],&Faces_Buffer[i][2]);
                        if(POINTS_PER_VERTEX != 3){
                           QMessageBox::critical(0,"Error","The mesh contains more than 3 points per face.");
                           for (int i =0; i < number_of_vertices ; i++){
                               delete[] Vertices_Buffer[i];
                               }
                           for (int i =0; i < number_of_faces ; i++){
                                   delete[] Faces_Buffer[i];
                               }
                           number_of_vertices = 0;
                           number_of_faces = 0;
                           number_of_edges = 0;
                           break;
                        }
                    }
                }
                if((number_of_vertices!=0)&&(number_of_faces!=0)){
                    normalize_vertices();
                    calculate_faces_normal_vectors();
                    calculate_vertices_normal_vectors();
                }
            }
        }
}

void MyOffFile::normalize_vertices()
{
    if (number_of_vertices !=0){
        xVerMin = Vertices_Buffer[0][0];
        xVerMax = Vertices_Buffer[0][0];
        yVerMin = Vertices_Buffer[0][1];
        yVerMax = Vertices_Buffer[0][1];
        zVerMin = Vertices_Buffer[0][2];
        zVerMax = Vertices_Buffer[0][2];
        for(int i = 1;i<number_of_vertices;i++){
            if(Vertices_Buffer[i][0]>xVerMax)
                xVerMax = Vertices_Buffer[i][0];
            if(Vertices_Buffer[i][0]<xVerMin)
                xVerMin = Vertices_Buffer[i][0];
            if(Vertices_Buffer[i][1]>yVerMax)
                yVerMax = Vertices_Buffer[i][1];
            if(Vertices_Buffer[i][1]<yVerMin)
                yVerMin = Vertices_Buffer[i][1];
            if(Vertices_Buffer[i][2]>zVerMax)
                zVerMax = Vertices_Buffer[i][2];
            if(Vertices_Buffer[i][2]<zVerMin)
                zVerMin = Vertices_Buffer[i][2];
        }


    globalVerMax = xVerMax;
    globalVerMin = xVerMin;

    if(yVerMax>globalVerMax)
        globalVerMax = yVerMax;
    if(zVerMax>globalVerMax)
        globalVerMax = zVerMax;

    if(yVerMin<globalVerMin)
        globalVerMin = yVerMin;
    if(zVerMin<globalVerMin)
        globalVerMin = zVerMin;

    normalized_Vertices_Buffer = new float*[number_of_vertices];
    for(int i=0;i<number_of_vertices;i++){
        normalized_Vertices_Buffer[i] = new float[3];
    }

    for(int i = 0;i<number_of_vertices;i++){
        normalized_Vertices_Buffer[i][0] = Vertices_Buffer[i][0]/(globalVerMax-globalVerMin);
        normalized_Vertices_Buffer[i][1] = Vertices_Buffer[i][1]/(globalVerMax-globalVerMin);
        normalized_Vertices_Buffer[i][2] = Vertices_Buffer[i][2]/(globalVerMax-globalVerMin);
    }

    globalVerMinNorm = globalVerMin/(globalVerMax-globalVerMin);
    globalVerMaxNorm = globalVerMax/(globalVerMax-globalVerMin);
    }
}

void MyOffFile::calculate_faces_normal_vectors()
{
    Faces_Normal_Vectors_Buffer = new float*[number_of_faces];
    for(int i=0;i<number_of_faces;i++){
        Faces_Normal_Vectors_Buffer[i] = new float[3];
    }
    float vect1[3],vect2[3];
    for(int i=0;i<number_of_faces;i++){
        vect1[0] = normalized_Vertices_Buffer[Faces_Buffer[i][1]][0] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][0];
        vect1[1] = normalized_Vertices_Buffer[Faces_Buffer[i][1]][1] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][1];
        vect1[2] = normalized_Vertices_Buffer[Faces_Buffer[i][1]][2] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][2];

        vect2[0] = normalized_Vertices_Buffer[Faces_Buffer[i][2]][0] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][0];
        vect2[1] = normalized_Vertices_Buffer[Faces_Buffer[i][2]][1] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][1];
        vect2[2] = normalized_Vertices_Buffer[Faces_Buffer[i][2]][2] - normalized_Vertices_Buffer[Faces_Buffer[i][0]][2];

        Faces_Normal_Vectors_Buffer[i][0] = vect1[1]*vect2[2] - vect1[2]*vect2[1];
        Faces_Normal_Vectors_Buffer[i][1] = vect1[2]*vect2[0] - vect1[0]*vect2[2];
        Faces_Normal_Vectors_Buffer[i][2] = vect1[0]*vect2[1] - vect1[1]*vect2[0];
        float d = 0.0;
        for(int j=0; j<3; j++){
                d+=Faces_Normal_Vectors_Buffer[i][j]*Faces_Normal_Vectors_Buffer[i][j];
        }
        d=sqrt(d);
        if(d > 0.0){
            for(int j=0; j<3; j++){
                Faces_Normal_Vectors_Buffer[i][j]/=d;
                //printf("normal: %f\n", p[i]);
            }
        }
    }
}

void MyOffFile::calculate_vertices_normal_vectors()
{
    Vertices_Normal_Vectors_Buffer = new float*[number_of_faces];
    for(int i=0;i<number_of_vertices;i++){
        Vertices_Normal_Vectors_Buffer[i] = new float[3];
    }

    for(int i=0;i<number_of_vertices;i++){
        Vertices_Normal_Vectors_Buffer[i][0] = 0;
        Vertices_Normal_Vectors_Buffer[i][1] = 0;
        Vertices_Normal_Vectors_Buffer[i][2] = 0;
        for(int j=0;j<number_of_faces;j++){
            for(int k=0;k<3;k++){
                if(Faces_Buffer[j][k]==i){
                    Vertices_Normal_Vectors_Buffer[i][0] = Vertices_Normal_Vectors_Buffer[i][0] + Faces_Normal_Vectors_Buffer[j][0];
                    Vertices_Normal_Vectors_Buffer[i][1] = Vertices_Normal_Vectors_Buffer[i][1] + Faces_Normal_Vectors_Buffer[j][1];
                    Vertices_Normal_Vectors_Buffer[i][2] = Vertices_Normal_Vectors_Buffer[i][2] + Faces_Normal_Vectors_Buffer[j][2];
                }
            }
        }

        float d = 0.0;
        for(int j=0; j<3; j++){
                d+=Vertices_Normal_Vectors_Buffer[i][j]*Vertices_Normal_Vectors_Buffer[i][j];
        }
        d=sqrt(d);
        if(d > 0.0){
            for(int j=0; j<3; j++){
                Vertices_Normal_Vectors_Buffer[i][j]/=d;
            }
        }
    }
}

int MyOffFile::get_number_of_vertices()
{
    return number_of_vertices;
}

int MyOffFile::get_number_of_faces()
{
    return number_of_faces;
}

float **MyOffFile::get_Vertices_Buffer()
{
    return Vertices_Buffer;
}

int **MyOffFile::get_Faces_Buffer()
{
    return Faces_Buffer;
}

MyOffFile::~MyOffFile()
{
//    for (int i =0; i < number_of_vertices ; i++)
//    {
//        delete[] Vertices_Buffer[i];
//    }
//    for (int i =0; i < number_of_faces ; i++)
//    {
//        delete[] Faces_Buffer[i];
    //    }
}


float **MyOffFile::get_normalized_Vertices_Buffer()
{
    return normalized_Vertices_Buffer;
}

float **MyOffFile::get_Faces_Normal_Vectors_Buffer()
{
    return Faces_Normal_Vectors_Buffer;
}

float **MyOffFile::get_Vertices_Normal_Vectors_Buffer()
{
    return Vertices_Normal_Vectors_Buffer;
}


float MyOffFile::get_globalVerMaxNorm()
{
    return globalVerMaxNorm;
}

float MyOffFile::get_globalVerMinNorm()
{
    return globalVerMinNorm;
}

float MyOffFile::get_globalVerMax()
{
    return globalVerMax;
}

float MyOffFile::get_globalVerMin()
{
    return globalVerMin;
}
