import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from bokeh.plotting import figure, output_file, show

usoil = pd.read_csv('NZDUSD1440.csv')
ukoil = pd.read_csv('AUDUSD1440.csv')

usoil.columns = ["date", "time", "price","high", "low", "close", "volume"]
ukoil.columns = ["date", "time", "price" ,"high", "low", "close", "volume"]

count = {}
usprice = {}
ukprice = {}
priceDiff = []
refactoredUsoil = []
refactoredUkoil = []
priceDiffAverage = []

for index, row in usoil.iterrows():
    z = row["date"]
    if z not in count:
        usprice[z] = row["price"]
        count[z] = 1
    else:
        usprice[z] = row["price"]
        count[z] = count[z] + 1

for index, row in ukoil.iterrows():
    z = row["date"]
    if z not in count:
        ukprice[z] = row["price"]
        count[z] = 1
    else:
        ukprice[z] = row["price"]
        count[z] = count[z] + 1

num = 0
DiffAverage = 0

for x in count:
    if count[x] == 2:
        priceDiff.append((x, ukprice[x] - usprice[x]))
        refactoredUsoil.append((x, usprice[x]))
        refactoredUkoil.append((x, ukprice[x]))
        num = num + 1
        DiffAverage = DiffAverage + ukprice[x] - usprice[x]
        priceDiffAverage.append((x, DiffAverage/num))

newData = pd.DataFrame(priceDiff)
newUSOil = pd.DataFrame(refactoredUsoil)
newUKOil = pd.DataFrame(refactoredUkoil)
diffave = pd.DataFrame(priceDiffAverage)

newUSOil.columns = ["date", "Diff"]
newUKOil.columns = ["date", "Diff"]
newData.columns = ["date", "Diff"]
diffave.columns = ["date", "value"]

print(newData)

## output_file('my_first_graph.html')
## p = figure()

## p.line(newData["date"], newData["Diff"], color='green', legend_label ='UK-US')

plt.plot(newData["date"], newData["Diff"], color='green', label ='UK-US')
plt.plot(newUSOil["date"], newUSOil["Diff"], color='red', label ='US')
plt.plot(newUKOil["date"], newUKOil["Diff"], color='blue', label ='UK')
plt.plot(diffave["date"], diffave["value"], color='purple', label ='priceAverage')
plt.xlabel('Date')
plt.ylabel('Price Diff')

plt.show()
##show(p)
