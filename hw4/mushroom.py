import sklearn
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

data = pd.read_csv('./mushroom/mushroom_train.csv',header=None)
training_data,training_label = data[ (list(range(10)) + list(range(11,15)) + list(range(16,22))) ].values,data[(22)].values.astype(np.int)
temp = training_data.copy()

name = [
['b','c','x','f','k','s'],
['f','g','y','s'],
['n','b','c','g','r','p','u','e','w','y'],
['t','f'],
['a','l','c','y','f','m','n','p','s'],
['a','d','f','n'],
['c','w','d'],
['b','n'],
['k','n','b','h','g','r','o','p','u','e','w','y'],
['e','t'],
['f','y','k','s'],
['f','y','k','s'],
['n','b','c','g','o','p','e','w','y'],
['n','b','c','g','o','p','e','w','y'],
['n','o','w','y'],
['n','o','t'],
['c','e','f','l','n','p','s','z'],
['k','n','b','h','r','o','u','w','y'],
['a','c','n','s','v','y'],
['g','l','m','p','u','w','d']]

mapping = {}
for i in range(len(name)):
    for t in name[i]:
        mapping['{0}_{1}'.format(i,t)] = len(mapping)

temp = np.zeros((training_data.shape[0],len(mapping)))

for i in range(training_data.shape[0]):
    for j in range(training_data.shape[1]):
        idx = '{0}_{1}'.format(j,training_data[i][j])
        
        temp[i][mapping[idx]] = 1

X_train, X_test, y_train, y_test = train_test_split(temp, training_label, test_size=0.2, random_state=42)
prior = [860/(860+764),764/(860+764)]

from sklearn.naive_bayes import GaussianNB
gnb = GaussianNB(priors=prior)
y_pred = gnb.fit(X_train, y_train).predict(X_test)
print("error rate dev GaussianNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import MultinomialNB
mnb = MultinomialNB(class_prior=prior)
y_pred = mnb.fit(X_train, y_train).predict(X_test)
print("error rate dev MultinomialNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import ComplementNB
cnb = ComplementNB(class_prior=prior)
y_pred = cnb.fit(X_train, y_train).predict(X_test)
print("error rate dev ComplementNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import BernoulliNB
bnb = BernoulliNB(class_prior=prior)
y_pred = bnb.fit(X_train, y_train).predict(X_test)
print("error rate dev BernoulliNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.tree import DecisionTreeClassifier,export_graphviz
t = DecisionTreeClassifier(criterion='gini', max_depth=40, min_samples_split=2,
                                  min_samples_leaf =1, min_weight_fraction_leaf=0.0, max_features=None, 
                                  random_state=None, max_leaf_nodes=100,class_weight=None)

y_pred = t.fit(X_train, y_train).predict(X_train)
y_pred = t.predict(X_test)
print("error rate dev DecisionTreeClassifier {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))



#################################################################
data = pd.read_csv('./mushroom/mushroom_test.csv',header=None)
testing_data,testing_label = data[ ( list(range(10)) + list(range(11,15)) + list(range(16,22))) ].values,data[22].values.astype(np.int)


temp = np.zeros((testing_data.shape[0],X_train.shape[1]))
for i in range(testing_data.shape[0]):
    for j in range(testing_data.shape[1]):
        now = '{0}_{1}'.format(j,testing_data[i][j])
        temp[i][mapping[now]] = 1
        
testing_data = temp.copy()

y_pred = t.predict(testing_data)
print("error rate DecisionTreeClassifier {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))

y_pred = gnb.predict(testing_data)
print("error rate GaussianNB {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))

y_pred = mnb.predict(testing_data)
print("error rate MultinomialNB {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))

y_pred = cnb.predict(testing_data)
print("error rate ComplementNB {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))

y_pred = bnb.predict(testing_data)
print("error rate BernoulliNB {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))
