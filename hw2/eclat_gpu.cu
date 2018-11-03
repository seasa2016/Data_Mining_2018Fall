#include"cuda_runtime.h"
#include"cuda.h"
#include"cuda_runtime_api.h"
#include<stdio.h>
#include<string.h>
#include<math.h>
#include<vector>
#include<iostream>
#include<bitset>
#include<utility>
#include<algorithm>
#include <time.h>

#define N 1048576
#define block_size 16
#define thread_size 16

#define cudaCheckErrors(msg) \
    do { \
        cudaError_t __err = cudaGetLastError(); \
        if (__err != cudaSuccess) { \
            fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", \
                msg, cudaGetErrorString(__err), \
                __FILE__, __LINE__); \
            fprintf(stderr, "*** FAILED - ABORTING\n"); \
            exit(1); \
        } \
    } while (0)
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}


using namespace std;


struct Data{
    int now;
    unsigned int *bit;
};
struct Pre{
    unsigned int *val;
    unsigned int *bit;
};
struct stat{
    unsigned int *count;
    unsigned int *val;
};


__device__ int my_push_back(stat *result,unsigned int *data,int size,int count,int bid) 
{
    extern __shared__ int idx;
    printf("my push idx:%d bid:%d\n",idx,bid);
    int insert_idx = atomicAdd(&idx, 1);
    if (insert_idx < N/block_size && insert_idx >=0)
    {
        result[ N/block_size*bid + insert_idx ].count[0] = count;

        memcpy(result[  N/block_size*bid + insert_idx ].val,data,size*sizeof(unsigned int));
        
        return insert_idx;
    }
    else 
    {
        printf("error %d %d\n",bid,insert_idx);
        return -1;
    }
}

__device__ int bit_count(unsigned int i)
{
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}


__device__ void find(Pre *head,Data *data,int i,stat *result,int &max,int &size,int &data_size,int min_sup)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;

    int j;
    int c;


    unsigned int *ori = (unsigned int*)malloc(max*sizeof(unsigned int));
    
    memcpy(ori,head->bit,max*sizeof(unsigned int));
        
    //printf("data_size %d\n",data_size);
    for(;i<data_size;i++)
    {
        //this result pass the min sup
        //add to the final ans
        c = 0;
        for(j=0;j<max;j++)
            c += bit_count( head->bit[j] & data[i].bit[j]);

        printf("(%d,%d) i:%d count:%d min_sup:%d\n",tid,bid,i,c,min_sup);
        if( c > min_sup)
        {
            
            head->val[data[i].now/32] |= (1U << (data[i].now%32));
            for(j=0;j<max;j++)
                head->bit[j] &= data[i].bit[j];
            
            //my_push_back(stat & result,unsigned int *data int size,int count,int bid) 
            my_push_back(result,head->val,size,c,bid);
            
            //find(Pre *head,Data *data,int i,stat *result,int max,int size,int data_size,double min_sup)
            if(1+i<data_size)
                find(head,data,i+1,result,max,size,data_size,min_sup);

            memcpy(head->bit,ori,max*sizeof(unsigned int));

            head->val[data[i].now/32] &= ~(1U << (data[i].now%32));
        }
    }
    free(ori);
}


//we should only pass data and result inside here
__global__ void gpu_find(Data *data,stat *result,int max,int size,int data_size,unsigned int min_sup,int *count)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    
    extern __shared__ int idx;
    idx = 0;
    __syncthreads();
    
    //printf("start:%d %d\n",bid,tid);
    int i,j;
    /*
    if(tid==0 && bid==1)
    {
        for(i=0;i<data_size;i++)
        {
            printf("%d-",data[i].now);
            for(j=0;j<max;j++)
            {
                printf("%u ",data[i].bit[j]);
            }
            printf("\n");
        }
    }
    */
    
    Pre head;
    head.val = new unsigned int[size];
    head.bit = new unsigned int[max];
    memset(head.val,0,size*sizeof(unsigned int));
    
    //printf("size %d max %d data_size %d\n",size,max,data_size);
    for(i=tid*blockDim.x+bid ; i<data_size ; i+= blockDim.x * gridDim.x)
    {
        head.val[data[i].now/32] |= (1U << (data[i].now%32));

        for(j=0;j<max;j++)    
            head.bit[j] = data[i].bit[j];
        
        //find(Pre *head,Data *data,int i,stat *result,int max,int size,int data_size,unsigned int min_sup)
        //find(head,data,i+1,result,max,size,data_size,min_sup);
        
        head.val[data[i].now/32] &= ~(1U << (data[i].now%32));
    }   

    
    __syncthreads();
    
    //printf("finish\n");
    //move the result to the front of each part
    if(tid == 0)
    {
        count[bid] = idx;

        printf("count[%d]:%d\n",bid,count[bid]);
    }
}

class ECLAT{
    private:
        vector< pair< int , vector<int> > > input_data;
        int min_sup;
        FILE* output;

        Data *ori_data;
        
        int count,max,size;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector< pair<  int,vector<int> > > &input_data,double min_sup,char* output_file,int max){
            this->min_sup = (int)(ceil(min_sup));
            printf("this->min_sup %d \n",this->min_sup);
            this->max = (max+31) / 32;
            printf("max: %d\n",this->max);
            this->size = (input_data.size()+31) / 32;
            printf("size: %d\n",this->size);

            this->output = fopen(output_file,"w");

            this->init(input_data);

        }
        void init(vector< pair< int,vector<int> > > &input_data)
        {
            this->ori_data = new Data[input_data.size()];

            //here we first filter out the un sup data
            this->count = 0;
            printf("this->max::%d\n",this->max);
            for(int i=0;i<input_data.size();i++)
            {
                //printf("input_data[%d].second.size() %d\n",i,input_data[i].second.size());
                if(input_data[i].second.size()>this->min_sup)
                {
                    //printf("qq ");
                    this->ori_data[this->count].now = i;
                    this->ori_data[this->count].bit = new unsigned int[this->max];
                    
                    //printf("(%d,%d) ",this->ori_data[this->count].now,input_data[i].second.size());       
                    fprintf(this->output,"%d ",this->ori_data[this->count].now+1);

                    memset(this->ori_data[this->count].bit,0,this->max*sizeof(unsigned int));
                    for(int j=0;j<input_data[i].second.size();j++)
                        this->ori_data[this->count].bit[ input_data[i].second[j] / 32 ] |=  1U << (input_data[i].second[j]%32) ; 

                    fprintf(this->output,"(%lu)\n",input_data[i].second.size());
                    //printf("(%lu)\n",input_data[i].second.size());
                    
                    this->count ++;
                }
            }
            /*
            printf("this->count %d\n",this->count);
            unsigned int temp;
            for(int i=0;i<1;i++)
            {
                printf("%d:\n",i);
                for(int j=0;j<this->max;j++)
                    printf("%u ",this->ori_data[i].bit[j]);
                printf("\n");
            }
            */
        }
        void freq()
        {
            int i,j;
            unsigned int *temp = new unsigned int[this->max];
            memset(temp, 0, this->max * sizeof(unsigned int));
            Data* d_data;
            Data* h_data = new Data[this->count];
            
            stat* d_result;
            stat* h_result = new stat[N];

            memcpy(h_data, this->ori_data, this->count * sizeof(Data));
            memset(h_result, 0, N * sizeof(stat));

            //printf("state 1\n");

            cudaMalloc((void**)&d_data, this->count*sizeof(Data)); 
            cudaMemcpy(d_data, this->ori_data, this->count*sizeof(Data), cudaMemcpyHostToDevice);
            
            for (i=0; i<this->count ; i++){
                cudaMalloc((void**)&(h_data[i].bit), this->max*sizeof(unsigned int));
                cudaMemcpy(h_data[i].bit, this->ori_data[i].bit,  this->max*sizeof(unsigned int), cudaMemcpyHostToDevice);
                cudaMemcpy(&(d_data[i].bit), &(h_data[i].bit),  sizeof(unsigned int*), cudaMemcpyHostToDevice);
            }// matrix data is now on the gpu, now copy the "meta" data to gpu
            

            cudaMalloc((void**)&d_result, N*sizeof(stat)); 
            for (i=0; i<N ; i++){
                cudaMalloc((void**)&(h_result[i].val), this->size*sizeof(unsigned int));
                cudaMemset(h_result[i].val, 0,  this->size*sizeof(unsigned int) );
                cudaMemcpy(&(d_result[i].val), &(h_result[i].val),  sizeof(unsigned int*), cudaMemcpyHostToDevice);
                
                cudaMalloc((void**)&(h_result[i].count), sizeof(unsigned int));
                cudaMemset(h_result[i].count, 0,  sizeof(unsigned int));
                cudaMemcpy(&(d_result[i].count), &(h_result[i].count),  sizeof(unsigned int*), cudaMemcpyHostToDevice);
            }// matrix data is now on the gpu, now copy the "meta" data to gpu

            

            int *d_count;
            int *h_count = new int[block_size];
            cudaMalloc((void**)&d_count, block_size*sizeof(int)); 
            cudaMemset(d_count,0, block_size*sizeof(int));

            printf("this->count:%d\n",this->count);
            //gpu_find(Data *data,stat *result,int max,int size,int data_size,unsigned int min_sup,int *count)
            gpu_find<<<block_size,thread_size>>>(d_data,d_result,this->max,this->size,this->count,this->min_sup,d_count);
            fflush(stdout);
            cudaDeviceSynchronize();
            cudaCheckErrors("???????????????");
            
            cudaMemcpy(h_count,d_count, block_size*sizeof(unsigned int), cudaMemcpyDeviceToHost);
            
            stat *ans = new stat[N];
            cudaMemcpy(h_result , d_result, N*sizeof(stat), cudaMemcpyDeviceToHost);

            for(i=0;i<N;i++)
            {
                ans[i].val = new unsigned int[this->size];
                ans[i].count = new unsigned int[1];

                cudaMemcpy(ans[i].val , h_result[i].val, this->size*sizeof(unsigned int), cudaMemcpyDeviceToHost);
                cudaMemcpy(ans[i].count , h_result[i].count, sizeof(unsigned int), cudaMemcpyDeviceToHost);    

                //printf("bit %d %d %d\n",i,ans[i].bit[0],ans[i].count[0]);
            }
            // matrix data is now on the gpu, now copy the "meta" data to gpu

            unsigned int k;
            for(i=0;i<block_size;i++)
            {
                printf("h_count[%d] %d\n",i,h_count[i]);    
                fflush(stdout);   
                for(j=0;j<h_count[i];j++)
                {

                    for(k=0;k<this->size*32;k++)
                    {
                        if( (1U<<(k%32)) & ans[ N/block_size*i + j ].val[k/32])
                        {
                            //printf("%u ",k+1);       
                            fprintf(this->output,"%u ",k+1);
                            fflush(stdout);
                        }
                    }    
                    //printf("(%u)\n",ans[ N/block_size*i + j ].count[0]);
                    fprintf(this->output,"(%u)\n",ans[ N/block_size*i + j ].count[0]);
                    fflush(stdout);
                }
            }
            
            
            printf("before free\n");
            for (int i=0; i<this->count ; i++)
                cudaFree(h_data[i].bit);

            for (int i=0; i<N ; i++)
                cudaFree(h_result[i].val);

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