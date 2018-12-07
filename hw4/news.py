import sklearn
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
import sys
from sklearn.naive_bayes import ComplementNB,GaussianNB,MultinomialNB,BernoulliNB



data = pd.read_csv(sys.argv[2],header=None)
training_data,training_label = data[list(range(23909))].values,data[(23909)].values.astype(np.int)

X_train, X_test, y_train, y_test = train_test_split(training_data, training_label, test_size=0.2, random_state=42)

if(sys.argv[1] == 'N'):
    """
    task = 'GaussianNB'
    model = GaussianNB()
    y_pred = model.fit(X_train, y_train).predict(X_test)
    print("error rate dev GaussianNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

    task = 'MultinomialNB'
    model = MultinomialNB()
    y_pred = model.fit(X_train, y_train).predict(X_test)
    print("error rate dev MultinomialNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))

    task = 'BernoulliNB'
    model = BernoulliNB()
    y_pred = model.fit(X_train, y_train).predict(X_test)
    print("error rate dev BernoulliNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))
    """

    task = 'ComplementNB'
    model = ComplementNB()
    y_pred = model.fit(X_train, y_train).predict(X_test)
    print("error rate dev ComplementNB {0}".format(1-(y_test != y_pred).sum()/y_test.shape[0] ))
elif(sys.argv[1] == 'D'):
    from sklearn import tree
    task = 'DecisionTree'
    model = tree.DecisionTreeClassifier(criterion='gini', max_depth=80, min_samples_split=2,
                                    min_samples_leaf =2,min_weight_fraction_leaf=0.0, 
                                    random_state=None, max_leaf_nodes=200,class_weight=None)

    y_pred = model.fit(training_data, training_label).predict(training_data)
    print("error rate dev DecisionTreeClassifier {0}".format((training_label == y_pred).sum()/training_data.shape[0] ))


data = pd.read_csv(sys.argv[3],header=None)
testing_data,testing_label = data[list(range(23909))].values,data[(23909)].values.astype(np.int)

y_pred = model.predict(testing_data)
print("error rate {1} {0}".format((testing_label == y_pred).sum()/testing_label.shape[0] ,task))

with open(sys.argv[4],'w') as f:
    for num in y_pred:
        f.write('{0}\n'.format(num))