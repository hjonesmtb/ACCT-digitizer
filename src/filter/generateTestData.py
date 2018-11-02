#!/bin/python

# Generates test vectors for the test bench. Saves to a file for reading in
# Written by David Bascelli
# August 2018
import re
from random import randint
print("Generating Test Data")
inputDataFile  = open("inputData.dat", "w")
outputDataFile = open("outputData.dat","w")

dummyDataFile = open("dummyData.dat","w")
dummyDataFile.write("");

outputData = [0] * 100 
inputData = [0] * 100
taps = [0] * 6

for i in range(0, len(inputData)):
    inputData[i] = randint(0, 60)
    inputDataFile.write("%0.2X\n" % inputData[i])


for i in range(0, len(outputData)):
    for j in reversed(range(1, len(taps))):
        taps[j] = taps[j-1]
        outputData[i] += int(taps[j]/(len(taps)))
    taps[0] = inputData[i]
    outputData[i] += int(taps[0]/(len(taps)))
    outputDataFile.write("%0.2X\n" % outputData[i])

print("Test Data Generated")
