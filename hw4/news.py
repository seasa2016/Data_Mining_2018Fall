import sklearn
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

data = pd.read_csv('./news/news_train.csv',header=None)
training_data,training_label = data[list(range(23909))].values,data[(23909)].values.astype(np.int)

X_train, X_test, y_train, y_test = train_test_split(training_data, training_label, test_size=0.2, random_state=42)

from sklearn.naive_bayes import GaussianNB
gnb = GaussianNB()
y_pred = gnb.fit(X_train, y_train).predict(X_test)
print("error rate dev GaussianNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import MultinomialNB
mnb = MultinomialNB()
y_pred = mnb.fit(X_train, y_train).predict(X_test)
print("error rate dev MultinomialNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import ComplementNB
cnb = ComplementNB()
y_pred = cnb.fit(X_train, y_train).predict(X_test)
print("error rate dev ComplementNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn.naive_bayes import BernoulliNB
bnb = BernoulliNB()
y_pred = bnb.fit(X_train, y_train).predict(X_test)
print("error rate dev BernoulliNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

from sklearn import tree
t = tree.DecisionTreeClassifier(criterion='gini', max_depth=80, min_samples_split=2,
                                  min_samples_leaf =2,min_weight_fraction_leaf=0.0, 
                                  random_state=None, max_leaf_nodes=200,class_weight=None)

y_pred = t.fit(training_data, training_label).predict(training_data)
print("error rate dev DecisionTreeClassifier {0}".format((training_label == y_pred).sum()/training_data.shape[0] ))


data = pd.read_csv('./news/news_test.csv',header=None)
testing_data,testing_label = data[list(range(23909))].values,data[(23909)].values.astype(np.int)


y_pred = t.predict(testing_data)
print("error rate DecisionTreeClassifier {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ))

y_pred = gnb.predict(testing_data)
print("error rate GaussianNB {0}".format(1-(testing_label != y_pred).sum()/testing_label.shape[0] ))

y_pred = mnb.predict(testing_data)
print("error rate MultinomialNB {0}".format(1-(testing_label != y_pred).sum()/testing_label.shape[0] ))

y_pred = cnb.predict(testing_data)
print("error rate ComplementNB {0}".format(1-(testing_label != y_pred).sum()/testing_label.shape[0] ))

y_pred = bnb.predict(testing_data)
print("error rate BernoulliNB {0}".format(1-(testing_label != y_pred).sum()/testing_label.shape[0] ))

















