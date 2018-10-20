import sys
import time
class APRIORI:
    def __init__(self,file,min_sup,output):
        self.data_set = []
        self.output = output
        
        with open(file) as f:
            for i,line in enumerate(f):
                self.data_set.append(set())
                for num in line.strip().split():
                    self.data_set[i].add(int(num))
        self.min_sup = min_sup * len(self.data_set)
        self.create_C1()
        
    def create_C1(self):
        self.C1 = set()
        for t in self.data_set:
            for item in t:
                item_set = frozenset([item])
                self.C1.add(item_set)


    def is_apriori(self,Ck_item, Lksub1):
        """
        Judge whether a frequent candidate k-itemset satisfy Apriori property.
        Args:
            Ck_item: a frequent candidate k-itemset in Ck which contains all frequent
                    candidate k-itemsets.
            Lksub1: Lk-1, a set which contains all frequent candidate (k-1)-itemsets.
        Returns:
            True: satisfying Apriori property.
            False: Not satisfying Apriori property.
        """
        for item in Ck_item:
            sub_Ck = Ck_item - frozenset([item])
            if sub_Ck not in Lksub1:
                return False
        return True


    def create_Ck(self,Lksub1, k):
        Ck = set()
        len_Lksub1 = len(Lksub1)
        list_Lksub1 = list(Lksub1)
        for i in range(len_Lksub1):
            for j in range(i+1, len_Lksub1):
                l1 = list(list_Lksub1[i])
                l2 = list(list_Lksub1[j])
                l1 = sorted(l1)
                l2 = sorted(l2)

                if l1[:k-2] == l2[:k-2]:
                    Ck_item = list_Lksub1[i] | list_Lksub1[j]
                    # pruning
                    if(self.is_apriori(Ck_item, Lksub1)):
                        Ck.add(Ck_item)
        return Ck


    def generate_Lk_by_Ck(self,Ck):
        Lk = set()
        item_count = {}
        for t in self.data_set:
            for item in Ck:
                if item.issubset(t):
                    try:
                        item_count[item] += 1
                    except KeyError:
                        item_count[item] = 1
        
        for item in item_count:
            if (item_count[item] >= self.min_sup):
                Lk.add(item)
                self.support_data[item] = item_count[item]
        return Lk


    def freq(self):
        self.support_data = {}
        self.create_C1()
        L1 = self.generate_Lk_by_Ck(self.C1)

        Lksub1 = L1.copy()
                
        i = 2
        while(True):
            Ci = self.create_Ck(Lksub1, i)
            Li = self.generate_Lk_by_Ck(Ci)
            if(len(Li) == 0):
                break
            Lksub1 = Li.copy()            
            i += 1
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
    apriori = APRIORI(sys.argv[1],float(sys.argv[2]),sys.argv[3])
    support_data = apriori.freq()
    apriori.print()
    print(time.time()-start)

    