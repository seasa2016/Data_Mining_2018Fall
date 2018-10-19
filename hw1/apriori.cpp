#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>
#include<bitset>
#include<utility>
#include<algorithm>
#include<set>
#define bit_size 32

using namespace std;
class APRIORI{
    private:
        vector< bitset<bit_size>  > input_data;
        double min_sup;
        char * output_file;
        vector< pair<vector<int>,int> > ans;
    public:
        APRIORI(void){
            
        }
        APRIORI(vector< bitset<bit_size>  > &input_data,double min_sup,char* output_file){
            this->min_sup = min_sup;
            this->output_file = output_file;
            this->ans.clear();
            
            this->input_data = input_data;
        }

        vector< vector<int> > count(vector< vector<int> > &check_set)
        {
            int num = 0,total=0;
            int size_check = check_set[0].size();
            vector< vector<int> > next;

            for(int i=0;i<check_set.size();i++)
            {
                total = 0;
                for(int k=0 ; k<input_data.size() ; k++)
                {
                    num = 0;
                    for(int j=0;j<check_set[i].size();j++)
                        num += input_data[k][check_set[i][j]];
                    if(num == size_check)
                        total ++;
                }
                //thus satisfied the constrain
                if(total>=min_sup)
                {
                    next.push_back(check_set[i]);
                    ans.push_back(pair<vector<int>,int>(check_set[i],total));
                }
            }

            return next;
        }
        void find(vector< vector<int> > &candidate,vector< vector<int> >&next,vector<int> temp,int idx,int now=0,int max=0)
        {
            if(now==0)
            {
                //printf("-\n");
                int arr[bit_size] = {0};
                for(int i=0;i<temp.size();i++)
                {
                    for(int j=0 ; j<candidate[ temp[i] ].size() ; j++)
                    {
                        //printf("%d ",candidate[ temp[i] ][j]);
                        arr[ candidate[ temp[i] ][j] ] ++;
                    }
                    //printf("\n");
                }
                int num=0;
                vector<int> dummy(max,0);
                for(int i=0;i<bit_size;i++)
                {
                    //printf("%d ",arr[i]);
                    if(arr[i] == max-1)
                    {
                        dummy[num] = i;
                        num++;
                    }   
                }
                //printf("\n");
                //printf("num %d\n",num);
                if(num == max)
                    next.push_back(dummy);
                
                return ;    
            }
            
            int temp_size = temp.size();
            temp.push_back(-1);

            for(int i=idx;i<candidate.size();i++)
            {
                temp[temp_size] = i;
                this->find(candidate,next,temp,i+1,now-1,max);
            }
        }
        vector< vector<int> > merge(vector< vector<int> > &candidate,int now=0)
        {
            vector< vector<int> > next;
            vector<int >temp;
            temp.push_back(-1);

            for(int i=0;i<candidate.size();i++)
            {
                temp[0] = i;

                this->find(candidate,next,temp,i+1,now,now+1);
            }

            return next;
        }
        void freq(vector< vector<int> > &candidate,int now=0)
        {
            //printf("count\n");
            candidate = this->count(candidate);
            //printf("merge\n");

            candidate = this->merge(candidate,now);

            //printf("next\n");
            if(candidate.size())
                this->freq(candidate,now+1);
        }
        void print()
        {
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
    vector< bitset<bit_size> > data;
    set<int> candidate_temp;

    FILE *in;
    //here we first deal with the input data
    i = 0;
    in = fopen(argv[1],"r");
    
    bitset<bit_size> temp;
        
    while(fgets(str,2048,in))
    {
        temp.reset();
        //cout<<str;
        fir = strtok(str," ");
        while(fir != NULL)
        {
            sscanf(fir,"%d",&id);
            
            temp.set(id-1,1);
            
            candidate_temp.insert(id-1);

            fir = strtok(NULL," ");
        }
        data.push_back(temp);
        //cout<<temp<<endl;
        i++;
    }
    
    //here take out the candidate
    
    //printf("********************\n");
    vector< vector<int> > candidate;
    vector<int> member;
    for(set<int>::iterator it=candidate_temp.begin() ; it!=candidate_temp.end() ; it++)
    {
        member.clear();
        member.push_back(*it);
        //printf("%d\n",*it);
        candidate.push_back(member);
    }

    double min_sup;
    sscanf(argv[2],"%lf",&min_sup);

    //printf("1********************\n");
    APRIORI apriori(data,min_sup*i,argv[3]);

    
    //printf("2********************\n");
    //cout << head.second;
    apriori.freq(candidate,1);
    //printf("3********************\n");
    apriori.print();
}