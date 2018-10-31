#include"cuda_runtime.h"
#include"cuda.h"
#include"cuda_runtime_api.h"
#include<stdio.h>
#include <stdlib.h>  

using namespace std;

__device__ int qq(int x)
{
    if(x==0)
        return 0;
    return x+qq(x-1);
}

__global__ static void sumOfSquares3(int * result)
{
    extern __shared__ int shared[];
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    printf("%d\n",tid*blockDim.x + bid);
    result[tid*blockDim.x + bid] = qq(tid*blockDim.x + bid);
}


int main()
{
    int *result;
    int sum[100] = {0};
    cudaMalloc((void**) &result,sizeof(int)*100);
    
    sumOfSquares3<<<10,10,0>>>(result);
    cudaMemcpy(&sum,result,sizeof(int)*10*10,cudaMemcpyDeviceToHost);
    for(int i=0;i<100;i++)
        printf("-%d\n",sum[i]);
    
    cudaFree(result);
    return 0;
}