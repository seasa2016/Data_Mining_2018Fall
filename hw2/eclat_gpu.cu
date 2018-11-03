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

#define N 524288LL
#define block_size 16
#define thread_size 16

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
    int *count;
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


__device__ void find(Pre *head,int now,Data *data,int i,stat *result,int max,int size,double min_sup)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    const int total = blockDim.x*gridDim.x;

    extern __shared__ int idx[thread_size];

    int *ori = new int[max];
    int j;
    
    //printf("--at %d %d\n",tid,i);
    for(int j=0;j<max;j++)
    {
        ori[j] = head->bit[j];
    }    
    int count;

    for(;i<size;i++)
    {
        //this result pass the min sup
        //add to the final ans
        count = 0;
        for(j=0;j<max;j++)
        {
            count += bit_count( head->bit[j] & data[i].bit[j]);

        }
        //printf("now: %d i:%d count:%d min_sup:%lf\n",now,i,count,min_sup);
        if( count > min_sup)
        {
            //printf("---%d %d %d\n",tid,now,i);
            head->now[now] = data[i].now;

            for(j=0;j<max;j++)
                head->bit[j] &= data[i].bit[j];
            //printf("---%d %d %d\n",tid,now,i);
                
            //printf("updata %d\n",N/total*(bid*blockDim.x+tid) + idx[tid]);

            //printf("%d\n",tid);
            result[ N/total*(bid*blockDim.x+tid) + idx[tid] ].count[0] = count;
            //printf("%d\n",tid);

            //printf("count %d update %d now: %d\nval ",count,N/total*(bid*blockDim.x+tid) + idx[tid],now);
            for(j=0;j<now+1 ;j++)
            {
                result[ N/total*(bid*blockDim.x+tid) + idx[tid] ].bit[j] = head->now[j];
                printf("%d ",head->now[j]);
            }    
            result[ N/total*(bid*blockDim.x+tid) + idx[tid] ].bit[j] = 0;
            //printf("\n");

            //printf("test i:%d tid:%d idx[tid]:%d\n",i,tid);

            idx[tid] += 1;
            //printf("--%d %d %d\n",tid,now,i);
            
            find(head,now+1,data,i+1,result,max,size,min_sup);

            for(j=0;j<size;j++)
                head->bit[j] = ori[j];
        }
    }
    delete ori;
}

//we should only pass data and result inside here
__global__ static void gpu_find(Data *data,stat *result,int max,int size,double min_sup,int *count)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    const int total = blockDim.x*gridDim.x;
        
    extern __shared__ int idx[thread_size];

    
    int i,j,k;
    unsigned int temp;
    for(i=0;i<size;i++)
    {
        //printf("%d-",data[i].now);
        for(j=0;j<max;j++)
        {
            temp = data[i].bit[j];
            while(temp)
            {
                //printf("%d",temp%2);
                temp /= 2;
            }
        }
        //printf("\n");
    }

    
    Pre head;
    head.now = new int[size];
    head.bit = new unsigned int[max];
    
    
    for(i=bid*blockDim.x+tid ; i<size ; i+= blockDim.x * gridDim.x)
    {
        //printf("--%d %d i:%d\n",bid,tid,i);
        head.now[0] = data[i].now;
        for(j=0;j<max;j++)
        {
            head.bit[j] = data[i].bit[j];
        }    
        find(&head,1,data,i+1,result,max,size,min_sup);
    }   

    __syncthreads();
    
    //printf("finish\n");
    //move the result to the front of each part
    if(tid == 0)
    {
        count[bid] = 0;
        //for each thread
        for(i=0;i<blockDim.x;i++)
        {
            for(j=0;j<idx[i];j++)
            {
                //printf("(%d,%d)\n",N/gridDim.x*bid + count[bid] + j,N/total*(bid*blockDim.x+i) + j);
                
                result[ N/gridDim.x*bid + count[bid] + j ].count[0] = result[ N/total*(bid*blockDim.x+i) + j ].count[0];
                for(k=0;k<size ;k++)
                    result[ N/gridDim.x*bid + count[bid] + j ].bit[k] = result[ N/total*(bid*blockDim.x+i) + j ].bit[k];
            }

            count[bid] += idx[i];
        }
        //printf("%d count %d\n",bid,count[bid]);
            
    }
}

class ECLAT{
    private:
        vector< pair< int , vector<int> > > input_data;
        double min_sup;
        FILE* output;

        Data *ori_data;
        
        int count,max,size;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector< pair<  int,vector<int> > > &input_data,double min_sup,char* output_file,int max){
            this->min_sup = min_sup;
            
            this->max = (max+31) / 32;
            printf("max: %d\n",this->max);
            this->size = input_data.size();

            this->output = fopen(output_file,"w");

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
                    this->ori_data[this->count].bit = new unsigned int[this->max];
                    
                    //printf("%d ",this->ori_data[this->count].now);       
                    fprintf(this->output,"%d ",this->ori_data[this->count].now+1);

                    memset(this->ori_data[this->count].bit,0,this->max*sizeof(int));
                    for(int j=0;j<input_data[i].second.size();j++)
                    {
                        this->ori_data[this->count].bit[ input_data[i].second[j] / 32 ] |=  1 << (input_data[i].second[j]%32) ; 

                    }    

                    fprintf(this->output,"(%lu)\n",input_data[i].second.size());
                    //printf("(%lu)\n",input_data[i].second.size());
                    
                    this->count ++;
                }
            }
            /*
            unsigned int temp;
            for(int i=0;i<this->count;i++)
            {
                printf("%d:",this->ori_data[i].now);
                for(int j=0;j<this->max;j++)
                {
                    temp = this->ori_data[i].bit[j];
                    while(temp)
                    {
                        printf("%u",temp%2);
                        temp = temp/2;
                    }
                    printf(" ");
                }    
                printf("\n");
            }
            */
                    
        }
        void freq()
        {
            int i,j,k;
            Data* d_data;
            Data* h_data = (Data*)malloc(this->count * sizeof(Data));
            
            stat* d_result;
            stat* h_result = (stat*)malloc(N * sizeof(stat));

            memcpy(h_data, this->ori_data, this->count * sizeof(Data));
            memset(h_result, 0, N * sizeof(stat));

            //printf("state 1\n");

            for (i=0; i<this->count ; i++){
                cudaMalloc(&(h_data[i].bit), this->max*sizeof(int));
                cudaMemcpy(h_data[i].bit, this->ori_data[i].bit,  this->max*sizeof(int), cudaMemcpyHostToDevice);

            }// matrix data is now on the gpu, now copy the "meta" data to gpu
            for (i=0; i<N ; i++){
                cudaMalloc(&(h_result[i].bit), this->size*sizeof(int));
                cudaMemset(h_result[i].bit, 0,  this->size*sizeof(int) );
                
                cudaMalloc(&(h_result[i].count), sizeof(int));
                cudaMemset(h_result[i].count, 0,  sizeof(int));
            }// matrix data is now on the gpu, now copy the "meta" data to gpu

            cudaMalloc(&d_data, this->count*sizeof(Data)); 
            cudaMemcpy(d_data, h_data, this->count*sizeof(Data), cudaMemcpyHostToDevice);
            cudaMalloc(&d_result, N*sizeof(stat)); 
            cudaMemcpy(d_result, h_result, N*sizeof(stat), cudaMemcpyHostToDevice);

            int *d_count;
            int h_count[block_size];
            cudaMalloc(&d_count, block_size*sizeof(int)); 
            cudaMemset(d_count,0, block_size*sizeof(int));

            //gpu_find(Data *data,stat *result,int max,int size,double min_sup,int *count)
            gpu_find<<<block_size,thread_size,0>>>(d_data,d_result,this->max,this->size,this->min_sup,d_count);
            //printf("after in\n");
            cudaMemcpy(h_count,d_count, block_size*sizeof(int), cudaMemcpyDeviceToHost);
            //printf("count in\n");
            //while(1);
            
            stat *ans = new stat[N];
            cudaMemcpy(h_result , d_result, N*sizeof(stat), cudaMemcpyDeviceToHost);
            //printf("----%d\n",N);


            for(i=0;i<N;i++)
            {
                ans[i].bit = new int[this->size];
                ans[i].count = new int[1];
                cudaMemcpy(ans[i].bit , h_result[i].bit, this->size*sizeof(int), cudaMemcpyDeviceToHost);
                cudaMemcpy(ans[i].count , h_result[i].count, sizeof(int), cudaMemcpyDeviceToHost);    

                //printf("bit %d %d %d\n",i,ans[i].bit[0],ans[i].count[0]);
            }
            // matrix data is now on the gpu, now copy the "meta" data to gpu

            
            for(i=0;i<block_size;i++)
            {
                fflush(stdout);
                for(j=0;j<h_count[i];j++)
                {

                    for(k=0;k<this->size;k++)
                    {
                        if( k>0 && ans[ N/block_size*i + j ].bit[k] == 0)
                            break;

                        //printf("%u ",ans[ N/block_size*i + j ].bit[k]+1);       
                        fprintf(this->output,"%u ",ans[ N/block_size*i + j ].bit[k]+1);
                        fflush(stdout);
                    }    
                    fprintf(this->output,"(%d)\n",ans[ N/block_size*i + j ].count[0]);
                    //printf("(%d)\n",ans[ N/block_size*i + j ].count[0]);
                    fflush(stdout);
                }
            }
            
            
            printf("before free\n");
            for (int i=0; i<this->count ; i++)
                cudaFree(h_data[i].bit);

            for (int i=0; i<N ; i++)
                cudaFree(h_result[i].bit);

            cudaFree(d_data); 
            cudaFree(d_result); 
            cudaFree(d_count);
            printf("finish\n");
            
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
    printf("test1\n");
    eclat.freq();
    printf("test2\n");
    end = clock();

    double diff = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Time = %f\n", diff);
}   