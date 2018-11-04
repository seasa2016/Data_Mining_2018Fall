#define DATA_SIZE 200000000
#include"cuda_runtime.h"
#include"cuda.h"
#include"cuda_runtime_api.h"
#include<stdio.h>
#include <stdlib.h>  

using namespace std;

int data[DATA_SIZE];

void GenerateNumber(int *number,int size)
{
    printf("number: ");
    for(int i=0 ; i<size ; i++)
    {
        number[i] = rand()%10;
        //printf("%d ",number[i]);
    }
}


__device__ void qq()
{
    extern __shared__ int shared[][1];
    const int tid = threadIdx.x;
    if(tid==0){
        for(int i=1;i<blockDim.x;i++)
            shared[0][0] += shared[i][0];
    }
}
__global__ static void sumOfSquares(int *num,int * result)
{
    extern __shared__ int shared[][1];
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    int sum = 0;
    int i;

    for(i=bid*blockDim.x+tid ; i<DATA_SIZE ; i+= blockDim.x * gridDim.x)
        sum += num[i]*num[i];
    shared[tid][0] = sum;
    __syncthreads();

    qq();

    result[bid] = shared[0][0];
}


int main()
{
    GenerateNumber(data,DATA_SIZE);
    
    int sum[100] = {0};
    
    clock_t begin_time = clock();
    for(int i=0;i<DATA_SIZE;i++)
        sum[0] += data[i] * data[i];
    printf("time: %f\n",float( clock () - begin_time ) /  CLOCKS_PER_SEC);
    printf("sum:%d\n",sum[0]);

    int *gpudata, *result;
    
    

    cudaMalloc((void**) &gpudata,sizeof(int)*DATA_SIZE);
    cudaMalloc((void**) &result,sizeof(int)*100);
    
    cudaMemcpy(gpudata,data,sizeof(int)*DATA_SIZE,cudaMemcpyHostToDevice);
    
    begin_time = clock();
    sumOfSquares<<<10,10,0>>>(gpudata,result);
    cudaMemcpy(&sum,result,sizeof(int)*1*1,cudaMemcpyDeviceToHost);
    printf("sum:%d\n",sum[0]);
    printf("---0time: %f\n",float( clock () - begin_time ) /  CLOCKS_PER_SEC);
    

    cudaFree(gpudata);
    cudaFree(result);
    return 0;
}