function createOneShotTimer(element, duration, action) {
    var comp = Qt.createComponent('qrc:///components/SingleShotTimer.qml')
    comp.createObject(element, {
                          "action": action,
                          "interval": duration
                      })
}


/* match objects in array based on properties
   array is an array of objects
   properties is an array of objects in the form of: {property: someproperty, value: somevalue}
   [{property: someproperty, value: somevalue}, {property: someproperty, value: somevalue},...]

    *  property objects can be made with makePropertyObject(someproperty, somevalue)
*/
function matchObjectsByProperties(array, properties) {
    if (typeof array == "undefined") {
        console.log("failed!")
        return []
    }
    return array.filter(function (obj) {
        for (var i = 0; i < properties.length; i++) {
            var propObj = properties[i]
            var propName = propObj.property
            var propValue = propObj.value
            if (obj[propName] != propValue) {
                return false
            }
        }
        return true
    })
}

function filterObjectsByProperties(array, properties) {
    return array.filter(function (obj) {
        var maybeFilter = false
        for (var i = 0; i < properties.length; i++) {
            var propObj = properties[i]
            var propName = propObj.property
            var propValue = propObj.value
            if (obj[propName] != propValue) {
                maybeFilter = true
            }
        }
        return maybeFilter
    })
}

function makePropertyObject(prop, value) {
    return {
        "property": prop,
        "value": value
    }
}
function generateUuid(n) {
    var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split(
                '')
    var uuid = [], i
    for (i = 0; i < n; i++) {
        uuid[i] = chars[Math.floor(Math.random() * chars.length)]
    }
    return uuid.join('')
}

function keysToLetters(obj) {
    var letters = []
    for (var key in obj) {
        letters.push(key.charAt(0))
    }
    return letters
}

/* make an array that can store letter, key pairs */
var letterKeyPairs = []

/* make a function that accepts a key and checks if it exists within letterKeyPairs, if not then adds a new object to letterKeyPairs with key value pair key : firstLetterOfKey */
function addKeyToLetterKeyPairs(key) {
    var firstLetterOfKey = key.charAt(0)
    var usedKeys = matchObjectsByProperties(letterKeyPairs,
                                            [makePropertyObject("key", key)])
    if (usedKeys.length > 0) {
        return usedKeys[0].letter
    }
    var usedLetters = matchObjectsByProperties(
                letterKeyPairs,
                [makePropertyObject("letter",
                                    firstLetterOfKey)]).map(function (item) {
                                        return item.letter
                                    })

    if (usedLetters.indexOf(firstLetterOfKey) === -1) {
        letterKeyPairs.push({
                                "key": key,
                                "letter": firstLetterOfKey
                            })
    } else {
        firstLetterOfKey = key.charAt(0) + key.charAt(1)
        usedLetters = matchObjectsByProperties(
                    letterKeyPairs, [makePropertyObject("letter",
                                                        firstLetterOfKey)]).map(
                    function (item) {
                        return item.letter
                    })

        if (usedLetters.indexOf(firstLetterOfKey) === -1) {
            letterKeyPairs.push({
                                    "key": key,
                                    "letter": firstLetterOfKey
                                })
        } else {
            firstLetterOfKey = key.charAt(0) + key.charAt(1) + key.charAt(2)
            usedLetters = matchObjectsByProperties(
                        letterKeyPairs,
                        [makePropertyObject("letter", firstLetterOfKey)]).map(
                        function (item) {
                            return item.letter
                        })

            if (usedLetters.indexOf(firstLetterOfKey) === -1) {
                letterKeyPairs.push({
                                        "key": key,
                                        "letter": firstLetterOfKey
                                    })
            } else {

            }
        }
    }
    return firstLetterOfKey
}

/* make a function that accepts an object and changes every key to the return value of addKeyToLetterKeyPairs(key) while keeping the values */
function changeKeysToLetters(obj) {
    var newObj = {}
    for (var key in obj) {
        newObj[addKeyToLetterKeyPairs(key)] = obj[key]
    }
    return newObj
}

/* make a function to recursively change keys to letter over a multi-dimensional array of objects which may or may not have child arrays and/or child objects */
function changeKeysToLettersRecursively(obj) {
    if (Array.isArray(obj)) {
        var newObj = []
        for (var i = 0; i < obj.length; i++) {
            newObj.push(changeKeysToLettersRecursively(obj[i]))
        }
        return newObj
    } else if (typeof obj === 'object') {
        var newObj = {}
        for (var key in obj) {
            newObj[addKeyToLetterKeyPairs(
                       key)] = changeKeysToLettersRecursively(obj[key])
        }
        return newObj
    } else {
        return obj
    }
}

/* make a function that uses letterKeyPairs to convert a letter into a key for the keys in an object */
function letterToKey(letter) {
    for (var i = 0; i < letterKeyPairs.length; i++) {
        if (letterKeyPairs[i].letter === letter) {
            return letterKeyPairs[i].key
        }
    }
}

/* make a function to take an array of objects and convert the letters to keys recursively over child objects, child arrays, and top level objects */
function changeLettersToKeysRecursively(obj) {
    if (Array.isArray(obj)) {
        var newObj = []
        for (var i = 0; i < obj.length; i++) {
            newObj.push(changeLettersToKeysRecursively(obj[i]))
        }
        return newObj
    } else if (typeof obj === 'object') {
        var newObj = {}
        for (var key in obj) {
            newObj[letterToKey(key)] = changeLettersToKeysRecursively(obj[key])
        }
        return newObj
    } else {
        return obj
    }
}

/* convert the keys to letter for the array: [ { "col" : 4, "row": 4 }, { "col" : 4, "row": 5 }, { "col" : 2, "row": 3 }  ] and print the result on screen */
//var array = [{
//                 "col": 4,
//                 "row": 4
//             }, {
//                 "col": 4,
//                 "row": 5
//             }, {
//                 "col": 2,
//                 "row": 3
//             }]
//var arrayWithLetters = changeKeysToLettersRecursively(array)
//console.log(JSON.stringify(arrayWithLetters))
//var convertedArray = changeLettersToKeysRecursively(arrayWithLetters)
//console.log(JSON.stringify(convertedArray))
function compressArray(iarray) {
    letterKeyPairs = []
    var rv = changeKeysToLettersRecursively(iarray)
    return {
        "dict": letterKeyPairs,
        "array": rv
    }
}

function decompressArray(iarray) {
    if (iarray.dict != null) {
        letterKeyPairs = iarray.dict
        var rv = changeLettersToKeysRecursively(iarray.array)

        return rv
    } else {
        return iarray
    }
}
function base64_encode(str) {
    var c1, c2, c3, e1, e2, e3, e4
    var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    var i = 0
    var len = str.length
    var out = ""
    while (i < len) {
        c1 = str.charCodeAt(i++) & 0xff
        if (i == len) {
            out += base64.charAt(c1 >> 2)
            out += base64.charAt((c1 & 0x3) << 4)
            out += "=="
            break
        }
        c2 = str.charCodeAt(i++)
        if (i == len) {
            out += base64.charAt(c1 >> 2)
            out += base64.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4))
            out += base64.charAt((c2 & 0xF) << 2)
            out += "="
            break
        }
        c3 = str.charCodeAt(i++)
        out += base64.charAt(c1 >> 2)
        out += base64.charAt(((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4))
        out += base64.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6))
        out += base64.charAt(c3 & 0x3F)
    }
    return out
}

/* make a function to create  a neural network for deep learning NLP in vanilla js */
function create_neural_network(input_nodes, hidden_nodes, output_nodes) {
    var network = {}
    network.input_nodes = input_nodes
    network.hidden_nodes = hidden_nodes
    network.output_nodes = output_nodes
    network.weights_ih = new Array(hidden_nodes)
    network.weights_ho = new Array(output_nodes)
    for (var i = 0; i < network.weights_ih.length; i++) {
        network.weights_ih[i] = []
        for (var j = 0; j < network.input_nodes; j++) {
            network.weights_ih[i][j] = Math.random() * 2 - 1
        }
    }
    for (var i = 0; i < network.weights_ho.length; i++) {
        network.weights_ho[i] = []
        for (var j = 0; j < network.hidden_nodes; j++) {
            network.weights_ho[i][j] = Math.random() * 2 - 1
        }
    }
    network.bias_h = []
    network.bias_o = []
    for (var i = 0; i < network.hidden_nodes; i++) {
        network.bias_h[i] = Math.random() * 2 - 1
    }
    for (var i = 0; i < network.output_nodes; i++) {
        network.bias_o[i] = Math.random() * 2 - 1
    }
    network.learning_rate = 0.1
    network.activation_function = function (x) {
        return Math.tanh(x)
    }
    network.activation_function_derivative = function (x) {
        return 1 - Math.tanh(x) * Math.tanh(x)
    }
    return network
}

/* make a function to parse a block of text where each input text is followed by a newline and then an output text then a newline and return an array of objects with the input and output values */
function parse_training_data(training_data) {
    var input_array = []
    var output_array = []
    for (var i = 0; i < training_data.length; i++) {
        var input_text = training_data[i].split('\n')[0]
        var output_text = training_data[i].split('\n')[1]
        input_array.push(input_text.split('').map(function (x) {
            return x
        }))
        output_array.push(output_text.split('').map(function (x) {
            return x
        }))
    }
    for (var i = 0; i < input_array.length; i++) {
        var input = input_array[i]
        var output = output_array[i]
        var input_object = {}
        input_object.input = input
        input_object.output = output
        input_array[i] = input_object
    }
    return input_array
}
var network = {}
/* make a function to parse the training data of a string and use the resulting array of objects to train the neural network in vanilla js */
function train_neural_network(training_data) {
    var input_array = parse_training_data(training_data)
    for (var i = 0; i < input_array.length; i++) {
        var input_object = input_array[i]
        var input = input_object.input
        var output = input_object.output
        var hidden_outputs = []
        var hidden_output = []
        for (var j = 0; j < network.hidden_nodes; j++) {
            var sum = 0
            for (var k = 0; k < network.input_nodes; k++) {
                sum += network.weights_ih[j][k] * input[k]
            }
            sum += network.bias_h[j]
            hidden_output[j] = network.activation_function(sum)
        }
        hidden_outputs.push(hidden_output)
        var output_outputs = []
        var output_output = []
        for (var j = 0; j < network.output_nodes; j++) {
            var sum = 0
            for (var k = 0; k < network.hidden_nodes; k++) {
                sum += network.weights_ho[j][k] * hidden_output[k]
            }
            sum += network.bias_o[j]
            output_output[j] = network.activation_function(sum)
        }
        output_outputs.push(output_output)
        var output_errors = []
        var output_error = []
        for (var j = 0; j < network.output_nodes; j++) {
            output_error[j] = output_output[j] - output[j]
        }
        output_errors.push(output_error)
        var hidden_errors = []
        var hidden_error = []
        for (var j = 0; j < network.hidden_nodes; j++) {
            var sum = 0
            for (var k = 0; k < network.output_nodes; k++) {
                sum += output_error[k] * network.weights_ho[k][j]
            }
            hidden_error[j] = sum * network.activation_function_derivative(
                        hidden_output[j])
        }
        hidden_errors.push(hidden_error)
        for (var j = 0; j < network.output_nodes; j++) {
            for (var k = 0; k < network.hidden_nodes; k++) {
                network.weights_ho[j][k] -= network.learning_rate
                        * output_error[j] * hidden_output[k]
            }
            network.bias_o[j] -= network.learning_rate * output_error[j]
        }
        for (var j = 0; j < network.hidden_nodes; j++) {
            for (var k = 0; k < network.input_nodes; k++) {
                network.weights_ih[j][k] -= network.learning_rate * hidden_error[j] * input[k]
            }
            network.bias_h[j] -= network.learning_rate * hidden_error[j]
        }
    }
}
var train_data = []

function append_training_data(input_string, output_string) {
    train_data.push(input_string + '\n' + output_string + '\n')
}

append_training_data("hello smackbot", "hello loser.")

append_training_data("how are you doing",
                     "i was doing great before you started talking")

append_training_data("do you ever sleep with female bots",
                     "i am a female bot, dumbass")

append_training_data("have you slept with a spambot",
                     "whenever a hot one comes around")

append_training_data("can i sleep with you", "hell no")

append_training_data("who are you", "i am smackbot")

function compile_neural_network() {
    var network = create_neural_network(8, 16, 8)
    train_neural_network(train_data)
    network = create_neural_network(train_data, train_data, train_data)
    console.log(JSON.stringify(network))
    return network
}

function predict_neural_network(input_string) {
    var input = input_string.split('').map(function (x) {
        return parseInt(x)
    })
    var hidden_outputs = []
    var hidden_output = []
    for (var j = 0; j < network.hidden_nodes; j++) {
        var sum = 0
        for (var k = 0; k < network.input_nodes; k++) {
            sum += network.weights_ih[j][k] * input[k]
        }
        sum += network.bias_h[j]
        hidden_output[j] = network.activation_function(sum)
    }
    hidden_outputs.push(hidden_output)
    var output_outputs = []
    var output_output = []
    for (var j = 0; j < network.output_nodes; j++) {
        var sum = 0
        for (var k = 0; k < network.hidden_nodes; k++) {
            sum += network.weights_ho[j][k] * hidden_output[k]
        }
        sum += network.bias_o[j]
        output_output[j] = network.activation_function(sum)
    }
    output_outputs.push(output_output)
    return output_outputs
}
