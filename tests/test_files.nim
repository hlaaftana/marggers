import module_bridge, marggers, strutils

proc joinedParse*(str: string): string =
  for p in str.parseMarggers:
    result.add($p)
    result.add("\r\n")

runTests:
  for dir in ["examples", "tests/files"]:
    for (testName, inputFile) in files(dir):
      var testPath = $inputFile
      testPath.removeSuffix(".mrg")
      let outputFile = testPath & ".html"
      if testPath.len != inputFile.len:
        let fileContent = read(inputFile)
        test "Test file " & testName:
          let input = joinedParse(fileContent).splitLines
          let output = read(outputFile).splitLines
          # outputFile has to be a variable or nims breaks for some reason
          checkpoint "input lines: " & $input.len
          checkpoint "output lines: " & $output.len
          check input == output
          if input != output:
            write(testPath & "_real.html", input.join("\r\n"))
        test "Test file " & testName & " with LF":
          let input = joinedParse(fileContent.replace("\r\n", "\n")).splitLines
          let output = read(outputFile).splitLines
          check input == output
          #if input != output:
          #  write(testPath & "_real_lf.html", input.join("\r\n"))
