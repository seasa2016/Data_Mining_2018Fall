
#include <iostream>
#include <cuda.h>
#include <cuda_runtime.h>
#include<vector>
#include<thrust/sort.h>
#include<thrust/device_vector.h>


__global__ static void sumOfSquares3(thrust::device_vector<int> * vec)
{
    extern __shared__ int shared[];
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    vec->push_back(tid*blockDim.x + bid);
    
}

int main(void)
{
    thrust::device_vector<int> b;
    sumOfSquares3<<<10,10,0>>>(&b);

    std::vector<int> c(b.size());

    thrust::copy(b.begin(),b.end(),c.begin());
    for(int i=0;i<c.size();i++)
        printf("%d\n",c[i]);
}