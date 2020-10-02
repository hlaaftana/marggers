## Parses a single XML node using Nim's parsexml.
## Works for JS in versions above 1.2.x.

import parsexml, xmltree, streams, strtabs

proc addNode(father, son: XmlNode) =
  if son != nil: add(father, son)

proc parse(x: var XmlParser, errors: var seq[string]): XmlNode {.gcsafe.}

proc untilElementEnd(x: var XmlParser, result: XmlNode,
                     errors: var seq[string]) =
  while true:
    case x.kind
    of xmlElementEnd:
      if x.elementName == result.tag:
        return
      else:
        errors.add(errorMsg(x, "</" & result.tag & "> expected"))
        # do not skip it here!
      break
    of xmlEof:
      errors.add(errorMsg(x, "</" & result.tag & "> expected"))
      break
    else:
      result.addNode(parse(x, errors))

proc parse(x: var XmlParser, errors: var seq[string]): XmlNode =
  case x.kind
  of xmlComment:
    result = newComment(move x.charData)
    next(x)
  of xmlCharData, xmlWhitespace:
    result = newText(move x.charData)
    next(x)
  of xmlPI, xmlSpecial:
    # we just ignore processing instructions for now
    next(x)
  of xmlError:
    errors.add(errorMsg(x))
    next(x)
  of xmlElementStart: ## ``<elem>``
    result = newElement(move x.elementName)
    next(x)
    untilElementEnd(x, result, errors)
  of xmlElementEnd:
    errors.add(errorMsg(x, "unexpected ending tag: " & move x.elementName))
  of xmlElementOpen:
    result = newElement(move x.elementName)
    next(x)
    result.attrs = newStringTable()
    while true:
      case x.kind
      of xmlAttribute:
        result.attrs[move x.attrKey] = move x.attrValue
        next(x)
      of xmlElementClose:
        next(x)
        break
      of xmlError:
        errors.add(errorMsg(x))
        next(x)
        break
      else:
        errors.add(errorMsg(x, "'>' expected"))
        next(x)
        break
    untilElementEnd(x, result, errors)
  of xmlAttribute, xmlElementClose:
    errors.add(errorMsg(x, "<some_tag> expected"))
    next(x)
  of xmlCData:
    result = newCData(move x.charData)
    next(x)
  of xmlEntity:
    ## &entity;
    result = newEntity(move x.entityName)
    next(x)
  of xmlEof: discard

proc parseXml*(text: string, i: int): (bool, int) =
  ## Parse `text` starting with index `i` as a single XML node
  ## and return a tuple with a boolean indicating success and
  ## an integer indicating the index where the XML ends.
  var errors: seq[string]
  var x: XmlParser
  let stream = newStringStream(text)
  stream.setPosition(i)
  open(x, stream, "", {allowUnquotedAttribs, reportComments})
  x.next()
  while true:
    case x.kind
    of xmlElementOpen, xmlElementStart:
      let node = newElement(move(x.elementName))
      untilElementEnd(x, node, errors)
      result[0] = true
    of xmlComment, xmlSpecial, xmlPI, xmlCData:
      x.next
      result[0] = true
    of xmlElementEnd, xmlCharData, xmlWhitespace, xmlEof:
      result[0] = true
      break
    else:
      result[0] = false
      break
  result[1] = x.bufpos
