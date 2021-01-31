from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile

from tensorflow.keras.models import Sequential #Neural stuff
from tensorflow.keras.layers import Dense

import numpy as np 
import matplotlib.pyplot as plt
import matplotlib.image as img 

import ast
import sympy

import copy 
import os

def load_model():
    model = Sequential()
    model.add(Dense(64, activation='relu', input_dim=784))
    model.add(Dense(64, activation='relu'))
    model.add(Dense(10, activation='softmax'))
    model.compile(
        optimizer='adam',
        loss = 'categorical_crossentropy',
        metrics = ['accuracy']
        )

    model.load_weights('model.h5')

    return model

def remove_white_space(image):
    height, width = image.shape
    x, y = height // 50, width // 50

    for edge in range(4):
        while True:
            numVal = (image > .5).sum()

            if edge == 0:
                tempImg = image[y:, :]

            if edge == 1:
                tempImg = image[:-y, :]

            if edge == 2:
                tempImg = image[:, x:]

            if edge == 3:
                tempImg = image[:, :-x]

            # if new image removed relavant pixels, stop
            if (tempImg > .5).sum() == numVal:
                image = tempImg 
            else:
                break

    return image

def convert_to_square(image):
    height, width = image.shape

    if height > width:
        blankMatrix = np.zeros((height, (height - width) // 2))
        image       = np.concatenate((blankMatrix, image, blankMatrix), axis=1)

    if width > height:
        blankMatrix = np.zeros(((width - height) // 2, height))
        image       = np.concatenate((blankMatrix, image, blankMatrix), axis=0)

    image = np.pad(image, [(5, 5), (5, 5)], mode='constant')
    image = image / np.max(image)
    image[image < .5] = 0.0
    image[image > .5] = 1.0

    return image

def compress_image(image):
    compressedImage = np.zeros((28, 28))
    width, height = image.shape
    width, height = width / 28, height / 28

    for row in range(28):
        for col in range(28):
            rowStart, rowEnd = int(row * height), int((row + 1) * height)
            colStart, colEnd = int(col * width), int((col + 1) * width)
            compressedImage[row, col]  = np.sum(np.sum(image[rowStart: rowEnd, colStart: colEnd]))
            compressedImage[row, col] /= (width * height)

    return compressedImage

@csrf_exempt
def process_image(request):
    model = load_model()

    image = request.FILES['media']
    path = default_storage.save('test.jpg', ContentFile(image.read()))
    rawImage = np.array(img.imread('test.jpg'))
    os.remove('test.jpg')

    topXRatio = 1 - float(request.POST["bot_x"])
    botXRatio = 1 - float(request.POST["top_x"])
    topYRatio = float(request.POST["top_y"])
    botYRatio = float(request.POST["bot_y"])

    image = np.sum(rawImage, axis=2)
    
    totalWidth = len(image[0])
    totalHeight = len(image)
    
    topX = int(topXRatio * totalHeight)
    botX = int(botXRatio * totalHeight)
    topY = int(topYRatio * totalWidth)
    botY = int(botYRatio * totalWidth)

    matrix = []

    image = np.rot90(image[botX:topX, botY:topY], k=3)

    colLength, rowLength = image.shape
    colLength, rowLength = colLength // 3, rowLength // 3

    for col in range(3):
        results = []
        for row in range(3):
            bot_x = row * rowLength 
            top_x = bot_x + rowLength

            bot_y = col * colLength
            top_y = bot_y + colLength

            tempImg = image[bot_y:top_y, bot_x:top_x]
            tempImg = np.abs((tempImg / np.max(tempImg)) - 1)
            tempImg = remove_white_space(tempImg)
            tempImg = convert_to_square(tempImg)
            tempImg = compress_image(tempImg)

            tempImg = tempImg / np.max(tempImg)

            # transforming image
            tempImg = tempImg.reshape((-1,784))
            # caluclations
            number = np.argmax(model.predict(tempImg))
            results.append(number)

        matrix.append(results)
    print(matrix)
    return JsonResponse({"matrix": str(matrix)})

@csrf_exempt
def determinant(request):
    Matrix = request.POST['matrix']
    Matrix= str(Matrix)
    Matrix = ast.literal_eval(Matrix)
    Matrix = np.array(Matrix)
    determinant = np.linalg.det(Matrix)
    determinant = str(determinant)
    return HttpResponse(determinant)

@csrf_exempt
def eigenvalue(request):
    Matrix = request.POST['matrix']
    Matrix= str(Matrix)
    Matrix = ast.literal_eval(Matrix)
    Matrix = np.array(Matrix)
    eigenvalues = np.linalg.eig(Matrix)
    eigenvalues = str(eigenvalues)
    return HttpResponse(eigenvalues)
    
@csrf_exempt
def solve(request):
    matrix = request.POST['matrix']
    matrix= str(matrix)
    matrix = ast.literal_eval(matrix)
    matrix=sympy.Matrix(matrix).rref()
    newMatrix = (matrix[0].tolist())
    solutions = np.array(matrix[1])
    print(newMatrix)
    newMatrix = str(newMatrix)

    return HttpResponse(newMatrix)

if __name__ == '__main__':
    process_image()
