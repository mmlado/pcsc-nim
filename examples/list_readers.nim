import pcsc/context

proc main() =
  let ctx = establishContext()
  echo "PC/SC context established."

  let readers = ctx.listReaders()
  if readers.len == 0:
    echo "No smart card readers found."
    return

  echo "Available readers:"
  for r in readers:
    echo " - ", r

main()
