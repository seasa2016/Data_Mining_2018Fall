#include<bitset>
#include<iostream>

using namespace std;
int main(void)
{
    bitset<16> a,b;
    
    a.set();
    b.set(4);

    cout<< (a & b);
    


}