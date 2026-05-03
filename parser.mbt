///|
fn field_to_string(field : StringBuilder, options : CSVOptions) -> String {
  if options.trim_spaces {
    field.to_string().trim(char_set="\n\r\t ").to_owned()
  } else {
    field.to_string()
  }
}

///|
fn[T : CSVReader] parse(
  reader : T,
  options? : CSVOptions = {
    delimiter: ',',
    allow_newlines_in_quotes: true,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: false,
  },
) -> Array[Array[String]] {
  let rows : Array[Array[String]] = Array::new()
  let mut row = Array::make(0, "")
  let mut field = StringBuilder::new()
  let mut in_quotes = false
  let mut record_has_content = false
  while !reader.is_eof() {
    let mut ch = reader.read_char().unwrap()

    // 处理 Windows 格式换行的 \r
    if ch == '\r' {
      if reader.peek_char() == Some('\n') {
        if in_quotes && options.allow_newlines_in_quotes {
          // 在引号内，需要同时处理 \r 和 \n
          field.write_char(ch) // 写入 \r
          reader.read_char() |> ignore // 消费 \n
          field.write_char('\n') // 写入 \n
          record_has_content = true
          continue // 继续下一轮循环
        } else {
          // 不在引号内，跳过 \r，之后将处理 \n
          continue
        }
      } else if options.allow_newlines_in_quotes && in_quotes {
        // 单独的 \r
        field.write_char(ch)
        record_has_content = true
        continue
      } else {
        // 将单独的 \r 视为换行
        ch = '\n'
      }
    }
    if in_quotes {
      if ch == options.quote_char {
        // 遇到引号，看下一个字符以判断转义或结束
        if !reader.is_eof() && reader.peek_char() == Some(options.quote_char) {
          // 连续两个引号，表示数据中的一个引号
          field.write_char(options.quote_char)
          reader.read_char() |> ignore // 跳过转义的第二个引号
          record_has_content = true
        } else {
          // 引号闭合，退出引号模式
          in_quotes = false
        }
      } else if ch == '\n' && !options.allow_newlines_in_quotes {
        // 如果不允许引号内换行但遇到了换行，强制结束引号
        in_quotes = false

        // 处理当前行
        if record_has_content || !options.skip_empty_lines {
          row.push(field_to_string(field, options))
          rows.push(row)
        }

        // 重置用于下一行
        row = Array::make(0, "")
        field = StringBuilder::new()
        record_has_content = false
      } else {
        // 引号内普通字符，加入当前字段
        field.write_char(ch)
        record_has_content = true
      }
    } else if ch == options.quote_char {
      // 遇到引号，进入引号模式（开始读取引用字段）
      // 只有当字段为空时才进入引号模式
      if field.is_empty() {
        in_quotes = true
        record_has_content = true
      } else {
        // 字段非空时遇到引号，视为普通字符
        field.write_char(ch)
        record_has_content = true
      }
    } else if ch == options.delimiter {
      // 遇到分隔符，当前字段结束
      row.push(field_to_string(field, options))
      field = StringBuilder::new() // 创建新的字段构建器
      record_has_content = true
    } else if ch == '\n' {
      // 遇到换行且不在引号内，当前记录结束
      // 检查是否为有效行（非空或配置允许空行）
      if record_has_content || !options.skip_empty_lines {
        row.push(field_to_string(field, options))
        rows.push(row)
      }

      // 重置用于下一行
      row = Array::make(0, "")
      field = StringBuilder::new()
      record_has_content = false
    } else {
      // 普通字符，累积到当前字段
      field.write_char(ch)
      record_has_content = true
    }
  }

  // 循环结束后，加入最后的字段和行（如果有）
  if record_has_content || row.length() > 0 {
    if record_has_content || !options.skip_empty_lines {
      row.push(field_to_string(field, options))
      rows.push(row)
    }
  }
  rows
}

///|
test "CSV::parse_string/carriage_return_in_quotes_not_allowed" {
  // 测试当不允许引号内换行时，引号内的\r会被视为换行并结束引号状态
  let data = "a,b,c\n1,\"line\rwith\rCRs\",3"
  let csv = CSV::parse_string(data, options={
    delimiter: ',',
    allow_newlines_in_quotes: false,
    quote_char: '"',
    skip_empty_lines: true,
    trim_spaces: true,
  })

  // 验证引号在遇到\r时被强制结束，并创建了新行
  inspect(csv.rows.length(), content="3") // 应该分成多行
  assert_eq(csv.rows[0][1], "line")
  // 后面的行会因为强制结束引号而成为新行的一部分
}

///|
test "CSV::parse_string/carriage_return_in_quotes" {
  // 测试引号内的\r在允许引号内换行的情况下被保留
  let data = "a,b,c\n1,\"line\rwith\rCRs\",3 "
  let csv = CSV::parse_string(data)
  inspect(csv.headers, content="[\"a\", \"b\", \"c\"]")

  // 验证引号内的\r被正确保留
  assert_eq(csv.rows[0][1], "line\rwith\rCRs")
  // 123
}
