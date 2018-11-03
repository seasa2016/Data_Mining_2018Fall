#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<utility>
#include<algorithm>
#include <time.h>
#include<math.h>

#define block_size 16
#define thread_size 16
using namespace std;


__device__ int bit_count(unsigned int i)
{
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}
__global__ void gpu_inter(unsigned int * d_vec_x,unsigned int * d_vec_y,unsigned int * d_result,int *d_count,int max)
{
    const int tid = threadIdx.x;
    const int bid = blockIdx.x;
    __shared__ int sum[thread_size];
    int i;

    sum[tid] = 0;
    for(i=bid*blockDim.x+tid ; i<max ; i+= blockDim.x * gridDim.x)
    {
        d_result[i] = d_vec_x[i] & d_vec_y[i];
        sum[tid] += bit_count(d_result[i]);
    }

    __syncthreads();
    
    if(tid == 0)
    {
        d_count[bid] = 0;
        for(i=0;i<blockDim.x;i++)
            d_count[bid] += sum[i];
    }    
}   


class ECLAT{
    public:
        vector< pair<int, unsigned int*> > input_data;
        int min_sup;
        FILE* output;
        vector< pair<vector<int>,int> > ans;

        int max,size;
        ECLAT(void){
            
        }
        ECLAT(vector< pair< int , vector<int> > > &input_data,int max,double min_sup,char* output_file){
            this->min_sup = int(ceil(min_sup));
            
            this->output = fopen(output_file,"w");
            
            this->ans.clear();
            
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
            unsigned int qq;
            for(int i=0;i<input_data.size();i++)
                if(input_data[i].second.size()>=this->min_sup)
                {
                    unsigned int *temp = new unsigned int[this->max];
                    
                    memset(temp,0,this->max*sizeof(int));

                    //printf("(%d %d)\n",input_data[i].first,input_data[i].second.size());
                    for(int j=0;j<input_data[i].second.size();j++)
                        temp[input_data[i].second[j]/32] |= (1UL << (input_data[i].second[j]%32));
                    
                    //printf("%3d:",input_data[i].first);
                    //print(temp);

                    this->input_data.push_back( make_pair(input_data[i].first,temp) );
                }
            printf("max:%d this->input_data:%d",this->max,this->input_data.size());
        }
        pair<int, unsigned int*> use_gpu( unsigned int *x , unsigned int *y)
        {
            unsigned int *d_vec_x;
            unsigned int *d_vec_y;

            unsigned int *d_result;
            int *d_count;

            //print(x);
            //print(y);
            

            //move to gpu
            cudaMalloc((void**)&d_vec_x, this->max*sizeof(unsigned int)); 
            cudaMemcpy(d_vec_x, x, this->max*sizeof(unsigned int), cudaMemcpyHostToDevice);

            cudaMalloc((void**)&d_vec_y, this->max*sizeof(unsigned int)); 
            cudaMemcpy(d_vec_y, y, this->max*sizeof(unsigned int), cudaMemcpyHostToDevice);
            
            cudaMalloc((void**)&d_result, this->max*sizeof(unsigned int)); 
            cudaMemset(d_result, 0, this->max*sizeof(unsigned int));

            cudaMalloc((void**)&d_count,block_size* sizeof(int)); 
            cudaMemset(d_count, 0, block_size*sizeof(int));


            gpu_inter<<<block_size,thread_size,0>>>(d_vec_x,d_vec_y,d_result,d_count,this->max);
            
            //move to cpu
            unsigned int *h_result = new unsigned int[this->max];
            int *h_count = new int[block_size];


            cudaMemcpy(h_result,d_result, this->max*sizeof(unsigned int), cudaMemcpyDeviceToHost);
            cudaMemcpy(h_count,d_count, block_size*sizeof(int), cudaMemcpyDeviceToHost);

            int count = 0;
            for(int i=0;i<block_size;i++)
                count += h_count[i];
                    

            //count = count/0;
            cudaFree(d_result);
            cudaFree(d_vec_x);
            cudaFree(d_vec_y);
            cudaFree(d_count);

            delete(h_count);

            return pair<int, unsigned int*>(count,h_result);
        }

        void find(vector<int> &arr,int idx, unsigned int* bit,int now)
        {
            pair<int, unsigned int*> result;
            
            while(arr.size()<=idx)
                arr.push_back(0);

            for(;now<this->input_data.size();now++)
            {
                //this result pass the min sup
                //add to the final ans

                result = use_gpu( bit , this->input_data[now].second);
                if( result.first >= this->min_sup)
                {
                    //printf("(%d %d %d)\n",idx,i,result.first);
                    arr[idx] = this->input_data[now].first;
                    
                    //this->ans.push_back(pair< vector<int>,int>(arr,result.first));
                    
                    for(int i=0 ; i<idx+1 ; i++)
                        fprintf(output,"%d ",arr[i]+1);
                    fprintf(output,"(%d)\n",result.first);
                    
                    this->find(arr,idx+1,result.second,now+1);
                }
                delete(result.second);
            }
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
    delete(head.second);

    end = clock();


    double diff = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Time = %f\n", diff);
}   