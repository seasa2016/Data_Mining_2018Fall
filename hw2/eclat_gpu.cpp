#include"cuda_runtime.h"
#include"cuda.h"
#include"cuda_runtime_api.h"
#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<bitset>
#include<utility>
#include<algorithm>
#include <time.h>

#define N 16384
#define block_size 16
#define thread_size 1024

using namespace std;


struct Data{
    int now;
    unsigned int *bit;
};
struct Pre{
    int *now;
    unsigned int *bit;
};
struct stat{
    int count;
    int *bit;
};
/*
__device__ int my_push_back(Data & pt,int idx) 
{
    int insert_idx = atomicAdd(&count[idx], 1);
    if (insert_idx < N)
    {
        data[idx][insert_idx] = pt;
        return insert_idx;
    }
    else 
        return -1;
}*/

__device__ int bit_count(int i)
{
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}


__device__ void find(Pre *head,int idx,Data *data,int i,int max,int size,int min_sup)
{
    extern __shared__ stat ans[][thread_size];
    extern __shared__ int idx[];
    const int tid = threadIdx.x;

    int *ori = new int[max];
    int j;
    for(int j=0;j<max;j++)
        ori[j] = head->bit[j];

    int count;
    for(;i<size;i++)
    {
        //this result pass the min sup
        //add to the final ans
        count = 0;
        for(j=0;j<max;j++)
            count += bit_count( head->bit[j] & data[i].bit[j]);

        if( count > min_sup)
        {
            head->now[idx] = data[i].now;

            for(j=0;j<max;j++)
                head->bit[j] &= data[i].bit[j];
    
            ans[idx[tid]][tid].count = count;
            ans[idx[tid]][tid].bit = (int*)malloc(size*sizeof(int));

            for(j=0;j<idx+1;j++)
                ans[idx[tid]][tid].bit[j] = head->now[j];
            atomicAdd(idx[tid]);

            find(head,idx+1,data,i,max,size,min_sup);

            for(j=0;j<idx+1;j++)
                head->bit[j] = ori[j];
        }
    }
    delete ori;
}

//we should only pass data and result inside here
__global__ void gpu_find(Data *data,stat *result,int max,int size,int min_sup)
{
    int count;
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;

    extern __shared__ stat ans[][thread_size];
    extern __shared__ int idx[];

    int i,j,k;

    idx[ tid ] = 0;

    Pre head;
    head.now = new int[size];
    head.bit = new unsigned int[max];

    for(i=bid*blockDim.x+tid ; i<size ; i+= blockDim.x * gridDim.x)
    {
        head.now[0] = data[i].now;
        for(j=0;j<max;j++)
            head.bit[j] = data->bit[j];

        find(&head,1,data,i,max,size,min_sup);
    }   

    __syncthreads();
    int count = 0;
    if(tid==0)
        for(i=0;i<blockDim.x;i++)
            for(j=0;j<idx[i];j++)
            {
                result[count].count = ans[j][i].count;
                for(k=0;k<size;k++)
                    result[count].bit[k] = ans[j][i].bit[k];
                free(ans[j][i].bit);
            }
}

class ECLAT{
    private:
        vector< pair< int , vector<int> > > input_data;
        double min_sup;
        char * output_file;

        Data *ori_data;
        
        int count,max,size;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector< pair<  int,vector<int> > > &input_data,double min_sup,char* output_file,int max){
            this->min_sup = min_sup;
            this->output_file = output_file;
            
            this->max = (max+31) / 32;
            this->size = input_data.size();

            this->init(input_data);
        }
        void init(vector< pair< int,vector<int> > > &input_data)
        {
            this->ori_data = new Data[input_data.size()];

            //here we first filter out the un sup data
            this->count = 0;
            for(int i=0;i<input_data.size();i++)
            {
                if(input_data[i].second.size()>this->min_sup)
                {
                    this->ori_data[this->count].now = i;
                    this->ori_data[this->count].bit = new int[max];

                    for(int j=0;j<input_data[i].second.size();j++)
                        this->ori_data[this->count].bit[ input_data[i].second[j] / 32 ] |=  1 << (input_data[i].second[j]%32) ; 
                    

                    this->count ++;
                }
            }
        }
        void freq()
        {
            Data* d_data;
            Data* h_data = (Data*)malloc(this->count * sizeof(Data));
            memcpy(h_data, this->ori_data, this->count * sizeof(Data));
            for (int i=0; i<this->count ; i++){
                cudaMalloc(&(h_data[i].bit), this->max*sizeof(int));
                cudaMemcpy(h_data[i].bit, this->ori_data[i].bit,  this->max*sizeof(int), cudaMemcpyHostToDevice);
            }// matrix data is now on the gpu, now copy the "meta" data to gpu
            
            
            cudaMalloc(&d_data, this->count*sizeof(Data)); 
            cudaMemcpy(d_data, h_data, this->count*sizeof(Data), cudaMemcpyHostToDevice);
            // ... Do other things ...
            gpu_find<<<block_size,thread_size,0>>>(d_data);

            cudaMemcpy(h_data,d_data, numMat*sizeof(Matrix), cudaMemcpyDeviceToHost);
            for (int i=0; i<numMat; i++)
                cudaMemcpy(data[i].elements,h_data[i].elements,  rows*cols*sizeof(float), cudaMemcpyDeviceToHost);
            // matrix data is now on the gpu, now copy the "meta" data to gpu
            

            for(int i=0;i<numMat;i++)
            {
                for(int j=0;j<5;j++)
                    printf("%f ",data[i].elements[j]);
                printf("\n");
            }


            FILE* output = fopen(this->output_file,"w");
            //here we finish find the ans 
            //next we need to do the sort for the ans
            for(int i=0 ; i<this->ans.size() ; i++)
            {
                for(int j=0;j<this->ans[i].first.size();j++)
                    fprintf(output,"%d ",this->ans[i].first[j]);
                fprintf(output,"(%d)\n",this->ans[i].second);
            }
        }
};

int main(int argc,char * argv[])
{
    time_t start, end;

    start = clock();
    int id,i;
    char str[2048];
    char* fir;
    vector< pair< int , vector<int> > > data;

    FILE *in;
    //here we first deal with the input data
    i = 0;
    in = fopen(argv[1],"r");
    while(fgets(str,2048,in))
    {
        fir = strtok(str," ");
        while(fir != NULL)
        {
            sscanf(fir,"%d",&id);
            

            while(data.size()<id)
                data.push_back( make_pair(data.size()+1,vector<int>()));
            
            data[id-1].second.push_back(i);

            fir = strtok(NULL," ");
        }
        i++;
    }
   
    double min_sup;
    sscanf(argv[2],"%lf",&min_sup);

    ECLAT eclat(data,min_sup*i,argv[3],i);

    eclat.freq();
    end = clock();

    double diff = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Time = %f\n", diff);
}   