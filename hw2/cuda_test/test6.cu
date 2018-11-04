#include <stdio.h>
#include<iostream>
#include <vector>

typedef struct {
    int width;
    int height;
    float* elements;
} Matrix;


__global__ void doThings(Matrix* matrices)
{
    printf("?");
    int i = blockIdx.x;
    for(int j=0;j<5;j++)
        printf("-%f-",matrices[i].elements[j]);
    printf("\n");
    
    matrices[i].elements[0] = 42+i;
    matrices[i].elements[3] = 42+i;
}

int main(void) {
    int rows=5, cols=1, numMat = 16; // These are actually determined at run-time
    Matrix* data = (Matrix*)malloc(numMat * sizeof(Matrix));
    for(int i=0;i<numMat;i++)
    {
        data[i].elements = (float*)malloc(sizeof(float)*5);
        for(int j=0;j<5;j++)
            data[i].elements[j] = j;
    }    
    Matrix* d_data;

    // ... Successfully read from file into "data" ...
    Matrix* h_data = (Matrix*)malloc(numMat * sizeof(Matrix));
    
    cudaMalloc(&d_data, numMat*sizeof(Matrix)); 
    cudaMemcpy(d_data, data,  numMat * sizeof(Matrix), cudaMemcpyHostToDevice);
        
    for (int i=0; i<numMat; i++){
        cudaMalloc(&(h_data[i].elements), 5*sizeof(float));
        cudaMemcpy(h_data[i].elements, data[i].elements,  5*sizeof(float), cudaMemcpyHostToDevice);
        
        cudaMemcpy(&(d_data[i].elements), &(h_data[i].elements), sizeof(float*), cudaMemcpyHostToDevice);
        
        
    }// matrix data is now on the gpu, now copy the "meta" data to gpu
    
    
    // ... Do other things ...
    doThings<<<numMat,16,0>>>(d_data);

    cudaMemcpy(h_data,d_data, numMat*sizeof(Matrix), cudaMemcpyDeviceToHost);

    for (int i=0; i<numMat; i++){
        cudaMemcpy(data[i].elements,h_data[i].elements,  rows*cols*sizeof(float), cudaMemcpyDeviceToHost);
     }// matrix data is now on the gpu, now copy the "meta" data to gpu
     

    for(int i=0;i<numMat;i++)
    {
        for(int j=0;j<5;j++)
            printf("%f ",data[i].elements[j]);
        printf("\n");
    }

}