#Wrapper for the Argon2 C library that won the PHC competition.

#Base lib for checking argument validity.
import Base

#Errors lib.
import Errors

#strutils stdlib for parsing Hex strings.
import strutils

#Include the argon2.h header.
{.passC: "-Isrc/lib/Argon/include".}
#Compile the relevant C files.
{.compile: "Argon/src/core.c".}
{.compile: "Argon/src/thread.c".}
{.compile: "Argon/src/encoding.c".}
{.compile: "Argon/src/blake2/blake2b.c".}
{.compile: "Argon/src/ref.c".}
{.compile: "Argon/src/argon2.c".}

#C function.
proc argon2d(
    iterations: uint32,
    memory: uint32,
    parallelism: uint32,
    data: ptr uint8,
    dataLen: uint32,
    salt: ptr uint8,
    saltLen: uint32,
    res: ptr uint8,
    resLen: uint32
): cint {.header: "../../src/lib/Argon/include/argon2.h", importc: "argon2d_hash_raw".}

#Take in data (128 char max) and a salt (64 char max), return a 64 character string.
proc Argon*(dataArg: string, saltArg: string): string {.raises: [ResultError, ValueError].} =
    var
        data: string = dataArg
        salt: string = saltArg
        dataArr: array[64, uint8]
        saltArr: array[32, uint8]
        resArr: array[32, uint8]
        res: string

    #Verify argument validity.
    if (not Base.isBase(data, 16)) or (not Base.isBase(salt, 16)):
        raise newException(ValueError, "Invalid hex data/salt.")
    if (data.len > 128) or (salt.len > 64):
        raise newException(ValueError, "Invalid data/salt length.")

    #Pad the arguments to always be 128/64 chars long.
    while data.len < 128:
        data = "00" & data
    while salt.len < 64:
        salt = "00" & salt

    #Parse the data/salt strings into array.
    for i in countup(0, 127, 2):
        dataArr[(int) i/2] = (uint8) parseHexInt(data[i .. i+1])
    for i in countup(0, 63, 2):
        saltArr[(int) i/2] = (uint8) parseHexInt(salt[i .. i+1])

    #Iterate 10000 times, using 200MB, with no parallelism.
    #The iteration quantity and memory usage values are for testing only.
    #They are not final and will be changed.
    if argon2d(
        (uint32) 10000,
        (uint32) 18,
        (uint32) 1,
        cast[ptr uint8](addr dataArr[0]),
        (uint32) 64,
        cast[ptr uint8](addr saltArr[0]),
        (uint32) 32,
        addr resArr[0],
        (uint32) 32
    ) != 0:
        raise newException(ResultError, "Argon2d raised an error.")

    #Set the result var.
    result = ""
    for i in resArr:
        result = result & i.toHex()