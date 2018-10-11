#include<stdio.h>
#include<vector>
#include<algorithm>
using namespace std;

bool myfunction(vector<int> &i,vector<int> &j)
{
    if(i.size() != j.size())
        return i.size()>j.size();
    for(int id =0;id<i.size();id++)
        if(i[id] != j[id])
            return i[id] < j[id];
    return 1 == 1;
}
int main(void)
{
    vector< vector<int> > temp;
    temp.push_back(vector<int>());
    temp.push_back(vector<int>());
    temp.push_back(vector<int>());

    temp[0].push_back(0);
    temp[0].push_back(3);
    temp[0].push_back(2);

    temp[1].push_back(0);
    temp[1].push_back(1);

    temp[2].push_back(0);
    temp[2].push_back(1);
    temp[2].push_back(2);

    for(int i=0;i<temp.size();i++)
    {
        for(int j=0;j<temp[i].size();j++)
            printf("%d ",(temp[i][j]));
        printf("\n");
    }
    sort(temp.begin(),temp.end(),myfunction);

    for(int i=0;i<temp.size();i++)
    {
        for(int j=0;j<temp[i].size();j++)
            printf("%d ",(temp[i][j]));
        printf("\n");
    }
}