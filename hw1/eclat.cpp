#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<bitset>
#include<utility>
using namespace std;


class ECLAT{
    private:
        vector< pair< vector<int> , bitset<128> > > input_data;
        double min_sup;
        char * output_file;
        vector< vector<int> > ans;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector< pair< vector<int> , bitset<128> > > &input_data,double min_sup,char* output_file){
            this->min_sup = min_sup;
            this->output_file = output_file;
            this->ans.clear();
            
            this->init(input_data);
        }
        void init(vector< pair< vector<int> , bitset<128> > > &input_data)
        {
            //here we first filter out the un sup data
            for(int i=0;i<input_data.size();i++)
                if(input_data[i].second.count()>this->min_sup)
                    this->input_data.push_back(input_data[i]);
        }
        void freq(pair< vector<int> , bitset<128> > head,int now)
        {
            pair< vector<int> , bitset<128> > temp = head;
            for(int i = now;i<this->input_data.size();i++)
            {
                //this result pass the min sup
                //add to the final ans
                if((head.second & this->input_data[i].second).count() >this->min_sup)
                {
                    temp.first.push_back( this->input_data[i].first[0] );
                    temp.second &= this->input_data[i].second;
                    this->ans.push_back(temp.first);

                    this->freq(temp,i+1);
                }
            }
        }
};

int main(int argc,char * argv[])
{
    int id,i;
    char str[2048];
    char* fir;
    vector< pair< vector<int> , bitset<128> > > data;

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
                data.push_back( make_pair(vector<int>(1,data.size()+1),bitset<128>()));
            
            data[id-1].second.set(i);

            fir = strtok(NULL," ");
        }
        i++;
    }
    
    cout<<data.size()<<endl;
    
    for(int i=0;i<data.size();i++)
    {
        cout<< data[i].first[0] << " " << data[i].second <<endl;
    }
    
   
    double min_sup;
    sscanf(argv[2],"%lf",&min_sup);

    ECLAT eclat(data,min_sup*i,argv[3]);

    pair< vector<int> , bitset<128> > head; 
    eclat.freq(head,0);
   
}