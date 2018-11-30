import sklearn
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

data = pd.read_csv('./income/income_train.csv',header=None)

for idx in [1,3,5,6,7,8,9,13]:    
    m = data[idx].value_counts().index[0]
    data[idx] = data[idx].apply(lambda x: m if('?' in x) else x)
    
training_data,training_label = data[ (list(range(14)))].values,data[(14)].values.astype(np.int)
temp = training_data.copy()

name = [
[],
['Private', 'Self-emp-not-inc', 'Self-emp-inc', 'Federal-gov', 'Local-gov', 'State-gov', 'Without-pay', 'Never-worked'],
[],
['Bachelors', 'Some-college', '11th', 'HS-grad', 'Prof-school', 'Assoc-acdm', 'Assoc-voc', '9th', '7th-8th', '12th', 'Masters', '1st-4th', '10th', 'Doctorate', '5th-6th', 'Preschool'],
[],
['Married-civ-spouse', 'Divorced', 'Never-married', 'Separated', 'Widowed', 'Married-spouse-absent', 'Married-AF-spouse'],
['Tech-support', 'Craft-repair', 'Other-service', 'Sales', 'Exec-managerial', 'Prof-specialty', 'Handlers-cleaners', 'Machine-op-inspct', 'Adm-clerical', 'Farming-fishing', 'Transport-moving', 'Priv-house-serv', 'Protective-serv', 'Armed-Forces'],
['Wife', 'Own-child', 'Husband', 'Not-in-family', 'Other-relative', 'Unmarried'],
['White', 'Asian-Pac-Islander', 'Amer-Indian-Eskimo', 'Other', 'Black'],
['Female', 'Male'],
[],
[],
[],   
['United-States', 'Cambodia', 'England', 'Puerto-Rico', 'Canada', 'Germany', 'Outlying-US(Guam-USVI-etc)', 'India', 'Japan', 'Greece', 'South', 'China', 'Cuba', 'Iran', 'Honduras', 'Philippines', 'Italy', 'Poland', 'Jamaica', 'Vietnam', 'Mexico', 'Portugal', 'Ireland', 'France', 'Dominican-Republic', 'Laos', 'Ecuador', 'Taiwan', 'Haiti', 'Columbia', 'Hungary', 'Guatemala', 'Nicaragua', 'Scotland', 'Thailand', 'Yugoslavia', 'El-Salvador', 'Trinadad&Tobago', 'Peru', 'Hong', 'Holand-Netherlands']
]

mapping = {}
for i in range(len(name)):
    for t in name[i]:
        mapping['{0}_ {1}'.format(i,t)] = len(mapping)

temp = np.zeros((training_data.shape[0],len(mapping)+6))

now = len(mapping)
for j in range(training_data.shape[1]):
    if(name[j] == []):
        for i in range(training_data.shape[0]):
            temp[i][now] = training_data[i][j]
        now += 1
    else:
        for i in range(training_data.shape[0]):
            idx = '{0}_{1}'.format(j,training_data[i][j])
            temp[i][mapping[idx]] = 1

def norm(x,y):
    mean = x.mean(axis=0)
    std = x.std(axis=0)+1e-8
    
    return (x-mean)/std,(y-mean)/std,mean,std

X_train, X_test, y_train, y_test = train_test_split(temp, training_label, test_size=0.2, random_state=42)
X_train_ori, X_test_ori, y_train, y_test = train_test_split(temp, training_label, test_size=0.2, random_state=42)
X_train, X_test,mean,std = norm(X_train, X_test)

prior = [24735/(24735+7827),7827/(24735+7827)]

from sklearn.naive_bayes import GaussianNB
gnb = GaussianNB(priors=prior)
y_pred = gnb.fit(X_train, y_train).predict(X_test)
print("error rate dev GaussianNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import MultinomialNB
mnb = MultinomialNB(class_prior=prior)
y_pred = mnb.fit(X_train_ori, y_train).predict(X_test_ori)
print("error rate dev MultinomialNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import ComplementNB
cnb = ComplementNB(class_prior=prior)
y_pred = cnb.fit(X_train_ori, y_train).predict(X_test_ori)
print("error rate dev ComplementNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import BernoulliNB
bnb = BernoulliNB(class_prior=prior)
y_pred = bnb.fit(X_train, y_train).predict(X_test)
print("error rate dev BernoulliNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn import tree
t = tree.DecisionTreeClassifier(criterion='gini', max_depth=80, min_samples_split=10,
                                  min_samples_leaf =6,min_weight_fraction_leaf=0.0, 
                                  random_state=None, max_leaf_nodes=200,class_weight=None)

y_pred = t.fit(X_train, y_train).predict(X_train)
print("error rate dev DecisionTreeClassifier {0}".format(1-(y_train != y_pred).sum()/y_pred.shape[0] ))
y_pred = t.predict(X_test)
print("error rate DecisionTreeClassifier {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

data = pd.read_csv('./income/income_test.csv',header=None)
testing_data = data[ (list(range(14)))].values

temp = np.zeros((testing_data.shape[0],len(mapping)+6))

now = len(mapping)
for j in range(testing_data.shape[1]):
    if(name[j] == []):
        for i in range(testing_data.shape[0]):
            temp[i][now] = training_data[i][j]
        now += 1
    else:
        for i in range(testing_data.shape[0]):
            idx = '{0}_{1}'.format(j,training_data[i][j])
            temp[i][mapping[idx]] = 1
        
testing_data = temp.copy()
testing_data = (testing_data-mean)/std

y_pred = t.predict(testing_data)

with open('output','w') as f:
    for num in y_pred:
        f.write('{0}\n'.format(num))


