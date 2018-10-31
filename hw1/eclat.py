import sys
import time
class ECLAT:
    def __init__(self,file,min_sup,output):
        self.data_set = []
        self.output = output
        self.support_data = {}
        self.total = set()
        with open(file) as f:
            for i,line in enumerate(f):
                for num in line.strip().split():
                    num = int(num)
                    
                    while(len(self.data_set)<num+1):
                        self.data_set.append(set())
                    
                        
                    self.data_set[num].add(i)
                    self.total.add(i)

        #for i in self.data_set:
        #    print(i)
        self.min_sup = min_sup * len(self.data_set)
        

    def freq(self,value=set(),now=set(),start=0):
        #print('-',value,now,start)
        for i in range(start,len(self.data_set)):
            temp_v = value.copy()
            temp_v = temp_v & self.data_set[i]

            temp_n = now.copy()
            if(len(temp_v) >= self.min_sup):
                temp_n.add(i)
                self.support_data[frozenset(temp_n)] = len(temp_v)
                self.freq(temp_v,temp_n,i+1)

    def print(self):
        with open(self.output,'w') as f:
            for data in self.support_data:
                l_data = list(data)
                l_data = sorted(l_data)
                for num in l_data:
                    f.write("{0} ".format(num))

                f.write("({0})\n".format(self.support_data[data]))

if __name__ == "__main__":
    start = time.time()
    eclat = ECLAT(sys.argv[1],float(sys.argv[2]),sys.argv[3])
    support_data = eclat.freq(eclat.total)
    eclat.print()
    print(time.time()-start)

    