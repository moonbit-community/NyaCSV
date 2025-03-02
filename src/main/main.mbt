fn main {
  println(@lib.hello())
  @fs.read_file_to_string?("csv/dataset.csv") |> println()
}
