#include<stdio.h>
#include<string.h>
#include<vector>
#include<iostream>

using namespace std;


class ECLAT{
    private:
        vector<unsigned __int128> input_data;
        double min_sup;
        char * output_file;
    public:
        ECLAT(void){
            
        }
        ECLAT(vector<unsigned __int128> &input_data,double min_sup,char* output_file){
            this->input_data = input_data;
            this->min_sup = min_sup;
            this->output_file = output_file;
        }

        int count(unsigned __int128 x)
        {
            int num = 0;
            while(x)
                if(x%2)
                {
                    num ++;
                    x /= 2;
                }
            return num;
        }

        void freq()
        {
            

        }
};

int main(int argc,char * argv[])
{
    unsigned __int128 temp;
    int id;
    char str[2048];
    char* fir;
    vector<unsigned __int128> data;

    FILE *in;
    //here we first deal with the input data
    in = fopen(argv[1],"r");
    
    while(fgets(str,2048,in))
    {
        temp = 0;
        fir = strtok(str," ");
        while(fir != NULL)
        {
            sscanf(fir,"%d",&id);
            temp ^= 1<<(id-1);
            fir = strtok(NULL," ");
        }
        data.push_back(temp);
    }
    /*
    printf("%d\n",data.size());
    for(int i=0;i<data.size();i++)
    {
        temp = data[i];
        while(temp)
        {
            printf("%d ",temp%2);
            temp = temp/2;
        }
        printf("\n");   
    }
    */
   double min_sup;
   sscanf(argv[2],"%lf",&min_sup);

   ECLAT eclat(data,min_sup,argv[3]);
   eclat.freq();
}