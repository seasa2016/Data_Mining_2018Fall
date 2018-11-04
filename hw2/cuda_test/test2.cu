#include"cuda_runtime.h"
#include"cuda.h"
#include"cuda_runtime_api.h"
#include<stdio.h>
#include <stdlib.h>  

using namespace std;


__global__ static void sumOfSquares()
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    printf("???????");
    //printf("%d %d\n",tid*blockDim.x + bid,result);
}


int main()
{
    int result = 5;
    
    sumOfSquares<<<1,1,0>>>();
    
    for(int i=0;i<1000000;i++)
        for(int j=0;j<10000;j++);
    return 0;
}