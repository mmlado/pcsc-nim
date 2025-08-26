import pcsc
import pcsc/util as putil
import std/strutils as s

proc main() =
  let ctx = establishContext()
  let readers = ctx.listReaders()
  if readers.len == 0:
    echo "No readers detected."; return

  echo "Connected to card in reader: ", readers[0]
  var card = ctx.connect(readers[0])  # auto T=1 then T=0

  let apduHex = "00 A4 04 00 08 A0 00 00 08 04 00 01 01"
  let apdu    = fromHexLoose(apduHex)
  echo "APDU len = ", apdu.len
  echo "Sending APDU: ", apduHex

  let resp = card.transmit(apdu)
  echo "Response: ", putil.prettyHex(resp)
  if resp.len >= 2:
    let sw1 = resp[^2]; let sw2 = resp[^1]
    echo "SW1SW2: 0x", s.toHex(int(sw1), 2), s.toHex(int(sw2), 2)

main()
