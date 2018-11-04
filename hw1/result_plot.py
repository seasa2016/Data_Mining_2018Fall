import matplotlib.pyplot as plt

x = [0.35,0.3,0.25,0.2,0.15,0.1, 0.05]
y = [0.088667,0.090923,0.139513,0.881793,2.057519,11.053780,81.432073]
plt.plot(x,y,'r',label='eclat')

x = [0.35,0.3,0.25,0.2]
y = [2.544534683227539,5.843411207199097,13.965424537658691,473.8437588214874]

plt.plot(x,y,'b',label='apriori')
plt.legend(loc='upper right')
plt.show()