import BN

import math, strutils

var Base16Characters: array[0 .. 15, char] = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'a', 'b', 'c', 'd', 'e', 'f'
]

var Base16Set: set[char] = {
    '0' .. '9',
    'A' .. 'F',
    'a' .. 'f'
}

var
    num0: BN = newBN("0")
    num1: BN = newBN("1")
    num16: BN = newBN("16")

proc verify*(value: string): bool {.raises: [].} =
    result = true

    for i in 0 ..< value.len:
        if value[i] notin Base16Set:
            result = false
            break

proc convert*(valueArg: BN): string {.raises: [OverflowError, Exception].} =
    if valueArg < num0:
        return

    var
        value: BN = valueArg
        remainder: string
    result = ""

    while value > num1:
        remainder = $(value mod num16)
        value = value / num16
        result = $Base16Characters[parseInt(remainder)] & result
    remainder = $(value mod num16)
    value = value / num16
    result = $Base16Characters[parseInt(remainder)] & result

    if value == num1:
        result = $Base16Characters[parseInt(remainder)] & result

    while result[0] == Base16Characters[0]:
        if result.len == 1:
            break
        result = result.substr(1, result.len)

    if result.len mod 2 == 1:
        result = "0" & result

proc revert*(base16ValueArg: string): BN {.raises: [ValueError].} =
    if not verify(base16ValueArg):
        raise newException(ValueError, "Invalid Hex Number.")

    var
        base16Value: string = base16ValueArg
        digitValue: int
        digitMultiple: BN
        value: BN = newBN("0")

    while base16Value.len != 0:
        digitValue = ((int) base16Value[0])
        if digitValue < 58:
            digitValue = digitValue - 48
        elif digitValue < 71:
            digitValue = digitValue - 55
        else:
            digitValue = digitValue - 87

        digitMultiple = num16 ^ (newBN($base16Value.len) - BNNums.ONE)
        value += newBN($digitValue) * digitMultiple
        base16Value = base16Value.substr(1, base16Value.len)

    return value
