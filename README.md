# pcsc-nim

🔒 **PC/SC bindings + idiomatic Nim wrapper**

`pcsc-nim` is a cross-platform [PC/SC](https://en.wikipedia.org/wiki/PC/SC) library for **smart card** access from Nim.  
It provides both **low-level FFI bindings** to `PCSC`/`winscard` as well as a **high-level API** for everyday use.

- ✅ Linux (`libpcsclite.so`)
- ✅ Windows (`winscard.dll`)
- ✅ macOS (`PCSC.framework`)

---

## ✨ Features

- Establish and release PC/SC contexts
- Enumerate available smart card readers
- Connect to a card with T=0 or T=1 protocol
- Send/receive raw APDUs
- Helper utilities for hex parsing & pretty printing
- Safe error handling with Nim exceptions

---

## 📦 Installation

```bash
nimble install https://github.com/mmlado/pcsc-nim
```

Or for development:

```bash
git clone https://github.com/mmlado/pcsc-nim
cd pcsc-nim
nimble develop
```

---

## 🚀 Usage

### List readers & select a card

```nim
import pcsc

let ctx = establishContext()
let readers = ctx.listReaders()

if readers.len == 0:
  quit "No readers found"

echo "Readers:"
for r in readers:
  echo "  ", r

let card = ctx.connect(readers[0])
```

### Transmit an APDU

```nim
# SELECT example AID
let resp = card.transmitHex("00 A4 04 00 08 A0 00 00 08 04 00 01 01")

echo "Response:"
echo "  ", prettyHex(resp)

let (sw1, sw2) = sw(resp)
echo "SW1SW2: 0x", (sw1.int shl 8 or sw2.int).toHex(4)
```

Example output:

```
Readers:
  Generic USB2.0-CRW [Smart Card Reader Interface]
Response:
  A4 61 8F 10 ... 90 00
SW1SW2: 0x9000
```

---

## 🛠 Development

Run the test suite:

```bash
nimble test
```

Run examples:

```bash
nimble transmit_apdu
```

---

## 📜 License

MIT © [mmlado](https://github.com/mmlado)

