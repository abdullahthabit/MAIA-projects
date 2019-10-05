#ifndef MYOFFFILE_H
#define MYOFFFILE_H

#include <string>

using namespace std;
class MyOffFile
{
private:
    float **Vertices_Buffer;
    float ** normalized_Vertices_Buffer;
    float **Faces_Normal_Vectors_Buffer;
    float **Vertices_Normal_Vectors_Buffer;
    int **Faces_Buffer;
    int POINTS_PER_VERTEX;
    int number_of_vertices=0, number_of_faces=0,  number_of_edges=0;
    float xVerMin,xVerMax,yVerMin,yVerMax,zVerMin,zVerMax,globalVerMin,globalVerMax,globalVerMinNorm,globalVerMaxNorm;
public:
    MyOffFile();
    void readOffFile(string file_name);
    void normalize_vertices();
    void calculate_faces_normal_vectors();
    void calculate_vertices_normal_vectors();
    int get_number_of_vertices();
    int get_number_of_faces();
    float** get_Vertices_Buffer();
    float** get_normalized_Vertices_Buffer();
    float **get_Faces_Normal_Vectors_Buffer();
    float **get_Vertices_Normal_Vectors_Buffer();
    int** get_Faces_Buffer();
    float get_globalVerMaxNorm();
    float get_globalVerMinNorm();
    float get_globalVerMax();
    float get_globalVerMin();
    ~MyOffFile();

};

#endif // MYOFFFILE_H
