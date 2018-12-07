#include<stdio.h>
#include<vector>

using namespace std;

int main(void)
{
    vector<int> a(1,5);
    for(int i=0;i<a.size();i++)
        printf("%d\n",a[i]);
}