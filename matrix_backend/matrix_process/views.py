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

    model.load_weights('/Users/johnbensen/Documents/matrixbullshit/matrix_backend/matrix_process/model.h5')

    return model

def remove_white_space(image):
    height, width = image.shape
    x, y = height // 20, width // 20

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
        blankMatrix = np.zeros(((height - width) // 2, height))
        image       = np.concatenate((blankMatrix, image, blankMatrix), axis=0)

    if width > height:
        blankMatrix = np.zeros((height, (width - height) // 2))
        image       = np.concatenate((blankMatrix, image, blankMatrix), axis=1)

    image = np.pad(image, [(20, 20), (20, 20)], mode='constant')
    image = image / np.max(image)
    image[image < .5] = 0.0
    image[image > .5] = 1.0

    return image

def compress_image(image):
    compressedImage = np.zeros((28, 28))
    width, height = image.shape
    width, height = width // 28, height // 28

    for row in range(28):
        for col in range(28):
            compressedImage[row, col]  = np.sum(np.sum(image[row * height: (row + 1) * height, col * width: (col + 1) * width]))
            compressedImage[row, col] /= (width * height)

    return compressedImage

model = load_model()

@csrf_exempt
def process_image(request):
    image = request.FILES['media']
    path = default_storage.save('test.jpg', ContentFile(image.read()))

    rawImage = np.array(img.imread('test.jpg'))

    topXRatio = float(request.POST['top_x'])
    botXRatio = float(request.POST['bot_x'])
    topYRatio = float(request.POST['top_y'])
    botYRatio = float(request.POST['bot_y'])
    print(topXRatio, botXRatio, topYRatio, botYRatio)
    image = np.sum(rawImage, axis=2)

    totalWidth = len(image[0])
    totalHeight = len(image)
    
    topX = int(topXRatio * totalWidth)
    botX = int(botXRatio * totalWidth)
    topY = int(topYRatio * totalHeight)
    botY = int(botYRatio * totalHeight)

    rowLength = (topX - botX) // 3
    colLength = (topY - botY) // 3
    matrix = []
    results = []

    for col in range(3):
        for row in range(3):
            bot_x = botX + row * rowLength 
            top_x = bot_x + rowLength

            bot_y = botY + col * colLength
            top_y = bot_y + colLength

            tempImg = image[bot_y:top_y, bot_x:top_x]
            tempImg = np.abs((tempImg - np.max(tempImg)) / np.max(tempImg))
            tempImg = remove_white_space(tempImg)
            tempImg = convert_to_square(tempImg)
            tempImg = compress_image(tempImg)
            # print(np.round(tempImg, 2))
            # transforming image
            tempImg = tempImg.reshape((-1,784))
            # caluclations
            number = np.argmax(model.predict(tempImg))
            results.append(number)

            plt.figure(3 * row + col)
            plt.imshow(tempImg)
            plt.colorbar()
            plt.savefig("%d_%d.png" % (row, col))

    return HttpResponse(status=200)

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
