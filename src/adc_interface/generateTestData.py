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

outputData = [0] * 10

for i in range(0, len(outputData)):
    outputData[i] = randint(0, 2**16)
    outputDataFile.write("%0.4X\n" % outputData[i])


for i in range(0, len(outputData)):
    for j in range(0,16):
        inputDataFile.write("%0.1X\n" % (outputData[i]>>(15-j) & 1))

print("Test Data Generated")
