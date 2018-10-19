#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<bitset>
#include<utility>
#include<algorithm>
#define bit_size 512
using namespace std;



class ECLAT{
    private:
        vector< pair< vector<int> , bitset<bit_size> > > input_data;
        double min_sup;
        char * output_file;
        vector< pair<vector<int>,int> > ans;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector< pair< vector<int> , bitset<bit_size> > > &input_data,double min_sup,char* output_file){
            this->min_sup = min_sup;
            this->output_file = output_file;
            this->ans.clear();
            
            this->init(input_data);
        }
        void init(vector< pair< vector<int> , bitset<bit_size> > > &input_data)
        {
            //here we first filter out the un sup data
            for(int i=0;i<input_data.size();i++)
                if(input_data[i].second.count()>this->min_sup)
                {
                    this->input_data.push_back(input_data[i]);
                    //printf("min %d\n",input_data[i].first[0]);
                }
        }
        void find(pair< vector<int> , bitset<bit_size> > head,int now)
        {
            /*
            printf("\n******************\n");
            printf("now:%d\nhead: ",now);
            for(int i=0;i<head.first.size();i++)
                printf("%d ",head.first[i]);
            printf("\n");
            */

            int count;
            for(int i = now;i<this->input_data.size();i++)
            {
                //printf("%d %d\n",now,i);
                pair< vector<int> , bitset<bit_size> > temp = head;
                //this result pass the min sup
                //add to the final ans
                count = (head.second & this->input_data[i].second).count();
                if( count > this->min_sup)
                {
                    temp.first.push_back( this->input_data[i].first[0] );
                    temp.second &= this->input_data[i].second;
                    this->ans.push_back(pair< vector<int>,int>(temp.first,count));
                    
                    /*
                    printf("next ");
                    for(int j=0;j<temp.first.size();j++)
                        printf("%d ",temp.first[j]);
                    printf("\n");
                    */

                    this->find(temp,i+1);
                }
            }
        }

        void freq(pair< vector<int> , bitset<bit_size> > head)
        {
            this->find(head,0);

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
    int id,i;
    char str[2048];
    char* fir;
    vector< pair< vector<int> , bitset<bit_size> > > data;

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
                data.push_back( make_pair(vector<int>(1,data.size()+1),bitset<bit_size>()));
            
            data[id-1].second.set(i);

            fir = strtok(NULL," ");
        }
        i++;
    }
    /*
    cout<<data.size()<<endl;
    
    for(int i=0;i<data.size();i++)
    {
        printf("%3d ",data[i].first[0]);
        cout<< data[i].second <<endl;
    }
    */
   
    double min_sup;
    sscanf(argv[2],"%lf",&min_sup);

    ECLAT eclat(data,min_sup*i,argv[3]);

    pair< vector<int> , bitset<bit_size> > head; 
    
    head.first.clear();
    head.second.set();
    //cout << head.second;
    eclat.freq(head);
   
}