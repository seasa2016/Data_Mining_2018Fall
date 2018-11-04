#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<utility>
#include<algorithm>
#include <time.h>
#include<math.h>

#define block_size 16
#define thread_size 256
using namespace std;


__device__ int bit_count(unsigned int i)
{
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}
__global__ void gpu_inter(unsigned int * query,unsigned int** bank,unsigned int** d_result,int *d_count,int start,int max,int size)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    extern __shared__ unsigned int q[];
    int i,j;
    //move the query on the the sharded memory
    if(tid==0)
        for(i=0;i<max;i++)
            q[i] = query[i];
    __syncthreads();

    //use parella to compute all the result
    for(i=bid*blockDim.x+tid + start ; i<size ; i+= blockDim.x * gridDim.x)
    {
        d_count[i] = 0;
        
        for(j=0;j<max;j++)
        {
            d_result[i][j] = q[j] & bank[i][j];

            d_count[i] += bit_count(d_result[i][j]);
        }
    }
}   


class ECLAT{
    public:
        int min_sup;
        FILE* output;
        unsigned int **d_data;
        unsigned int **h_data;

        unsigned int **data;

        unsigned int **h_result;
        unsigned int **d_result;

        unsigned int *d_query;

        int *h_count;
        int *d_count;

        int *pre;

        int max,size;
        ECLAT(void){
            
        }
        ECLAT(vector< pair< int , vector<int> > > &input_data,int max,double min_sup,char* output_file){
            this->min_sup = int(ceil(min_sup));
            
            this->output = fopen(output_file,"w");
            
            this->max = (max+31)/32;

            this->init(input_data);
        }
        void print(unsigned *x)
        {
            for(int j=0;j<this->max*32;j++)
            {
                if(x[j/32] & 1UL<<(j%32)) printf("1");
                else printf("0");
                
                if(j && j%32==0) printf(" ");
            }
            printf("\n");
            fflush(stdout);
        }
        void init(vector< pair< int , vector<int> > > &input_data)
        {
            //here we first filter out the un sup data
            
            vector< pair<int,unsigned int*> > data_temp;
            
            //finst parsing the data
            for(int i=0;i<input_data.size();i++)
                if(input_data[i].second.size()>=this->min_sup)
                {
                    unsigned int *temp = new unsigned int[this->max];
                    
                    memset(temp,0,this->max*sizeof(int));

                    for(int j=0;j<input_data[i].second.size();j++)
                        temp[input_data[i].second[j]/32] |= (1UL << (input_data[i].second[j]%32));
                    
                    data_temp.push_back( make_pair(input_data[i].first,temp) );
                }
            //put the data into cpu memory
            this->size = data_temp.size();

            this->pre = new int[data_temp.size()];
            this->data = new unsigned int*[data_temp.size()];

            for(int i=0 ; i<data_temp.size() ; i++)
            {
                this->pre[i] = data_temp[i].first;
                this->data[i] = data_temp[i].second;
            }

            //we should alloc all the memory first XD    
            this->h_data  = new unsigned int*[data_temp.size()];
            this->h_result  = new unsigned int*[data_temp.size()];

            //alloc memory to 2d array
            cudaMalloc(&(this->d_data), data_temp.size()*sizeof(unsigned int*)); 
            cudaMalloc(&(this->d_result), data_temp.size()*sizeof(unsigned int*)); 

            cudaMemcpy(this->d_data, this->data,  data_temp.size()*sizeof(unsigned int*), cudaMemcpyHostToDevice);
                
            for(int i=0; i<data_temp.size(); i++){
                //alloc memory to 1d array
                cudaMalloc(&(this->h_data[i]), (this->max)*sizeof(unsigned int));
                cudaMalloc(&(this->h_result[i]), (this->max)*sizeof(unsigned int));

                cudaMemcpy(this->h_data[i], this->data[i],  (this->max)*sizeof(unsigned int) , cudaMemcpyHostToDevice);
                
                cudaMemcpy(&(this->d_data[i]), &(this->h_data[i]), sizeof(unsigned int*), cudaMemcpyHostToDevice);
                cudaMemcpy(&(this->d_result[i]), &(this->h_result[i]), sizeof(unsigned int*), cudaMemcpyHostToDevice);
            }

            cudaMalloc((void**)&(this->d_query), this->max*sizeof(unsigned int));
            cudaMalloc((void**)&(this->d_count), this->size* sizeof(int));  

            printf("max:%d this->size:%d",this->max,this->size);
        }
        // use_gpu( bit , now, result, h_count);
        void use_gpu( unsigned int *query,int now,unsigned int**result,int* h_count)
        {
            //we only copy the data here
            cudaMemcpy(this->d_query, query, this->max*sizeof(unsigned int), cudaMemcpyHostToDevice);

            // gpu_inter(unsigned int * query,unsigned int** bank,unsigned int** d_result,int *d_count,int start,int max,int size)
            gpu_inter<<<block_size,thread_size,0>>>(this->d_query,this->d_data,this->d_result,this->d_count,now,this->max,this->size);
            
            //move result and count back to the cpu
            cudaMemcpy(this->h_result,this->d_result, this->size*sizeof(unsigned int*), cudaMemcpyDeviceToHost);
            for (int i=0; i<this->size; i++)
                cudaMemcpy(result[i],this->h_result[i],  this->size*sizeof(unsigned int), cudaMemcpyDeviceToHost);

            cudaMemcpy(h_count,this->d_count, this->size*sizeof(int), cudaMemcpyDeviceToHost);
        }

        void find(vector<int> &arr,int idx, unsigned int* bit,int now)
        {
            unsigned int** result;
            int* h_count;
            int i;

            while(arr.size()<=idx)
                arr.push_back(0);

            h_count = new int[this->size];
            result = new unsigned int*[this->size];
            for(i=0;i<this->size;i++)
                result[i] = new unsigned int[this->size];

            use_gpu( bit , now, result, h_count);
            
            for(;now<this->size;now++)
            {
                //since we share the memory    
                if( h_count[now] >= this->min_sup)
                {
                    arr[idx] = this->pre[now];
                    for(i=0 ; i<idx+1 ; i++)
                        fprintf(this->output,"%d ",arr[i]+1);
                    fprintf(this->output,"(%d)\n",h_count[now]);

                    find(arr,idx+1,result[now],now+1);
                }
                delete(result[i]);
            }
            delete(result);
            delete(h_count);
        }
        void finish()
        {
            cudaFree(this->d_query);
            cudaFree(this->d_count);  

            for(int i=0; i<this->size; i++){
                cudaFree(this->h_data[i]);
                cudaFree(this->h_result[i]);
            }

            cudaFree(this->d_data); 
            cudaFree(this->d_result); 
        }
};

int main(int argc,char * argv[])
{
    time_t start, end;

    start = clock();
    int id,i;
    char str[4096];
    char* fir;
    vector< pair< int , vector<int> > > data;

    FILE *in;
    //here we first deal with the input data
    i = 0;
    in = fopen(argv[1],"r");
    int max = 0;

    printf("parsing data\n");
    while(fgets(str,4096,in))
    {
        fir = strtok(str," ");
        while(fir != NULL)
        {
            sscanf(fir,"%d",&id);
            while(data.size()<id)
                data.push_back( make_pair(data.size(),vector<int>()));
            
            data[id-1].second.push_back(i);
            if(max<i)
                max=i;

            fir = strtok(NULL," ");
        }
        i++;
    }
   
    double min_sup;
    sscanf(argv[2],"%lf",&min_sup);
    printf("initial\n");
    ECLAT eclat(data,max,min_sup*i,argv[3]);

    pair< vector<int> , unsigned int* > head;

    head.first.clear();
    head.second = new unsigned int[eclat.max];

    printf("eclat.max %d\n",eclat.max);
    for(int i=0;i<eclat.max;i++)
        head.second[i] = 0xFFFFFFFF;
    //cout << head.second;

    printf("find freq\n");
    eclat.find(head.first,0,head.second,0);

    eclat.finish();
    delete(head.second);

    end = clock();


    double diff = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Time = %f\n", diff);
}   
