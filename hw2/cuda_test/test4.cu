
#include <iostream>
#include <cuda.h>
#include <cuda_runtime.h>
#include<thrust/sort.h>

int main(void)
{
	int test[] = {1,5,3,4,6,7,9,10};
	for(int i=0;i<8;i++)
		printf("%d\n",test[i]);
	thrust::sort(test,test+8);
	for(int i=0;i<8;i++)
		printf("%d\n",test[i]);
}