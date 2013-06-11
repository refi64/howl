ffi = require 'ffi'
import style from howl.ui
import char_arr from howl.cdefs

style_number_for = style.number_for
style_name_for = style.name_for
ffi_fill = ffi.fill
string_byte = string.byte

style_buf = nil
style_buf_length = 0

get_styling_start_pos = (sci) ->
  -- so where to begin?
  pos = sci\get_end_styled!
  start_line = sci\line_from_position pos

  -- at the start already, or close enough - a safe start from the beginning
  return 0 if start_line == 0 or pos < 10

  -- we could just start at the beginning of the line?
  pos = sci\position_from_line start_line

  -- hmm, unless we're in the middle of something of course..
  -- but if the actual newline is styled differently than the pos before,
  -- we're presumably OK though since multiline lexing would just style
  -- everything until the end with the same style
  nl_pos = sci\get_line_end_position start_line - 1
  nl_style = sci\get_style_at nl_pos
  before_nl_style = sci\get_style_at nl_pos - 1
  return pos if nl_style != before_nl_style

  -- OK, fine. we're now in unknown territory, so back up until the last
  -- style change in order to get some perspective
  for pos = nl_pos - 2, 0, -1
    cur_style = sci\get_style_at pos
    return pos + 1 if cur_style != nl_style

  -- and after all this we're now back square zero after all, yay!
  0

apply = (buffer, start_pos, tokens) ->
  last_styled_pos = tokens[#tokens]
  return unless last_styled_pos
  end_pos = start_pos + last_styled_pos

  sci = buffer.sci
  default_style_number = style_number_for 'default', buffer

  size = (end_pos - start_pos) + 1 -- we'll use one-based indexes below, hence the + 1
  if style_buf_length < size
    style_buf = char_arr(size)
    style_buf_length = size

  last_pos = 1
  for idx = 1, #tokens, 3
    pos = tokens[idx]
    style_number = style_number_for tokens[idx + 1], buffer
    stop_pos = tokens[idx + 2]
    ffi_fill style_buf + last_pos, pos - last_pos, default_style_number

    while pos < stop_pos
      style_buf[pos] = style_number
      pos += 1

    last_pos = stop_pos

  ffi_fill style_buf + last_pos, size - last_pos, default_style_number

  with sci
    \start_styling start_pos - 1, 0xff
    \set_styling_ex size - 1, style_buf + 1

style_text = (buffer, end_pos, lexer) ->
  start_pos = get_styling_start_pos buffer.sci
  text = buffer.sci\get_text_range start_pos, end_pos
  apply buffer, start_pos + 1, lexer(text)

reverse = (buffer, start_pos, end_pos) ->
  default_style_number = style_number_for 'default', buffer
  style_bytes = buffer.sci\get_styled_text start_pos - 1, end_pos
  styles = {}

  cur_style = -1
  c_index = 1

  for i = 1, #style_bytes, 2
    style_num = style_bytes\byte(i + 1)
    if style_num != cur_style
      styles[#styles + 1] = c_index if #styles > 0 and cur_style != default_style_number -- mark end pos
      if style_num != default_style_number
        styles[#styles + 1] = c_index
        styles[#styles + 1] = style_name_for style_num, buffer

    c_index += 1
    cur_style = style_num

  if #styles > 0 and cur_style != default_style_number -- mark end pos
    styles[#styles + 1] = c_index

  styles

clear_styling = (sci, buffer) ->
  default_style_number = style.number_for 'default', buffer
  with sci
    end_pos = \get_end_styled!
    \start_styling 0, 0xff
    \set_styling end_pos, default_style_number

return :apply, :style_text, :clear_styling, :reverse
