import unittest
import pcsc/util

suite "PC/SC utility functions":
    test "toHex converts bytes to hex string":
        let bytes = @[0x12'u8, 0xAB'u8, 0xFF'u8]  # Use 'u8 suffix for explicit byte type
        check bytes.toHex() == "12ABFF"

    test "fromHex converts hex string to bytes":
        let hex = "12ABFF"
        let expected: seq[byte] = @[0x12'u8, 0xAB'u8, 0xFF'u8]
        check hex.fromHex() == expected

    test "fromHex requires even length string":
        expect AssertionDefect:
            discard "123".fromHex()

    test "prettyHex formats with spaces":
        let bytes = @[0x12'u8, 0xAB'u8, 0xFF'u8]
        check bytes.prettyHex() == "12 AB FF"

    test "empty array handling":
        let empty: seq[byte] = @[]
        check empty.toHex() == ""
        check empty.prettyHex() == ""
        check "".fromHex() == empty