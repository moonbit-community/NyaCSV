fn read(str : String) -> Unit {
  @fs.read_file_to_string?(str) |> println()
}

test {
  read("csv/newlines_crlf.csv")
}